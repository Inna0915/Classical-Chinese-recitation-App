import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../constants/tts_voices.dart';
import '../models/poem.dart';
import 'database_helper.dart';
import 'settings_service.dart';
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
  /// 当前正在进行的请求（用于取消）
  CancelToken? _currentCancelToken;
  
  /// 调试日志列表（最多保留100条）
  final List<String> _debugLogs = [];
  static const int _maxLogCount = 100;
  
  /// 获取日志内容
  String getLogs() => _debugLogs.join('\n');
  
  /// 获取日志列表
  List<String> getLogList() => List.unmodifiable(_debugLogs);
  
  /// 清空日志
  void clearLogs() => _debugLogs.clear();
  
  /// 添加日志
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    _debugLogs.add('[$timestamp] $message');
    // 限制日志数量
    if (_debugLogs.length > _maxLogCount) {
      _debugLogs.removeAt(0);
    }
    // 同时输出到控制台
    debugPrint('[TTS] $message');
  }

  /// 初始化 Dio 配置
  void init() {
    _dio.options.connectTimeout = 
        Duration(seconds: TtsConstants.connectTimeout);
    _dio.options.receiveTimeout = 
        Duration(seconds: TtsConstants.receiveTimeout);
    // 接受所有状态码，自行处理
    _dio.options.validateStatus = (status) => true;
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
        'audio_params': (audioParams ?? const AudioParams()).toJson(),
      },
    };
  }

  /// 测试 TTS 连接
  /// 
  /// 发送一个简单的测试请求，验证 API 配置和连接是否正常
  /// 发送一个简单的测试请求，验证 API 配置和连接是否正常
  Future<TtsTestResult> testConnection() async {
    try {
      final requestBody = _buildRequestBody('测试');
      final headers = _buildHeaders();
      
      // 清空旧日志并记录新请求
      clearLogs();
      _addLog('========== TTS 测试请求 ==========');
      _addLog('URL: ${TtsConstants.apiUrl}');
      _addLog('Headers:');
      headers.forEach((key, value) {
        // 敏感信息部分隐藏
        if (key.toLowerCase().contains('key') || key.toLowerCase().contains('token')) {
          final masked = value.length > 8 
              ? '${value.substring(0, 8)}****${value.substring(value.length - 4)}'
              : '****';
          _addLog('  $key: $masked');
        } else {
          _addLog('  $key: $value');
        }
      });
      _addLog('Request Body: ${jsonEncode(requestBody)}');
      _addLog('===================================');
      
      final response = await _dio.post(
        TtsConstants.apiUrl,
        data: requestBody,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );

      // ========== 打印响应信息 ==========
      _addLog('========== TTS 测试响应 ==========');
      _addLog('Status Code: ${response.statusCode}');
      _addLog('Response Headers:');
      response.headers.forEach((key, value) {
        _addLog('  $key: $value');
      });

      if (response.statusCode == 200) {
        // 读取流的第一行验证格式 (NDJSON)
        final responseBody = response.data as ResponseBody;
        final stream = responseBody.stream;
        String buffer = '';
        final allResponseLines = <String>[];
        
        await for (final chunk in stream) {
          buffer += utf8.decode(chunk);
          final lines = buffer.split('\n');
          buffer = lines.last; // 保留不完整的行
          
          // 处理完整的行
          for (final line in lines.take(lines.length - 1)) {
            final trimmedLine = line.trim();
            if (trimmedLine.isEmpty) continue;
            
            allResponseLines.add(trimmedLine);
            _addLog('Response Line: $trimmedLine');
            
            try {
              final json = jsonDecode(trimmedLine) as Map<String, dynamic>;
              
              if (json['code'] == 0 || json['code'] == 20000000) {
                _addLog('===================================');
                _addLog('TTS 测试成功');
                return TtsTestResult(isSuccess: true);
              } else {
                _addLog('===================================');
                _addLog('TTS 测试失败: ${json['message']}');
                return TtsTestResult(
                  isSuccess: false,
                  errorMessage: json['message'] ?? 'API 返回错误',
                  statusCode: json['code'],
                );
              }
            } catch (e) {
              if (e is FormatException) continue;
              rethrow;
            }
          }
        }
        
        // 处理缓冲区剩余数据
        if (buffer.trim().isNotEmpty) {
          allResponseLines.add(buffer.trim());
          _addLog('Response Line (final): ${buffer.trim()}');
          try {
            final json = jsonDecode(buffer.trim()) as Map<String, dynamic>;
            if (json['code'] == 0 || json['code'] == 20000000) {
              _addLog('===================================');
              _addLog('TTS 测试成功');
              return TtsTestResult(isSuccess: true);
            } else {
              _addLog('===================================');
              _addLog('TTS 测试失败: ${json['message']}');
              return TtsTestResult(
                isSuccess: false,
                errorMessage: json['message'] ?? 'API 返回错误',
                statusCode: json['code'],
              );
            }
          } catch (_) {}
        }
        
        _addLog('===================================');
        _addLog('TTS 测试成功 (无明确错误码)');
        return TtsTestResult(isSuccess: true);
      } else if (response.statusCode == 401) {
        _addLog('===================================');
        _addLog('TTS 测试失败: 401 认证失败');
        return TtsTestResult(
          isSuccess: false,
          statusCode: 401,
          errorMessage: '认证失败，请检查 APP ID 和 Access Token 是否正确',
          errorMessage: '认证失败，请检查 APP ID 和 Access Token 是否正确',
        );
      } else if (response.statusCode == 403) {
        // 读取错误响应体
        String? errorDetail;
        String? rawResponse;
        try {
          final responseBody = response.data as ResponseBody;
          final chunks = await responseBody.stream.toList();
          if (chunks.isNotEmpty) {
            rawResponse = utf8.decode(chunks.expand((e) => e).toList());
            _addLog('Error Response Body: $rawResponse');
            final json = jsonDecode(rawResponse) as Map<String, dynamic>;
            errorDetail = json['message'] ?? json['error'];
          }
        } catch (_) {}
        
        _addLog('===================================');
        _addLog('TTS 测试失败: 403 禁止访问');
        return TtsTestResult(
          isSuccess: false,
          statusCode: 403,
          errorMessage: errorDetail ?? '认证失败(403)\n\n可能原因：\n'
              '1. APP ID 或 Access Token 错误\n'
              '2. 资源 ID (Resource ID) 不正确\n'
              '3. 账号未开通该服务权限\n\n'
              '请检查设置中的 TTS 配置信息',
          errorMessage: errorDetail ?? '认证失败(403)\n\n可能原因：\n'
              '1. APP ID 或 Access Token 错误\n'
              '2. 资源 ID (Resource ID) 不正确\n'
              '3. 账号未开通该服务权限\n\n'
              '请检查设置中的 TTS 配置信息',
        );
      } else if (response.statusCode == 429) {
        _addLog('===================================');
        _addLog('TTS 测试失败: 429 请求过于频繁');
        return TtsTestResult(
          isSuccess: false,
          statusCode: 429,
          errorMessage: '请求过于频繁，请稍后再试',
        );
      } else {
        _addLog('===================================');
        _addLog('TTS 测试失败: ${response.statusCode}');
        return TtsTestResult(
          isSuccess: false,
          statusCode: response.statusCode,
          errorMessage: '服务器错误: ${response.statusCode}',
          errorMessage: '服务器错误: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMsg;
      
      _addLog('========== TTS 测试异常 ==========');
      _addLog('DioException: ${e.type}');
      _addLog('Message: ${e.message}');
      _addLog('Response: ${e.response}');
      
      // 检测 CORS 错误
      if (kIsWeb && _isCorsError(e)) {
        _addLog('检测到 CORS 错误');
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
      
      _addLog('===================================');
      return TtsTestResult(
        isSuccess: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      debugPrint('========== TTS 测试异常 ==========');
      _addLog('未知异常: $e');
      _addLog('===================================');
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

    // 解析流式响应 (NDJSON 格式)
    final audioBytes = <int>[];
    final responseBody = response.data as ResponseBody;
    final stream = responseBody.stream;
    int totalBytes = 0;
    String buffer = ''; // 用于存储不完整的 JSON 行
    
    await for (final chunk in stream) {
      // 检查是否被取消
      if (_currentCancelToken?.isCancelled ?? false) {
        throw Exception('合成已取消');
      }
      
      // 将字节数据转换为字符串并添加到缓冲区
      buffer += utf8.decode(chunk);
      
      // 按行分割处理 NDJSON
      final lines = buffer.split('\n');
      // 保留最后一行（可能不完整）到缓冲区
      buffer = lines.last;
      
      // 处理完整的行
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
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
    
    // 处理缓冲区中剩余的数据
    if (buffer.trim().isNotEmpty) {
      try {
        final json = jsonDecode(buffer.trim()) as Map<String, dynamic>;
        final code = json['code'];
        if (code != 0 && code != 20000000) {
          throw Exception(json['message'] ?? '合成失败: $code');
        }
        final data = json['data'];
        if (data != null && data is String && data.isNotEmpty) {
          final bytes = base64Decode(data);
          audioBytes.addAll(bytes);
        }
        if (code == 20000000 && onProgress != null) {
          onProgress(1.0);
        }
      } catch (e) {
        // 忽略解析错误
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
    return await _downloadAudioFromApi(
      poem,
      voiceType: voiceType,
      audioParams: audioParams,
      onProgress: onProgress,
    );
  }

  /// 取消当前请求
  /// 取消当前请求
  void cancelDownload() {
    _currentCancelToken?.cancel('用户取消');
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
