import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/enums.dart';
import '../models/poem.dart';
import '../models/tts_result.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import 'poem_controller.dart' show PlaybackState;

/// 播放器控制器 - 管理播放列表、播放模式、上一首/下一首
class PlayerController extends GetxController {
  static PlayerController get to => Get.find();

  final TtsService _ttsService = TtsService();
  AudioPlayer? _audioPlayer;

  // ==================== 播放列表状态 ====================
  
  /// 当前播放列表
  final RxList<Poem> playlist = <Poem>[].obs;
  
  /// 当前播放索引
  final RxInt currentIndex = (-1).obs;
  
  /// 播放模式
  final Rx<PlayMode> playMode = PlayMode.sequence.obs;
  
  /// 随机播放时的乱序索引列表
  final RxList<int> shuffleIndices = <int>[].obs;
  
  /// 当前在 shuffleIndices 中的位置
  int _shufflePosition = 0;

  // ==================== 播放状态 ====================
  
  /// 当前播放的诗词（可观察对象）
  final Rx<Poem?> currentPoemRx = Rx<Poem?>(null);
  
  /// 当前播放的诗词（对外暴露）
  Poem? get currentPoem => currentPoemRx.value;
  
  /// 更新当前诗词
  void _updateCurrentPoem() {
    if (currentIndex.value >= 0 && currentIndex.value < playlist.length) {
      currentPoemRx.value = playlist[currentIndex.value];
    } else {
      currentPoemRx.value = null;
    }
  }

  /// 播放状态
  final Rx<PlaybackState> playbackState = PlaybackState.idle.obs;
  
  /// 播放进度
  final Rx<Duration> position = Duration.zero.obs;
  
  /// 总时长
  final Rx<Duration> duration = Duration.zero.obs;
  
  /// 下载进度 (0.0 - 1.0)
  final RxDouble downloadProgress = 0.0.obs;
  
  /// 当前播放的时间戳数据（用于卡拉OK高亮）
  final RxList<TimestampItem> currentTimestamps = <TimestampItem>[].obs;

  // ==================== 初始化 ====================

  @override
  void onInit() {
    super.onInit();
    _initAudioPlayer();
    
    // 监听 currentIndex 变化，更新 currentPoem
    ever(currentIndex, (_) => _updateCurrentPoem());
    // 监听 playlist 变化，更新 currentPoem
    ever(playlist, (_) => _updateCurrentPoem());
  }

  @override
  void onClose() {
    _audioPlayer?.dispose();
    super.onClose();
  }

