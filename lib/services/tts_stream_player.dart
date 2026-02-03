import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'tts_service.dart';

/// TTS 流式播放器 - 支持边接收边播放
class TtsStreamPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  
  // 播放状态
  final ValueNotifier<PlayerState> playerState = ValueNotifier(PlayerState.stopped);
  final ValueNotifier<double> playProgress = ValueNotifier(0.0);
  final ValueNotifier<String?> currentSubtitle = ValueNotifier<String?>(null);
  final ValueNotifier<List<SubtitleInfo>> subtitles = ValueNotifier([]);
  
  // 音频数据缓冲区
  final List<int> _audioBuffer = [];
  bool _isBuffering = false;
  String? _currentText;
  StreamSubscription<TtsStreamEvent>? _streamSubscription;
  
  /// 获取音频播放器（用于外部控制）
  AudioPlayer get audioPlayer => _audioPlayer;
  
  /// 初始化
  void init() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      playerState.value = state;
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      _updateSubtitle(position);
    });
  }
  
  /// 使用流式播放朗读文本
  Future<void> speakStreaming(String text, {String? voiceType}) async {
    try {
      // 停止当前播放
      await stop();
      
      _currentText = text;
      _audioBuffer.clear();
      subtitles.value = [];
      currentSubtitle.value = null;
      _isBuffering = true;
      
      // 检查缓存
      final cachedFile = await _getCachedAudio(text, voiceType);
      if (cachedFile != null) {
        // 使用缓存文件播放
        await _audioPlayer.play(DeviceFileSource(cachedFile.path));
        return;
      }
      
      // 开始流式合成和播放
      final tempFile = await _ttsService.streamToFile(
        text,
        customVoiceType: voiceType,
        onProgress: (progress) {
          playProgress.value = progress * 0.5; // 合成占50%进度
        },
      );
      
      if (tempFile != null) {
        // 流式合成完成后播放
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        playProgress.value = 1.0;
        
        // 可选：保存到缓存
        await _saveToCache(text, voiceType, tempFile);
      }
    } catch (e) {
      debugPrint('TTS Stream Player Error: $e');
      rethrow;
    }
  }
  
  /// 高级：实时边接收边播放（需要更复杂的实现）
  Future<void> speakRealtime(String text, {String? voiceType}) async {
    try {
      await stop();
      
      _currentText = text;
      _audioBuffer.clear();
      subtitles.value = [];
      currentSubtitle.value = null;
      
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/tts_realtime_${DateTime.now().millisecondsSinceEpoch}.mp3');
      final sink = tempFile.openWrite();
      
      bool hasStartedPlaying = false;
      int receivedBytes = 0;
      const minBufferSize = 50 * 1024; // 至少缓冲50KB再开始播放
      
      _streamSubscription = _ttsService.streamAudioV2(
        text,
        customVoiceType: voiceType,
        enableSubtitle: true,
      ).listen(
        (event) async {
          switch (event.type) {
            case TtsStreamEventType.audio:
              if (event.bytes != null) {
                sink.add(event.bytes!);
                receivedBytes += event.bytes!.length;
                
                // 缓冲足够数据后开始播放
                if (!hasStartedPlaying && receivedBytes >= minBufferSize) {
                  hasStartedPlaying = true;
                  await sink.flush();
                  await _audioPlayer.play(DeviceFileSource(tempFile.path));
                }
                
                playProgress.value = 0.3 + (event.totalBytes ?? 0) / (text.length * 2000) * 0.4;
              }
              break;
              
            case TtsStreamEventType.subtitle:
              if (event.text != null) {
                subtitles.value = [...subtitles.value, SubtitleInfo(
                  text: event.text!,
                  words: event.words,
                )];
              }
              break;
              
            case TtsStreamEventType.complete:
              await sink.close();
              playProgress.value = 1.0;
              
              // 如果还没开始播放（短文本），现在开始播放
              if (!hasStartedPlaying) {
                await _audioPlayer.play(DeviceFileSource(tempFile.path));
              }
              
              // 保存到缓存
              await _saveToCache(text, voiceType, tempFile);
              break;
              
            case TtsStreamEventType.error:
              await sink.close();
              try { await tempFile.delete(); } catch (_) {}
              throw Exception(event.message);
          }
        },
        onError: (e) async {
          await sink.close();
          try { await tempFile.delete(); } catch (_) {}
          debugPrint('Stream error: $e');
        },
        onDone: () async {
          await sink.close();
        },
      );
    } catch (e) {
      debugPrint('Real-time TTS Error: $e');
      rethrow;
    }
  }
  
  /// 暂停
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  /// 恢复
  Future<void> resume() async {
    await _audioPlayer.resume();
  }
  
  /// 停止
  Future<void> stop() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _audioPlayer.stop();
    _audioBuffer.clear();
    _isBuffering = false;
    playProgress.value = 0.0;
    currentSubtitle.value = null;
  }
  
  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  /// 更新当前字幕
  void _updateSubtitle(Duration position) {
    if (subtitles.value.isEmpty) return;
    
    // 根据播放时间找到对应的字幕
    final seconds = position.inMilliseconds / 1000.0;
    
    for (final subtitle in subtitles.value) {
      if (subtitle.words != null && subtitle.words!.isNotEmpty) {
        final firstWord = subtitle.words!.first;
        final lastWord = subtitle.words!.last;
        
        if (seconds >= firstWord.startTime && seconds <= lastWord.endTime) {
          currentSubtitle.value = subtitle.text;
          return;
        }
      }
    }
  }
  
  /// 获取缓存的音频文件
  Future<File?> _getCachedAudio(String text, String? voiceType) async {
    // TODO: 实现缓存检查逻辑
    // 这里可以查询数据库检查是否已缓存
    return null;
  }
  
  /// 保存到缓存
  Future<void> _saveToCache(String text, String? voiceType, File tempFile) async {
    // TODO: 实现缓存保存逻辑
    // 这里可以将临时文件移动到缓存目录，并更新数据库
  }
  
  /// 释放资源
  void dispose() {
    _streamSubscription?.cancel();
    _audioPlayer.dispose();
    playerState.dispose();
    playProgress.dispose();
    currentSubtitle.dispose();
    subtitles.dispose();
  }
}

/// 扩展：用于实时播放的音频源（需要 audioplayers 支持）
/// 注意：audioplayers 目前对实时流的支持有限，建议使用先下载后播放的方式
/// 如果需要真正的边下边播，可能需要使用 just_audio 或其他插件
