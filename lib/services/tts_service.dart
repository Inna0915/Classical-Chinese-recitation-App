import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
// import '../models/poem.dart';  // 语音缓存功能暂时禁用
import '../models/voice_cache.dart';
import '../models/tts_result.dart';
import '../services/database_helper.dart';

/// 调试日志条目
class TtsDebugLog {
  final DateTime timestamp;
  final String type; // 'request', 'response', 'error'
  final String title;
  final String content;

  TtsDebugLog({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.content,
  });
}

/// 词级别时间戳
class WordTimestamp {
  final String word;
  final double startTime; // 秒
  final double endTime;   // 秒
  final double confidence;

  WordTimestamp({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  factory WordTimestamp.fromJson(Map<String, dynamic> json) {
    return WordTimestamp(
      word: json['word'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// 字幕信息
class SubtitleInfo {
  final String text;
  final List<WordTimestamp>? words;
  final DateTime timestamp;

  SubtitleInfo({
    required this.text,
    this.words,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 合成结果内部类
class _SynthesizeResult {
  final File audioFile;
  final String? timestampPath;
  final List<TimestampItem>? timestamps;
  
  _SynthesizeResult({
    required this.audioFile,
    this.timestampPath,
    this.timestamps,
  });
}

/// 流式事件类型
enum TtsStreamEventType {
  audio,      // 音频数据
  subtitle,   // 字幕信息
  complete,   // 合成完成
  error,      // 错误
}

/// 流式播放事件
class TtsStreamEvent {
  final TtsStreamEventType type;
  final List<int>? bytes;          // 音频数据（audio 类型）
  final int? totalBytes;           // 累计字节数
  final String? text;              // 字幕文本（subtitle 类型）
  final List<WordTimestamp>? words; // 词级别时间戳
  final int? code;                 // 错误码（error 类型）
  final String? message;           // 错误信息

  TtsStreamEvent._({
    required this.type,
    this.bytes,
    this.totalBytes,
    this.text,
    this.words,
    this.code,
    this.message,
  });

  /// 音频数据事件
  factory TtsStreamEvent.audio({
    required List<int> bytes,
    int? totalBytes,
  }) => TtsStreamEvent._(
    type: TtsStreamEventType.audio,
    bytes: bytes,
    totalBytes: totalBytes,
  );

  /// 字幕信息事件
  factory TtsStreamEvent.subtitle({
    required String text,
    List<WordTimestamp>? words,
  }) => TtsStreamEvent._(
    type: TtsStreamEventType.subtitle,
    text: text,
    words: words,
  );

  /// 完成事件
  factory TtsStreamEvent.complete({
    int? totalBytes,
  }) => TtsStreamEvent._(
    type: TtsStreamEventType.complete,
    totalBytes: totalBytes,
  );

  /// 错误事件
  factory TtsStreamEvent.error({
    required int code,
    required String message,
  }) => TtsStreamEvent._(
    type: TtsStreamEventType.error,
    code: code,
    message: message,
  );
}

/// TTS 服务 - 支持 Doubao 1.0 和 2.0
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final Dio _dio = Dio();
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isInitialized = false;
  String _appId = TtsConstants.appId;
  String _accessToken = TtsConstants.accessToken;
  String _voiceType = TtsVoices.defaultVoice;
  double _speed = 1.0;

  // 调试日志列表 - 使用 RxList 支持响应式更新
  final RxList<TtsDebugLog> debugLogs = <TtsDebugLog>[].obs;

  // Cancel token for download cancellation
  CancelToken? _cancelToken;

  // Stream controller for audio chunks
  final StreamController<List<int>> _audioStreamController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get audioStream => _audioStreamController.stream;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _dio.options.baseUrl = TtsConstants.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    _isInitialized = true;
  }

  // Getters
  String get appId => _appId;
  String get accessToken => _accessToken;
  String get voiceType => _voiceType;
  double get speed => _speed;

  /// 添加调试日志
  void _addDebugLog(String type, String title, String content) {
    final log = TtsDebugLog(
      timestamp: DateTime.now(),
      type: type,
      title: title,
      content: content,
    );
    debugLogs.add(log);
    // 只保留最近50条日志
    if (debugLogs.length > 50) {
      debugLogs.removeAt(0);
    }
  }

  /// 清空调试日志
  void clearDebugLogs() {
    debugLogs.clear();
  }

  // Configuration
  void setCredentials(String appId, String accessToken) {
    _appId = appId;
    _accessToken = accessToken;
  }

  void setVoiceType(String voiceType) {
    _voiceType = voiceType;
  }

  void setSpeed(double speed) {
    _speed = speed;
  }

  /// Check if voice type is 2.0 (seed-tts-2.0)
  bool _isVoice2(String voiceType) {
    // 使用 TtsVoices 的判断逻辑
    return TtsVoices.isVoice2(voiceType);
  }

  /// Get resource ID based on voice type
  String _getResourceId(String voiceType) {
    return TtsVoices.needs2Api(voiceType) ? 'seed-tts-2.0' : 'seed-tts-1.0';
  }

  /// 合成文本为音频（支持按音色缓存）
  Future<TtsResult> synthesizeText({
    required String text,
    required int poemId,
    String? voiceType,
    AudioParams? audioParams,
    Function(double progress)? onProgress,
  }) async {
    _addDebugLog('info', 'synthesizeText 开始', '开始TTS合成流程');
    await init();

    final voice = voiceType ?? _voiceType;
    final params = audioParams ?? const AudioParams();
    _addDebugLog('info', '使用音色', voice);
    
    // 语音缓存功能暂时禁用 - 直接走网络请求
    // TODO: 恢复缓存功能
    _addDebugLog('info', '缓存已禁用', '直接进行TTS合成');

    // Synthesize audio
    _cancelToken = CancelToken();
    
    try {
      _addDebugLog('info', '调用_synthesize', '开始网络请求');
      final result = await _synthesize(
        text,
        voiceType: voice,
        audioParams: params,
        onProgress: onProgress,
        cancelToken: _cancelToken,
      );
      _addDebugLog('info', '_synthesize返回', result?.audioFile.path ?? 'null');

      if (result == null) {
        return TtsResult.failure('合成失败');
      }

      // 语音缓存功能暂时禁用
      // TODO: 恢复缓存功能
      // await _db.saveVoiceCache(VoiceCache(
      //   poemId: poemId,
      //   voiceType: voice,
      //   filePath: result.audioFile.path,
      //   timestampPath: result.timestampPath,
      //   fileSize: await result.audioFile.length(),
      //   createdAt: DateTime.now(),
      // ));

      return TtsResult.success(
        audioPath: result.audioFile.path,
        timestampPath: result.timestampPath,
        timestamps: result.timestamps,
      );
    } on DioException catch (e) {
      final errorMsg = '网络错误: ${e.type} - ${e.message}';
      _addDebugLog('error', '网络错误', errorMsg);
      return TtsResult.failure(errorMsg);
    } catch (e) {
      _addDebugLog('error', '未知错误', e.toString());
      return TtsResult.failure('合成失败: $e');
    } finally {
      _cancelToken = null;
    }
  }

  /// 检查指定诗词和音色是否已缓存（语音缓存功能暂时禁用）
  Future<bool> isVoiceCached(int poemId, String voiceType) async {
    // 语音缓存功能暂时禁用
    return false;
  }

  /// Synthesize text to audio file
  Future<_SynthesizeResult?> _synthesize(
    String text, {
    required String voiceType,
    required AudioParams audioParams,
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final isVoice2 = _isVoice2(voiceType);
    final resourceId = isVoice2 ? 'seed-tts-2.0' : 'seed-tts-1.0';
    
    _addDebugLog('info', '开始合成', '音色:$voiceType, 资源ID:$resourceId');
    _addDebugLog('info', '开始合成', '音色: $voiceType, 资源ID: $resourceId, 文本: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');
    
    // For Web platform, use stream API
    if (kIsWeb) {
      return await _synthesizeStreamWeb(
        text,
        voiceType: voiceType,
        audioParams: audioParams,
        resourceId: resourceId,
        isVoice2: isVoice2,
        cancelToken: cancelToken,
      );
    }

    try {
      _addDebugLog('info', '构建请求参数', '准备HTTP请求体');
      // 构建请求体 - 添加 with_timestamp 获取时间戳
      final reqParams = <String, dynamic>{
        'text': text,
        'speaker': voiceType,
        'audio_params': {
          'format': 'mp3',
          'sample_rate': 24000,
          'speech_rate': audioParams.speechRate,
          'loudness_rate': audioParams.loudnessRate,
          'with_timestamp': 1, // 开启时间戳
        },
      };
      
      // 1.0 音色添加 model 字段
      if (!isVoice2) {
        reqParams['model'] = 'seed-tts-1.1';
      }
      
      _addDebugLog('request', '发送HTTP请求', 'URL: https://openspeech.bytedance.com/api/v3/tts/unidirectional\nHeaders: X-Api-App-Id=${_appId.substring(0, 8)}..., X-Api-Resource-Id=$resourceId\nBody: ${jsonEncode({'user': {'uid': '388808087185088'}, 'req_params': reqParams})}');
      
      final response;
      try {
        response = await _dio.post<ResponseBody>(
          'https://openspeech.bytedance.com/api/v3/tts/unidirectional',
          options: Options(
            headers: {
              'X-Api-App-Id': _appId,
              'X-Api-Access-Key': _accessToken,
              'X-Api-Resource-Id': resourceId,
              'Content-Type': 'application/json',
            },
            responseType: ResponseType.stream,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
          cancelToken: cancelToken,
          data: {
            'user': {
              'uid': '388808087185088',
            },
            'req_params': reqParams,
          },
        );
        _addDebugLog('response', '收到响应', '状态码: ${response.statusCode}');
      } on DioException catch (e) {
        _addDebugLog('error', 'DioException', '${e.type}, ${e.message}\nResponse: ${e.response}');
        rethrow;
      }

      // 处理流式响应 - 使用缓冲区处理跨块的 NDJSON
      _addDebugLog('info', '开始处理流式响应', '接收NDJSON数据流');
      final List<int> audioChunks = [];
      final List<Map<String, dynamic>> timestampList = []; // 收集时间戳
      final stream = response.data as ResponseBody;
      final buffer = StringBuffer();
      int chunkCount = 0;
      
      await for (final chunk in stream.stream) {
        chunkCount++;
        if (chunkCount % 10 == 0) {
      // 每10个数据块记录一次
      if (chunkCount % 10 == 0) {
        _addDebugLog('info', '接收数据块', '已接收 $chunkCount 个数据块');
      }
        }
        if (cancelToken?.isCancelled ?? false) break;
        
        // 将字节数据解码并添加到缓冲区
        buffer.write(utf8.decode(chunk));
        
        // 按行分割处理 NDJSON
        final lines = buffer.toString().split('\n');
        
        // 保留最后一行（可能不完整）到缓冲区
        buffer.clear();
        if (lines.isNotEmpty && !lines.last.trim().endsWith('}')) {
          buffer.write(lines.last);
        }
        
        // 处理完整的行
        for (int i = 0; i < lines.length - (buffer.isNotEmpty ? 1 : 0); i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          
          try {
            final data = jsonDecode(line) as Map<String, dynamic>;
            final code = data['code'] as int?;
            
            // 处理音频数据块: code == 0 且 data != null
            if (code == 0 && data['data'] != null) {
              final audioBytes = base64Decode(data['data'] as String);
              audioChunks.addAll(audioBytes);
            }
            // 处理时间戳数据 - 在 addition 字段中
            else if (code == 0 && data['addition'] != null) {
              _addDebugLog('response', '收到addition数据', jsonEncode(data['addition']));
              final addition = data['addition'] as Map<String, dynamic>;
              // 尝试多种可能的时间戳字段路径
              final frontendMsg = addition['frontend_message'];
              if (frontendMsg != null && frontendMsg is List) {
                _addDebugLog('info', '找到frontend_message', '共 ${frontendMsg.length} 条');
                // 解析字级别时间戳
                for (final item in frontendMsg) {
                  if (item is Map<String, dynamic>) {
                    timestampList.add(item);
                  }
                }
              }
              // 备选：直接尝试 addition 中的其他字段
              if (timestampList.isEmpty) {
                final words = addition['words'] ?? addition['timestamps'] ?? addition['chars'];
                if (words != null && words is List) {
                  _addDebugLog('info', '找到备选时间戳字段', '共 ${words.length} 条');
                  for (final item in words) {
                    if (item is Map<String, dynamic>) {
                      timestampList.add(item);
                    }
                  }
                }
              }
              // 如果还是空的，打印 addition 的所有键
              if (timestampList.isEmpty) {
                _addDebugLog('info', 'addition字段keys', addition.keys.toList().toString());
              }
            }
            // 备选：有些API版本可能直接在data中包含时间戳
            else if (code == 0 && data['timestamps'] != null) {
              _addDebugLog('info', '找到data.timestamps', '');
              final ts = data['timestamps'];
              if (ts is List) {
                for (final item in ts) {
                  if (item is Map<String, dynamic>) {
                    timestampList.add(item);
                  }
                }
              }
            }
            // 处理错误码
            else if (code != null && code != 0 && code != 20000000) {
              _addDebugLog('error', 'Stream Error', 'Code: $code, Message: ${data['message']}');
            }
          } catch (e) {
            // Skip invalid lines
          }
        }
      }

      _addDebugLog('info', '流处理完成', '数据块:$chunkCount, 音频:${audioChunks.length}bytes, 时间戳:${timestampList.length}条');
      
      // 打印完整的时间戳数据（用于分析）
      if (timestampList.isNotEmpty) {
        final tsSample = timestampList.take(3).map((e) => jsonEncode(e)).join('\n');
        _addDebugLog('info', '时间戳数据示例', '[1-${timestampList.length}]\n$tsSample\n字段keys: ${timestampList.first.keys.toList()}');
      }
      
      if (audioChunks.isEmpty) {
        _addDebugLog('error', '合成失败', '未收到音频数据');
        _addDebugLog('error', '合成失败', '未收到音频数据');
        return null;
      }

      _addDebugLog('info', '保存音频文件', '');
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tts_$ts.mp3';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(audioChunks);
      
      // 保存时间戳文件并转换为 TimestampItem 列表
      String? timestampPath;
      List<TimestampItem>? timestamps;
      if (timestampList.isNotEmpty) {
        final tsFileName = 'tts_$ts.json';
        timestampPath = '${dir.path}/$tsFileName';
        final tsFile = File(timestampPath);
        await tsFile.writeAsString(jsonEncode(timestampList));
        
        // 转换为 TimestampItem 列表
        timestamps = timestampList.map((item) => TimestampItem.fromJson(item)).toList();
        _addDebugLog('info', '保存时间戳文件', '$timestampPath, ${timestamps.length}条');
      }
      
      // 打印完整返回结果
      _addDebugLog('info', '合成成功', '音频:${file.path}, 大小:${audioChunks.length}bytes, 时间戳:${timestampList.length}条, 时间戳文件:$timestampPath');
      if (timestamps != null && timestamps.isNotEmpty) {
        _addDebugLog('info', '时间戳范围', '首字:${timestamps.first.char}(${timestamps.first.startTime}ms)~尾字:${timestamps.last.char}(${timestamps.last.endTime}ms)');
      }
      _addDebugLog('info', '合成完成', '');
      
      _addDebugLog('info', '合成成功', '文件: ${file.path}, 大小: ${audioChunks.length} bytes, 时间戳: ${timestampList.length}');
      onProgress?.call(1.0);
      
      return _SynthesizeResult(
        audioFile: file,
        timestampPath: timestampPath,
        timestamps: timestamps,
      );
    } catch (e) {
      _addDebugLog('error', '合成异常', e.toString());
      _addDebugLog('error', '合成异常', e.toString());
      return null;
    }
  }

  /// Synthesize for Web platform using stream API
  Future<_SynthesizeResult?> _synthesizeStreamWeb(
    String text, {
    required String voiceType,
    required AudioParams audioParams,
    required String resourceId,
    required bool isVoice2,
    CancelToken? cancelToken,
  }) async {
    try {
      final List<int> audioChunks = [];
      
      // 构建请求体 - 添加 with_timestamp 获取时间戳
      final reqParams = <String, dynamic>{
        'text': text,
        'speaker': voiceType,
        'audio_params': {
          'format': 'mp3',
          'sample_rate': 24000,
          'speech_rate': audioParams.speechRate,
          'loudness_rate': audioParams.loudnessRate,
          'with_timestamp': 1, // 开启时间戳
        },
      };
      
      // 1.0 音色添加 model 字段
      if (!isVoice2) {
        reqParams['model'] = 'seed-tts-1.1';
      }
      
      final response = await _dio.post(
        'https://openspeech.bytedance.com/api/v3/tts/unidirectional',
        options: Options(
          headers: {
            'X-Api-App-Id': _appId,
            'X-Api-Access-Key': _accessToken,
            'X-Api-Resource-Id': resourceId,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        data: {
          'user': {
            'uid': '388808087185088',
          },
          'req_params': reqParams,
        },
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final buffer = StringBuffer();
        
        await for (final chunk in stream.stream) {
          if (cancelToken?.isCancelled ?? false) break;
          
          // 将字节数据解码并添加到缓冲区
          buffer.write(utf8.decode(chunk));
          
          // 按行分割处理 NDJSON
          final lines = buffer.toString().split('\n');
          
          // 保留最后一行（可能不完整）到缓冲区
          buffer.clear();
          if (lines.isNotEmpty && !lines.last.trim().endsWith('}')) {
            buffer.write(lines.last);
          }
          
          // 处理完整的行
          for (int i = 0; i < lines.length - (buffer.isNotEmpty ? 1 : 0); i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            
            try {
              final data = jsonDecode(line) as Map<String, dynamic>;
              final code = data['code'] as int?;
              
              // 处理音频数据块: code == 0 且 data != null
              if (code == 0 && data['data'] != null) {
                audioChunks.addAll(base64Decode(data['data'] as String));
              }
            } catch (e) {
              // Skip invalid lines
            }
          }
        }
      }

      if (audioChunks.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tts_$ts.mp3';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(audioChunks);
      
      // Web 平台暂时不支持时间戳，返回空
      return _SynthesizeResult(
        audioFile: file,
        timestampPath: null,
        timestamps: null,
      );
    } catch (e) {
      _addDebugLog('error', 'Stream合成错误', e.toString());
      return null;
    }
  }
  
  /// 获取时间戳数据文件路径（与音频文件对应）
  String? _getTimestampPath(String audioPath) {
    if (audioPath.endsWith('.mp3')) {
      return audioPath.replaceAll('.mp3', '.json');
    }
    return null;
  }

  /// Cancel current download
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled');
    }
  }

  /// Check if poem has cached audio for specific voice（语音缓存功能暂时禁用）
  Future<VoiceCache?> getCachedAudio(int poemId, String voiceType) async {
    // 语音缓存功能暂时禁用
    return null;
  }

  /// Get all cached voices for a poem（语音缓存功能暂时禁用）
  Future<List<VoiceCache>> getCachedVoices(int poemId) async {
    // 语音缓存功能暂时禁用
    return [];
  }

  /// Cache audio file for poem and voice（语音缓存功能暂时禁用）
  Future<void> cacheAudio(int poemId, String voiceType, File audioFile) async {
    // 语音缓存功能暂时禁用
    // TODO: 恢复缓存功能
  }

  /// Clear audio cache for a specific poem (all voices)（语音缓存功能暂时禁用）
  Future<void> clearAudioCache(int poemId) async {
    // 语音缓存功能暂时禁用
    // TODO: 恢复缓存功能
  }

  /// Clear voice cache for a poem（语音缓存功能暂时禁用）
  Future<void> clearCache(int poemId, String voiceType) async {
    // 语音缓存功能暂时禁用
    // TODO: 恢复缓存功能
  }

  /// Clear all voice caches for a poem（语音缓存功能暂时禁用）
  Future<void> clearAllCaches(int poemId) async {
    // 语音缓存功能暂时禁用
    // TODO: 恢复缓存功能
  }

  /// Get total cache size in MB（语音缓存功能暂时禁用）
  Future<double> getCacheSize() async {
    // 语音缓存功能暂时禁用，返回 0
    return 0.0;
  }

  /// 流式播放音频 - 完整的 NDJSON 解析实现
  /// 
  /// 返回：Stream<TtsStreamEvent> 包含音频数据和字幕信息
  Stream<TtsStreamEvent> streamAudioV2(
    String text, {
    String? customVoiceType,
    bool enableSubtitle = false,
  }) async* {
    await init();
    
    final voice = customVoiceType ?? _voiceType;
    final isVoice2 = _isVoice2(voice);
    final resourceId = isVoice2 ? 'seed-tts-2.0' : 'seed-tts-1.0';
    
    // 构建请求体
    final reqParams = <String, dynamic>{
      'text': text,
      'speaker': voice,
      'audio_params': {
        'format': 'mp3',
        'sample_rate': 24000,
        'speech_rate': _speed,
      },
    };
    
    // 1.0 音色添加 model 字段
    if (!isVoice2) {
      reqParams['model'] = 'seed-tts-1.1';
    }
    
    // 2.0 音色可选开启字幕
    if (isVoice2 && enableSubtitle) {
      reqParams['audio_params']['enable_subtitle'] = true;
    }
    
    try {
      _addDebugLog('request', 'Stream Request', 
        '音色: $voice\nResource-ID: $resourceId\n文本: $text');
      
      final response = await _dio.post(
        'https://openspeech.bytedance.com/api/v3/tts/unidirectional',
        options: Options(
          headers: {
            'X-Api-App-Id': _appId,
            'X-Api-Access-Key': _accessToken,
            'X-Api-Resource-Id': resourceId,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'user': {'uid': '388808087185088'},
          'req_params': reqParams,
        },
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final buffer = StringBuffer();
        int totalAudioBytes = 0;
        
        await for (final chunk in stream.stream) {
          // 将字节数据解码为字符串并添加到缓冲区
          buffer.write(utf8.decode(chunk));
          
          // 按行分割处理 NDJSON
          final lines = buffer.toString().split('\n');
          
          // 保留最后一行（可能不完整）到缓冲区
          buffer.clear();
          if (lines.isNotEmpty && !lines.last.trim().endsWith('}')) {
            buffer.write(lines.last);
          }
          
          // 处理完整的行
          for (int i = 0; i < lines.length - (buffer.isNotEmpty ? 1 : 0); i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            
            try {
              final data = jsonDecode(line) as Map<String, dynamic>;
              final code = data['code'] as int?;
              
              // 处理音频数据块: code == 0 且 data != null
              if (code == 0 && data['data'] != null) {
                final audioBase64 = data['data'] as String;
                final audioBytes = base64Decode(audioBase64);
                totalAudioBytes += audioBytes.length;
                
                yield TtsStreamEvent.audio(
                  bytes: audioBytes,
                  totalBytes: totalAudioBytes,
                );
              }
              
              // 处理字幕信息: code == 0 且 sentence != null
              else if (code == 0 && data['sentence'] != null) {
                final sentence = data['sentence'] as Map<String, dynamic>;
                yield TtsStreamEvent.subtitle(
                  text: sentence['text'] as String? ?? '',
                  words: (sentence['words'] as List<dynamic>?)
                      ?.map((w) => WordTimestamp.fromJson(w as Map<String, dynamic>))
                      .toList(),
                );
              }
              
              // 处理结束标记: code == 20000000
              else if (code == 20000000) {
                _addDebugLog('response', 'Stream Complete', 
                  '合成完成，总音频字节: $totalAudioBytes');
                yield TtsStreamEvent.complete(
                  totalBytes: totalAudioBytes,
                );
              }
              
              // 处理错误
              else if (code != null && code != 0 && code != 20000000) {
                final message = data['message'] as String? ?? 'Unknown error';
                _addDebugLog('error', 'Stream Error', 'Code: $code, Message: $message');
                yield TtsStreamEvent.error(
                  code: code,
                  message: message,
                );
              }
            } catch (e) {
              _addDebugLog('error', 'Parse Error', 'Failed to parse line: $e\nLine: $line');
            }
          }
        }
        
        // 处理缓冲区中剩余的数据
        final remaining = buffer.toString().trim();
        if (remaining.isNotEmpty) {
          try {
            final data = jsonDecode(remaining) as Map<String, dynamic>;
            final code = data['code'] as int?;
            
            if (code == 0 && data['data'] != null) {
              final audioBytes = base64Decode(data['data'] as String);
              yield TtsStreamEvent.audio(bytes: audioBytes);
            } else if (code == 20000000) {
              yield TtsStreamEvent.complete();
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    } on DioException catch (e) {
      _addDebugLog('error', 'Network Error', '${e.type}: ${e.message}');
      yield TtsStreamEvent.error(
        code: e.response?.statusCode ?? -1,
        message: e.message ?? 'Network error',
      );
    } catch (e) {
      _addDebugLog('error', 'Stream Error', e.toString());
      yield TtsStreamEvent.error(
        code: -1,
        message: e.toString(),
      );
    }
  }

  /// 将流式音频数据保存到临时文件
  Future<File?> streamToFile(
    String text, {
    String? customVoiceType,
    Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/tts_stream_${DateTime.now().millisecondsSinceEpoch}.mp3');
    
    final sink = tempFile.openWrite();
    int totalBytes = 0;
    
    try {
      await for (final event in streamAudioV2(text, customVoiceType: customVoiceType)) {
        switch (event.type) {
          case TtsStreamEventType.audio:
            sink.add(event.bytes!);
            totalBytes += event.bytes!.length;
            if (totalBytes % (50 * 1024) < 1024) { // 每约50KB更新一次进度
              onProgress?.call(0.5); // 简化进度计算
            }
            break;
          case TtsStreamEventType.complete:
            await sink.close();
            _addDebugLog('info', 'Stream Saved', '文件: ${tempFile.path}, 大小: $totalBytes bytes');
            return tempFile;
          case TtsStreamEventType.error:
            await sink.close();
            try { await tempFile.delete(); } catch (_) {}
            throw Exception(event.message);
          default:
            break;
        }
      }
      await sink.close();
      return tempFile;
    } catch (e) {
      await sink.close();
      try { await tempFile.delete(); } catch (_) {}
      rethrow;
    }
  }

  /// Test connection to TTS API with debug logging
  Future<ConnectionResult> testConnection() async {
    _addDebugLog('info', '开始测试', '准备连接 TTS 服务...');
    
    try {
      await init();
      
      // 判断是 1.0 还是 2.0
      final isVoice2 = _isVoice2(_voiceType);
      final resourceId = isVoice2 ? 'seed-tts-2.0' : 'seed-tts-1.0';
      
      // 构建请求体
      final reqParams = <String, dynamic>{
        'text': '床前明月光，疑是地上霜。',
        'speaker': _voiceType,
        'audio_params': {
          'format': 'mp3',
          'sample_rate': 24000,
        },
      };
      
      // 1.0 音色添加 model 字段
      if (!isVoice2) {
        reqParams['model'] = 'seed-tts-1.1';
      }
      
      final requestBody = {
        'user': {
          'uid': '388808087185088',
        },
        'req_params': reqParams,
      };
      
      // 记录请求信息
      final requestHeaders = {
        'X-Api-App-Id': _appId,
        'X-Api-Access-Key': '${_accessToken.substring(0, _accessToken.length > 8 ? 8 : _accessToken.length)}****',
        'X-Api-Resource-Id': resourceId,
        'Content-Type': 'application/json',
      };
      
      _addDebugLog('request', 'HTTP Request', 
        '【当前音色】: $_voiceType\n'
        '【API版本】: ${isVoice2 ? "2.0 (seed-tts-2.0)" : "1.0 (seed-tts-1.0)"}\n\n'
        'POST https://openspeech.bytedance.com/api/v3/tts/unidirectional\n\n'
        'Headers:\n${const JsonEncoder.withIndent('  ').convert(requestHeaders)}\n\n'
        'Body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}'
      );
      
      final List<String> responseLines = [];
      
      final response = await _dio.post(
        'https://openspeech.bytedance.com/api/v3/tts/unidirectional',
        options: Options(
          headers: {
            'X-Api-App-Id': _appId,
            'X-Api-Access-Key': _accessToken,
            'X-Api-Resource-Id': resourceId,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestBody,
      );
      
      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        bool hasAudioData = false;
        
        await for (final chunk in stream.stream) {
          final lines = utf8.decode(chunk).trim().split('\n');
          
          for (final line in lines) {
            if (line.isEmpty) continue;
            responseLines.add(line);
            
            try {
              final data = jsonDecode(line);
              
              if (data['code'] != null && data['code'] != 0 && data['code'] != 20000000) {
                _addDebugLog('error', 'Response Error', 
                  'Code: ${data['code']}\nMessage: ${data['message'] ?? 'Unknown error'}'
                );
                return ConnectionResult.failure(
                  statusCode: data['code'],
                  message: data['message'] ?? 'API 返回错误',
                );
              }
              
              // 检查音频数据: code == 0 且 data != null
              if (data['code'] == 0 && data['data'] != null) {
                hasAudioData = true;
              }
            } catch (e) {
              // Skip invalid lines
            }
          }
        }
        
        // 记录响应信息
        _addDebugLog('response', 'HTTP Response', 
          'Status: 200 OK\n\n'
          'Body (NDJSON):\n${responseLines.map((l) {
            try {
              final data = jsonDecode(l);
              // 音频数据在 "data" 字段，不是 "audio"
              if (data['data'] != null) {
                data['data'] = '[BASE64_AUDIO_DATA... (${data['data'].length} chars)]';
              }
              return const JsonEncoder.withIndent('  ').convert(data);
            } catch (_) {
              return l;
            }
          }).join('\n')}',
        );
        
        if (hasAudioData) {
          _addDebugLog('info', '测试成功', 'TTS 服务连接正常，成功接收音频数据');
          return ConnectionResult.success(debugLogs: debugLogs.toList());
        } else {
          _addDebugLog('error', '测试失败', '未收到音频数据');
          return ConnectionResult.failure(message: '未收到音频数据');
        }
      } else {
        _addDebugLog('error', 'HTTP Error', 'Status: ${response.statusCode}');
        return ConnectionResult.failure(
          statusCode: response.statusCode ?? 0,
          message: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final errorMsg = 'DioError: ${e.type}\nMessage: ${e.message}\nResponse: ${e.response?.data}';
      _addDebugLog('error', 'Connection Error', errorMsg);
      return ConnectionResult.failure(
        statusCode: e.response?.statusCode ?? 0,
        message: e.message ?? '连接失败',
        debugLogs: debugLogs.toList(),
      );
    } catch (e) {
      final errorMsg = 'Error: $e';
      _addDebugLog('error', 'Unexpected Error', errorMsg);
      return ConnectionResult.failure(
        message: e.toString(),
        debugLogs: debugLogs.toList(),
      );
    }
  }

  /// Clear all audio cache（语音缓存功能暂时禁用）
  Future<void> clearAllAudioCache() async {
    // 语音缓存功能暂时禁用
    // TODO: 恢复缓存功能
  }

  /// Dispose
  void dispose() {
    _audioStreamController.close();
  }
}

/// Connection test result
class ConnectionResult {
  final bool isSuccess;
  final int statusCode;
  final String? errorMessage;
  final List<TtsDebugLog>? debugLogs;

  ConnectionResult({
    required this.isSuccess,
    this.statusCode = 0,
    this.errorMessage,
    this.debugLogs,
  });

  factory ConnectionResult.success({List<TtsDebugLog>? debugLogs}) {
    return ConnectionResult(
      isSuccess: true,
      debugLogs: debugLogs,
    );
  }

  factory ConnectionResult.failure({
    int statusCode = 0,
    String? message,
    List<TtsDebugLog>? debugLogs,
  }) {
    return ConnectionResult(
      isSuccess: false,
      statusCode: statusCode,
      errorMessage: message,
      debugLogs: debugLogs,
    );
  }
}