  void _initAudioPlayer() {
    if (kIsWeb) return;
    
    _audioPlayer = AudioPlayer();
    
    // 播放状态监听
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          playbackState.value = PlaybackState.playing;
          break;
        case PlayerState.paused:
          playbackState.value = PlaybackState.paused;
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          playbackState.value = PlaybackState.idle;
          break;
        case PlayerState.disposed:
          break;
      }
    });

    // 播放进度监听
    _audioPlayer!.onPositionChanged.listen((pos) {
      position.value = pos;
    });

    // 总时长监听
    _audioPlayer!.onDurationChanged.listen((dur) {
      duration.value = dur;
    });

    // 播放完成监听 - 自动播放下一首
    _audioPlayer!.onPlayerComplete.listen((_) {
      _onPlaybackComplete();
    });
  }

  // ==================== 播放列表操作 ====================

  /// 播放分组/列表
  /// 
  /// [poems] 要播放的诗词列表
  /// [initialIndex] 从第几首开始播放
  Future<void> playGroup(List<Poem> poems, int initialIndex) async {
    debugPrint('[PlayerController] playGroup called, poems: ${poems.length}, index: $initialIndex');
    if (poems.isEmpty) {
      debugPrint('[PlayerController] poems is empty, returning');
      return;
    }
    if (initialIndex < 0 || initialIndex >= poems.length) {
      initialIndex = 0;
    }

    // 设置播放列表
    playlist.assignAll(poems);
    currentIndex.value = initialIndex;
    debugPrint('[PlayerController] playlist set, currentIndex: $currentIndex, currentPoem: $currentPoem');

    // 如果是随机模式，生成乱序列表
    if (playMode.value == PlayMode.shuffle) {
      _generateShuffleIndices();
      // 找到 initialIndex 在乱序列表中的位置
      _shufflePosition = shuffleIndices.indexOf(initialIndex);
      if (_shufflePosition < 0) _shufflePosition = 0;
    }

    // 开始播放
    debugPrint('[PlayerController] calling _playAtIndex($currentIndex)');
    await _playAtIndex(currentIndex.value);
  }

  /// 播放下一首
  /// 
  /// [auto] 是否为自动播放（用于区分用户点击和播放完成自动触发）
  Future<void> playNext({bool auto = false}) async {
    if (playlist.isEmpty) return;

    int targetIndex;

    switch (playMode.value) {
      case PlayMode.singleLoop:
        // 单曲循环：自动播放时重播当前，用户点击时下一首
        if (auto) {
          targetIndex = currentIndex.value;
        } else {
          targetIndex = (currentIndex.value + 1) % playlist.length;
        }
        break;

      case PlayMode.shuffle:
        // 随机播放：按 shuffleIndices 顺序
        _shufflePosition = (_shufflePosition + 1) % shuffleIndices.length;
        targetIndex = shuffleIndices[_shufflePosition];
        break;

      case PlayMode.sequence:
        // 顺序播放：循环到下一首
        targetIndex = (currentIndex.value + 1) % playlist.length;
        break;
    }

    currentIndex.value = targetIndex;
    await _playAtIndex(targetIndex);
  }

  /// 播放上一首
  Future<void> playPrevious() async {
    if (playlist.isEmpty) return;

    int targetIndex;

    switch (playMode.value) {
      case PlayMode.singleLoop:
        // 单曲循环：上一首
        targetIndex = (currentIndex.value - 1 + playlist.length) % playlist.length;
        break;

      case PlayMode.shuffle:
        // 随机播放：按 shuffleIndices 逆序
        _shufflePosition = (_shufflePosition - 1 + shuffleIndices.length) % shuffleIndices.length;
        targetIndex = shuffleIndices[_shufflePosition];
        break;

      case PlayMode.sequence:
        // 顺序播放：循环到上一首
        targetIndex = (currentIndex.value - 1 + playlist.length) % playlist.length;
        break;
    }

    currentIndex.value = targetIndex;
    await _playAtIndex(targetIndex);
  }

  /// 切换播放模式
  void togglePlayMode() {
    playMode.value = playMode.value.next;
    
    // 如果切换到随机模式，生成乱序列表
    if (playMode.value == PlayMode.shuffle) {
      _generateShuffleIndices();
      _shufflePosition = shuffleIndices.indexOf(currentIndex.value);
      if (_shufflePosition < 0) _shufflePosition = 0;
    }
  }

  /// 从列表中移除指定索引的诗词
  void removeFromPlaylist(int index) {
    if (index < 0 || index >= playlist.length) return;

    // 如果删除的是当前播放的，先停止播放
    if (index == currentIndex.value) {
      stop();
      // 播放下一首（索引不变，因为删除后后面的会前移）
      if (playlist.length > 1) {
        // 延迟一下再播放，让UI更新
        Future.delayed(const Duration(milliseconds: 100), () {
          playlist.removeAt(index);
          if (currentIndex.value >= playlist.length) {
            currentIndex.value = 0;
          }
          if (playlist.isNotEmpty) {
            _playAtIndex(currentIndex.value);
          }
        });
        return;
      }
    } else if (index < currentIndex.value) {
      // 如果删除的是当前播放之前的，currentIndex 需要减1
      currentIndex.value--;
    }

    playlist.removeAt(index);
    
    // 重新生成乱序列表
    if (playMode.value == PlayMode.shuffle) {
      _generateShuffleIndices();
    }
  }

  /// 清空播放列表
  void clearPlaylist() {
    stop();
    playlist.clear();
    currentIndex.value = -1;
    shuffleIndices.clear();
    _shufflePosition = 0;
  }

  // ==================== 播放控制 ====================

  /// 播放指定索引的诗词
  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= playlist.length) return;

    final poem = playlist[index];
    await _startPlay(poem);
  }

  /// 开始播放
  Future<void> _startPlay(Poem poem) async {
    debugPrint('[PlayerController] _startPlay called for poem: ${poem.title}');
    playbackState.value = PlaybackState.loading;
    downloadProgress.value = 0.0;

    try {
      final settings = SettingsService.to;
      debugPrint('[PlayerController] voiceType: ${settings.voiceType.value}');
      _ttsService.setVoiceType(settings.voiceType.value);

      debugPrint('[PlayerController] calling TTS synthesizeText...');
      final result = await _ttsService.synthesizeText(
        text: '${poem.title}。${poem.dynasty != null ? '${poem.dynasty}·' : ''}${poem.author}。${poem.cleanContent}',
        voiceType: settings.voiceType.value,
        audioParams: AudioParams(
          speechRate: settings.speechRate.value,
          loudnessRate: settings.loudnessRate.value,
        ),
        poemId: poem.id,
        onProgress: (progress) {
          downloadProgress.value = progress;
        },
      );
      debugPrint('[PlayerController] TTS result: success=${result.isSuccess}, path=${result.audioPath}');

      if (!result.isSuccess) {
        debugPrint('[PlayerController] TTS failed: ${result.errorMessage}');
        playbackState.value = PlaybackState.error;
        return;
      }

      // 播放音频
      if (_audioPlayer == null) {
        debugPrint('[PlayerController] creating AudioPlayer...');
        _audioPlayer = AudioPlayer();
        _initAudioPlayer();
      }

      debugPrint('[PlayerController] reading audio file: ${result.audioPath}');
      final file = File(result.audioPath!);
      final bytes = await file.readAsBytes();
      debugPrint('[PlayerController] audio file size: ${bytes.length} bytes');
      
      debugPrint('[PlayerController] setting source and playing...');
      await _audioPlayer!.setSourceBytes(bytes);
      await _audioPlayer!.resume();
      debugPrint('[PlayerController] playback started!');
    } catch (e, stackTrace) {
      debugPrint('[PlayerController] _startPlay ERROR: $e');
      debugPrint('[PlayerController] stackTrace: $stackTrace');
      playbackState.value = PlaybackState.error;
    }
  }

  /// 播放/暂停切换
  Future<void> togglePlay() async {
    debugPrint('[PlayerController] togglePlay called, currentPoem: $currentPoem, state: ${playbackState.value}');
    final poem = currentPoem;
    if (poem == null) {
      debugPrint('[PlayerController] togglePlay: poem is null, returning');
      return;
    }

    if (playbackState.value == PlaybackState.loading) {
      // 加载中，取消播放
      debugPrint('[PlayerController] togglePlay: canceling download');
      _ttsService.cancelDownload();
      playbackState.value = PlaybackState.idle;
      return;
    }

    switch (playbackState.value) {
      case PlaybackState.idle:
      case PlaybackState.error:
        debugPrint('[PlayerController] togglePlay: playing from index $currentIndex');
        await _playAtIndex(currentIndex.value);
        break;
      case PlaybackState.playing:
        debugPrint('[PlayerController] togglePlay: pausing');
        await _audioPlayer?.pause();
        break;
      case PlaybackState.paused:
        debugPrint('[PlayerController] togglePlay: resuming');
        await _audioPlayer?.resume();
        break;
      default:
        break;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _audioPlayer?.stop();
    playbackState.value = PlaybackState.idle;
    position.value = Duration.zero;
  }

  /// 播放完成回调
  void _onPlaybackComplete() {
    // 自动播放下一首
    playNext(auto: true);
  }

  /// 生成乱序索引列表
  void _generateShuffleIndices() {
    if (playlist.isEmpty) {
      shuffleIndices.clear();
      return;
    }

    // 创建索引列表并打乱
    final indices = List<int>.generate(playlist.length, (i) => i);
    indices.shuffle(Random());
    
    // 确保当前播放的诗词在第一位（如果当前有播放）
    if (currentIndex.value >= 0 && currentIndex.value < playlist.length) {
      indices.remove(currentIndex.value);
      indices.insert(0, currentIndex.value);
      _shufflePosition = 0;
    }

    shuffleIndices.assignAll(indices);
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await _audioPlayer?.seek(position);
  }

  /// 检查指定诗词是否正在播放
  bool isPlayingPoem(int poemId) {
    final current = currentPoem;
    return current?.id == poemId && playbackState.value == PlaybackState.playing;
  }

  /// 检查指定诗词是否在播放列表中
  bool isInPlaylist(int poemId) {
    return playlist.any((p) => p.id == poemId);
  }
}

