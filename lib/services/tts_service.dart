import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../models/poem.dart';
import 'database_helper.dart';
import 'settings_service.dart';

/// TTS 服务结果状态
enum TtsResultStatus {
  /// 成功
  success,
  
  /// 网络错误
  networkError,
  
  /// API 错误（401等）
  apiError,
  
  /// 文件保存错误
  fileError,
  
  /// 已取消
  cancelled,
  
  /// Web 平台不支持
  notSupported,
}

/// TTS 服务结果
class TtsResult {
  final TtsResultStatus status;
  final String? audioPath;
  final String? errorMessage;
  /// Web 端音频数据（字节数组）
  final List<int>? audioBytes;
  /// Web 端音频 URL（Blob URL）
  final String? audioUrl;

  TtsResult({
    required this.status,
    this.audioPath,
    this.errorMessage,
    this.audioBytes,
    this.audioUrl,
  });

  bool get isSuccess => status == TtsResultStatus.success;
}

/// TTS 测试结果
class TtsTestResult {
  final bool isSuccess;
  final String? errorMessage;
  final int? statusCode;

  TtsTestResult({
    required this.isSuccess,
    this.errorMessage,
    this.statusCode,
  });
}

/// 音频参数配置
class AudioParams {
  final String format;
  final int sampleRate;
  final int? bitRate;
  final int speechRate;
  final int loudnessRate;
  final String? emotion;
  final int emotionScale;

  const AudioParams({
    this.format = 'mp3',
    this.sampleRate = 24000,
    this.bitRate,
    this.speechRate = 0,
    this.loudnessRate = 0,
    this.emotion,
    this.emotionScale = 4,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'format': format,
      'sample_rate': sampleRate,
    };
    if (bitRate != null) json['bit_rate'] = bitRate;
    if (speechRate != 0) json['speech_rate'] = speechRate;
    if (loudnessRate != 0) json['loudness_rate'] = loudnessRate;
    if (emotion != null) {
      json['emotion'] = emotion;
      json['emotion_scale'] = emotionScale;
    }
    return json;
  }
}

