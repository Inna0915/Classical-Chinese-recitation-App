import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../models/tts_result.dart';
import '../models/poem.dart';
import '../models/voice_cache.dart';
import '../models/tts_result.dart';
import '../services/database_helper.dart';

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
  String _voiceType = 'BV001_streaming';
  double _speed = 1.0;

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
    return voiceType.contains('_V2_') ||
        voiceType.contains('bigtts') ||
        voiceType.contains('saturn') ||
        voiceType.contains('tob');
  }

  /// Get resource ID based on voice type
  String _getResourceId(String voiceType) {
    return _isVoice2(voiceType) ? 'seed-tts-2.0' : 'seed-tts-1.0';
  }

  /// Get or download audio for a poem
  Future<TtsResult> getOrDownloadAudio(
    Poem poem, {
    String? voiceType,
    AudioParams? audioParams,
    Function(double progress)? onProgress,
  }) async {
    await init();

    final voice = voiceType ?? _voiceType;
    final params = audioParams ?? const AudioParams();
    
    // Check cache first
    final cached = await _db.getVoiceCache(poem.id, voice);
    if (cached != null && await File(cached.filePath).exists()) {
      onProgress?.call(1.0);
      return TtsResult.success(
        audioPath: cached.filePath,
        isFromCache: true,
      );
    }

    // Synthesize audio
    _cancelToken = CancelToken();
    
    try {
      final file = await _synthesize(
        poem.content,
        voiceType: voice,
        audioParams: params,
        onProgress: onProgress,
        cancelToken: _cancelToken,
      );

      if (file == null) {
        return TtsResult.failure('合成失败');
      }

      // Save to cache
      await _db.saveVoiceCache(VoiceCache(
        poemId: poem.id,
        voiceType: voice,
        filePath: file.path,
        fileSize: await file.length(),
        createdAt: DateTime.now(),
      ));

      // Update poem's local audio path (for backward compatibility)
      await _db.updatePoemAudioPath(poem.id, file.path);

      return TtsResult.success(audioPath: file.path);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return TtsResult.failure('已取消');
      }
      return TtsResult.failure('下载失败: ${e.message}');
    } catch (e) {
      return TtsResult.failure('合成失败: $e');
    } finally {
      _cancelToken = null;
    }
  }

  /// Synthesize text to audio file
  Future<File?> _synthesize(
    String text, {
    required String voiceType,
    required AudioParams audioParams,
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final resourceId = _getResourceId(voiceType);
    
    // For Web platform, use stream API
    if (kIsWeb) {
      return await _synthesizeStreamWeb(
        text,
        voiceType: voiceType,
        resourceId: resourceId,
        cancelToken: cancelToken,
      );
    }

    try {
      final response = await _dio.post(
        '/api/v3/tts',
        options: Options(
          headers: {
            'Authorization': 'Bearer;$_accessToken',
          },
        ),
        cancelToken: cancelToken,
        data: {
          'app': {
            'appid': _appId,
            'token': 'access_token',
            'cluster': 'volcano_tts',
          },
          'user': {
            'uid': '388808087185088',
          },
          'audio': {
            'voice_type': voiceType,
            'encoding': 'mp3',
            'speed_ratio': audioParams.speedRatio,
            'volume_ratio': audioParams.volumeRatio,
          },
          'request': {
            'reqid': '${DateTime.now().millisecondsSinceEpoch}',
            'text': text,
            'operation': 'query',
            'resource_id': resourceId,
            'silence_duration': '100ms',
          },
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        if (data['data'] != null && data['data']['audio'] != null) {
          final audioData = base64Decode(data['data']['audio']);
          final dir = await getApplicationDocumentsDirectory();
          final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(audioData);
          onProgress?.call(1.0);
          return file;
        }
      }
      
      return null;
    } catch (e) {
      print('Synthesize error: $e');
      return null;
    }
  }

  /// Synthesize for Web platform using stream API
  Future<File?> _synthesizeStreamWeb(
    String text, {
    required String voiceType,
    required String resourceId,
    CancelToken? cancelToken,
  }) async {
    try {
      final List<int> audioChunks = [];
      
      final response = await _dio.post(
        '/api/v3/tts/unidirectional',
        options: Options(
          headers: {
            'Authorization': 'Bearer;$_accessToken',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        data: {
          'app': {
            'appid': _appId,
            'token': 'access_token',
            'cluster': 'volcano_tts',
          },
          'user': {
            'uid': '388808087185088',
          },
          'audio': {
            'voice_type': voiceType,
            'encoding': 'mp3',
            'speed_ratio': 1.0,
          },
          'request': {
            'reqid': '${DateTime.now().millisecondsSinceEpoch}',
            'text': text,
            'operation': 'query',
            'resource_id': resourceId,
            'silence_duration': '100ms',
          },
        },
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        
        await for (final chunk in stream.stream) {
          if (cancelToken?.isCancelled ?? false) break;
          
          final lines = utf8.decode(chunk).trim().split('\n');
          
          for (final line in lines) {
            if (line.isEmpty) continue;
            
            try {
              final data = jsonDecode(line);
              
              if (data['error'] != null) {
                print('Stream error: ${data['error']}');
                continue;
              }
              
              if (data['audio'] != null) {
                audioChunks.addAll(base64Decode(data['audio']));
              }
            } catch (e) {
              // Skip invalid lines
            }
          }
        }
      }

      if (audioChunks.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(audioChunks);
      return file;
    } catch (e) {
      print('Stream synthesize error: $e');
      return null;
    }
  }

  /// Cancel current download
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled');
    }
  }

  /// Check if poem has cached audio for specific voice
  Future<VoiceCache?> getCachedAudio(int poemId, String voiceType) async {
    return await _db.getVoiceCache(poemId, voiceType);
  }

  /// Get all cached voices for a poem
  Future<List<VoiceCache>> getCachedVoices(int poemId) async {
    return await _db.getVoiceCachesForPoem(poemId);
  }

  /// Cache audio file for poem and voice
  Future<void> cacheAudio(int poemId, String voiceType, File audioFile) async {
    await _db.saveVoiceCache(VoiceCache(
      poemId: poemId,
      voiceType: voiceType,
      filePath: audioFile.path,
      fileSize: await audioFile.length(),
      createdAt: DateTime.now(),
    ));
  }

  /// Clear audio cache for a specific poem (all voices)
  Future<void> clearAudioCache(int poemId) async {
    await _db.deleteAllVoiceCachesForPoem(poemId);
    await _db.updatePoemAudioPath(poemId, null);
  }

  /// Clear voice cache for a poem
  Future<void> clearCache(int poemId, String voiceType) async {
    await _db.deleteVoiceCache(poemId, voiceType);
  }

  /// Clear all voice caches for a poem
  Future<void> clearAllCaches(int poemId) async {
    await _db.deleteAllVoiceCachesForPoem(poemId);
  }

  /// Get total cache size in MB
  Future<double> getCacheSize() async {
    final size = await _db.getVoiceCacheSize();
    return size / (1024 * 1024); // Convert to MB
  }

  /// Stream audio data while synthesizing
  Future<void> streamAudio(String text, {
    String? customVoiceType,
    Function(double progress)? onProgress,
  }) async {
    await init();
    
    final voice = customVoiceType ?? _voiceType;
    final resourceId = _getResourceId(voice);
    
    try {
      final response = await _dio.post(
        '/api/v3/tts/unidirectional',
        options: Options(
          headers: {
            'Authorization': 'Bearer;$_accessToken',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'app': {
            'appid': _appId,
            'token': 'access_token',
            'cluster': 'volcano_tts',
          },
          'user': {
            'uid': '388808087185088',
          },
          'audio': {
            'voice_type': voice,
            'encoding': 'mp3',
            'speed_ratio': _speed,
          },
          'request': {
            'reqid': '${DateTime.now().millisecondsSinceEpoch}',
            'text': text,
            'operation': 'query',
            'resource_id': resourceId,
            'silence_duration': '100ms',
          },
        },
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        int totalBytes = 0;
        
        await for (final chunk in stream.stream) {
          final lines = utf8.decode(chunk).trim().split('\n');
          
          for (final line in lines) {
            if (line.isEmpty) continue;
            
            try {
              final data = jsonDecode(line);
              
              if (data['error'] != null) {
                print('Stream error: ${data['error']}');
                continue;
              }
              
              if (data['audio'] != null) {
                final audioBytes = base64Decode(data['audio']);
                _audioStreamController.add(audioBytes);
                totalBytes += audioBytes.length;
                
                final textLength = text.length;
                final progress = (totalBytes / (textLength * 1000)).clamp(0.0, 1.0);
                onProgress?.call(progress);
              }
            } catch (e) {
              // Skip invalid lines
            }
          }
        }
      }
    } catch (e) {
      print('Stream error: $e');
    }
  }

  /// Test connection to TTS API
  Future<ConnectionResult> testConnection() async {
    try {
      await init();
      final response = await _dio.post(
        '/api/v3/tts',
        options: Options(
          headers: {
            'Authorization': 'Bearer;$_accessToken',
          },
        ),
        data: {
          'app': {
            'appid': _appId,
            'token': 'access_token',
            'cluster': 'volcano_tts',
          },
          'user': {
            'uid': 'test',
          },
          'audio': {
            'voice_type': _voiceType,
            'encoding': 'mp3',
          },
          'request': {
            'reqid': '${DateTime.now().millisecondsSinceEpoch}',
            'text': '测试',
            'operation': 'query',
            'resource_id': _getResourceId(_voiceType),
          },
        },
      );
      
      if (response.statusCode == 200) {
        return ConnectionResult.success();
      } else {
        return ConnectionResult.failure(
          statusCode: response.statusCode ?? 0,
          message: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Test connection error: $e');
      return ConnectionResult.failure(
        statusCode: e.response?.statusCode ?? 0,
        message: e.message ?? '连接失败',
      );
    } catch (e) {
      print('Test connection error: $e');
      return ConnectionResult.failure(message: e.toString());
    }
  }

  /// Clear all audio cache
  Future<void> clearAllAudioCache() async {
    final caches = await _db.getAllVoiceCaches();
    for (final cache in caches) {
      try {
        final file = File(cache.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Delete cache file error: $e');
      }
    }
    await _db.clearAllVoiceCaches();
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

  ConnectionResult({
    required this.isSuccess,
    this.statusCode = 0,
    this.errorMessage,
  });

  factory ConnectionResult.success() {
    return ConnectionResult(isSuccess: true);
  }

  factory ConnectionResult.failure({int statusCode = 0, String? message}) {
    return ConnectionResult(
      isSuccess: false,
      statusCode: statusCode,
      errorMessage: message,
    );
  }
}