/// TTS 服务类 - 火山引擎 TTS v3 API
/// 
/// 文档：https://www.volcengine.com/docs/6561/196768
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final Dio _dio = Dio();
  
  /// 当前正在进行的请求（用于取消）
  CancelToken? _currentCancelToken;

  /// 初始化 Dio 配置
  void init() {
    _dio.options.connectTimeout = 
        Duration(seconds: TtsConstants.connectTimeout);
    _dio.options.receiveTimeout = 
        Duration(seconds: TtsConstants.receiveTimeout);
    // 接受所有状态码，自行处理
    _dio.options.validateStatus = (status) => true;
    
    // Web 平台：配置额外的浏览器选项
    if (kIsWeb) {
      _dio.options.extra['withCredentials'] = false;
    }
  }

  /// 构建请求头
  Map<String, dynamic> _buildHeaders() {
    final settings = SettingsService.to;
    return {
      'Content-Type': 'application/json',
      'X-Api-App-Id': settings.appId.value,
      'X-Api-Access-Key': settings.apiKey.value,
      'X-Api-Resource-Id': settings.resourceId.value,
      'Accept': 'application/json',
    };
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequestBody(
    String text, {
    String? voiceType,
    AudioParams? audioParams,
  }) {
    final settings = SettingsService.to;
    return {
      'user': {
        'uid': 'user_${DateTime.now().millisecondsSinceEpoch}',
      },
      'req_params': {
        'text': text,
        'speaker': voiceType ?? settings.voiceType.value,
        'model': TtsConstants.model,
        'audio_params': (audioParams ?? const AudioParams()).toJson(),
      },
    };
  }

  /// 测试 TTS 连接
  /// 
  /// 发送一个简单的测试请求，验证 API 配置和连接是否正常
  Future<TtsTestResult> testConnection() async {
    try {
      final requestBody = _buildRequestBody('测试');
      
      final response = await _dio.post(
        TtsConstants.apiUrl,
        data: requestBody,
        options: Options(
          headers: _buildHeaders(),
          responseType: ResponseType.stream,
        ),
      );

      if (response.statusCode == 200) {
        // 读取流的第一行验证格式
        final stream = response.data as Stream<List<int>>;
        await for (final chunk in stream.take(1)) {
          final text = utf8.decode(chunk);
          final json = jsonDecode(text) as Map<String, dynamic>;
          
          if (json['code'] == 0 || json['code'] == 20000000) {
            return TtsTestResult(isSuccess: true);
          } else {
            return TtsTestResult(
              isSuccess: false,
              errorMessage: json['message'] ?? 'API 返回错误',
              statusCode: json['code'],
            );
          }
        }
        return TtsTestResult(isSuccess: true);
      } else if (response.statusCode == 401) {
        return TtsTestResult(
          isSuccess: false,
          statusCode: 401,
          errorMessage: '认证失败，请检查 APP ID 和 Access Token 是否正确',
        );
      } else if (response.statusCode == 403) {
        // 读取错误响应体
        String? errorDetail;
        try {
          final stream = response.data as Stream<List<int>>;
          final chunks = await stream.take(1).toList();
          if (chunks.isNotEmpty) {
            final text = utf8.decode(chunks.first);
            final json = jsonDecode(text) as Map<String, dynamic>;
            errorDetail = json['message'] ?? json['error'];
          }
        } catch (_) {}
        
        return TtsTestResult(
          isSuccess: false,
          statusCode: 403,
          errorMessage: errorDetail ?? '认证失败(403)\n\n可能原因：\n'
              '1. APP ID 或 Access Token 错误\n'
              '2. 资源 ID (Resource ID) 不正确\n'
              '3. 账号未开通该服务权限\n\n'
              '请检查设置中的 TTS 配置信息',
        );
      } else if (response.statusCode == 429) {
        return TtsTestResult(
          isSuccess: false,
          statusCode: 429,
          errorMessage: '请求过于频繁，请稍后再试',
        );
      } else {
        return TtsTestResult(
          isSuccess: false,
          statusCode: response.statusCode,
          errorMessage: '服务器错误: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMsg;
      
      // 检测 CORS 错误
      if (kIsWeb && _isCorsError(e)) {
        return TtsTestResult(
          isSuccess: false,
          errorMessage: 'Web 端跨域限制：\n\n'
              '浏览器安全策略阻止了直接调用 TTS API。\n\n'
              '解决方案：\n'
              '1. 使用移动端测试（推荐）\n'
              '2. 配置代理服务器转发请求\n'
              '3. 使用浏览器插件临时禁用 CORS（仅开发测试）',
        );
      }
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '连接超时，请检查网络连接';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '接收数据超时，请稍后重试';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '网络连接失败，请检查网络设置';
      } else {
        errorMsg = '网络错误: ${e.message}';
      }
      
      return TtsTestResult(
        isSuccess: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      return TtsTestResult(
        isSuccess: false,
        errorMessage: '测试失败: $e',
      );
    }
  }

  /// 获取音频缓存目录
  Future<Directory> _getAudioCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(
      path.join(appDir.path, DatabaseConstants.audioCacheDir),
    );
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    return audioDir;
  }

  /// 生成音频文件名
  String _generateAudioFileName(int poemId) {
    return 'poem_$poemId.mp3';
  }

  /// 检查本地缓存是否有效
  Future<String?> _checkLocalCache(int poemId) async {
    if (kIsWeb) return null;

    final poem = await _db.getPoemById(poemId);
    if (poem?.localAudioPath == null) return null;

    final file = File(poem!.localAudioPath!);
    if (await file.exists()) {
      return poem.localAudioPath;
    }

    await _db.updateAudioPath(poemId, null);
    return null;
  }

  /// 流式合成音频
  /// 
  /// 返回音频字节数据
  Future<List<int>> _synthesizeAudio(
    String text, {
    String? voiceType,
    AudioParams? audioParams,
    Function(double)? onProgress,
  }) async {
    final requestBody = _buildRequestBody(
      text,
      voiceType: voiceType,
      audioParams: audioParams,
    );
    
    _currentCancelToken = CancelToken();
    
    final response = await _dio.post(
      TtsConstants.apiUrl,
      data: requestBody,
      options: Options(
        headers: _buildHeaders(),
        responseType: ResponseType.stream,
      ),
      cancelToken: _currentCancelToken,
    );

    if (response.statusCode != 200) {
      throw Exception('API 请求失败: ${response.statusCode}');
    }

    // 解析流式响应
    final audioBytes = <int>[];
    final stream = response.data as Stream<List<int>>;
    int totalBytes = 0;
    
    await for (final chunk in stream) {
      // 检查是否被取消
      if (_currentCancelToken?.isCancelled ?? false) {
        throw Exception('合成已取消');
      }
      
      // 解析 JSON 行
      final text = utf8.decode(chunk);
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
      
      for (final line in lines) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          
          // 检查错误码
          final code = json['code'];
          if (code != 0 && code != 20000000) {
            throw Exception(json['message'] ?? '合成失败: $code');
          }
          
          // 提取音频数据
          final data = json['data'];
          if (data != null && data is String && data.isNotEmpty) {
            final bytes = base64Decode(data);
            audioBytes.addAll(bytes);
            totalBytes += bytes.length;
            
            // 报告进度（估计值）
            if (onProgress != null) {
              // 根据已接收数据估算进度
              final estimatedProgress = (totalBytes / (text.length * 100)).clamp(0.0, 0.95);
              onProgress(estimatedProgress);
            }
          }
          
          // 检查是否完成
          if (code == 20000000) {
            if (onProgress != null) onProgress(1.0);
            break;
          }
        } catch (e) {
          if (e is FormatException) {
            // JSON 解析错误，可能是数据不完整，继续等待
            continue;
          }
          rethrow;
        }
      }
    }
    
    return audioBytes;
  }

  /// 调用火山引擎 TTS API 下载音频
  /// 
  /// 在移动端：下载并保存到本地文件系统
  /// 在 Web 端：直接返回音频数据（通过 data 字段）
  Future<TtsResult> _downloadAudioFromApi(
    Poem poem, {
    String? voiceType,
    AudioParams? audioParams,
    Function(double)? onProgress,
  }) async {
    try {
      final text = '${poem.title}。${poem.author}。${poem.content.replaceAll('\n', '。')}';
      
      // 流式合成音频
      final audioBytes = await _synthesizeAudio(
        text,
        voiceType: voiceType,
        audioParams: audioParams,
        onProgress: onProgress,
      );
      
      if (audioBytes.isEmpty) {
        return TtsResult(
          status: TtsResultStatus.apiError,
          errorMessage: '合成音频数据为空',
        );
      }
      
      // Web 平台：直接返回音频数据，不保存到文件
      if (kIsWeb) {
        return TtsResult(
          status: TtsResultStatus.success,
          audioBytes: audioBytes,
        );
      }
      
      // 移动端：保存到本地文件
      final audioPath = await _saveAudioFile(poem.id, audioBytes);
      
      if (audioPath != null) {
        await _db.updateAudioPath(poem.id, audioPath);
        
        return TtsResult(
          status: TtsResultStatus.success,
          audioPath: audioPath,
        );
      } else {
        return TtsResult(
          status: TtsResultStatus.fileError,
          errorMessage: '保存音频文件失败',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return TtsResult(
          status: TtsResultStatus.cancelled,
          errorMessage: '合成已取消',
        );
      }
      
      // 检测 CORS 错误
      if (kIsWeb && _isCorsError(e)) {
        return TtsResult(
          status: TtsResultStatus.networkError,
          errorMessage: 'Web 端跨域限制：浏览器安全策略阻止了直接调用 TTS API。\n'
              '请使用移动端测试，或配置代理服务器。',
        );
      }
      
      return TtsResult(
        status: TtsResultStatus.networkError,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      return TtsResult(
        status: TtsResultStatus.apiError,
        errorMessage: 'API 错误: $e',
      );
    }
  }

  /// 保存音频文件到本地
  Future<String?> _saveAudioFile(int poemId, List<int> bytes) async {
    try {
      final audioDir = await _getAudioCacheDir();
      final fileName = _generateAudioFileName(poemId);
      final filePath = path.join(audioDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      print('保存音频文件失败: $e');
      return null;
    }
  }

  /// 获取或下载音频
  Future<TtsResult> getOrDownloadAudio(
    Poem poem, {
    String? voiceType,
    AudioParams? audioParams,
    bool forceDownload = false,
    Function(double)? onProgress,
  }) async {
    if (!forceDownload) {
      final cachedPath = await _checkLocalCache(poem.id);
      if (cachedPath != null) {
        return TtsResult(
          status: TtsResultStatus.success,
          audioPath: cachedPath,
        );
      }
    }

    return await _downloadAudioFromApi(
      poem,
      voiceType: voiceType,
      audioParams: audioParams,
      onProgress: onProgress,
    );
  }

  /// 取消当前请求
  void cancelDownload() {
    _currentCancelToken?.cancel('用户取消');
    _currentCancelToken = null;
  }

  /// 清除指定诗词的音频缓存
  Future<bool> clearAudioCache(int poemId) async {
    if (kIsWeb) return false;

    try {
      final poem = await _db.getPoemById(poemId);
      if (poem?.localAudioPath == null) return true;

      final file = File(poem!.localAudioPath!);
      if (await file.exists()) {
        await file.delete();
      }

      await _db.updateAudioPath(poemId, null);
      return true;
    } catch (e) {
      print('清除缓存失败: $e');
      return false;
    }
  }

  /// 清除所有音频缓存
  Future<void> clearAllAudioCache() async {
    if (kIsWeb) return;

    try {
      final audioDir = await _getAudioCacheDir();
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
        await audioDir.create();
      }

      final db = await _db.database;
      await db.update(
        DatabaseConstants.poemsTable,
        {'local_audio_path': null},
      );
    } catch (e) {
      print('清除所有缓存失败: $e');
    }
  }

  /// 获取音频缓存大小（MB）
  Future<double> getCacheSize() async {
    if (kIsWeb) return 0.0;

    try {
      final audioDir = await _getAudioCacheDir();
      if (!await audioDir.exists()) return 0.0;

      int totalSize = 0;
      await for (final file in audioDir.list()) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// 检测是否为 CORS 错误（Web 平台）
  bool _isCorsError(DioException e) {
    if (!kIsWeb) return false;
    
    final errorStr = e.toString().toLowerCase();
    final message = e.message?.toLowerCase() ?? '';
    
    // CORS 错误的常见特征
    return errorStr.contains('cors') ||
           errorStr.contains('cross-origin') ||
           message.contains('xmlhttprequest') ||
           (e.response?.statusCode == 404 && e.requestOptions.method == 'OPTIONS') ||
           (e.type == DioExceptionType.badResponse && e.response == null);
  }
}
