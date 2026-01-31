import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';
import '../models/poem.dart';
import 'database_helper.dart';

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

/// TTS 服务类 - 核心业务逻辑
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final Dio _dio = Dio();
  
  /// 当前正在进行的下载请求（用于取消）
  CancelToken? _currentCancelToken;

  /// 初始化 Dio 配置
  void init() {
    _dio.options.connectTimeout = 
        Duration(seconds: TtsConstants.connectTimeout);
    _dio.options.receiveTimeout = 
        Duration(seconds: TtsConstants.receiveTimeout);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${TtsConstants.apiKey}',
    };
    
    // Web 平台：配置额外的浏览器选项
    if (kIsWeb) {
      _dio.options.extra['withCredentials'] = false;
    }
  }

  /// 测试 TTS 连接
  /// 
  /// 发送一个简单的测试请求，验证 API Key 和连接是否正常
  /// 支持 Web 和移动端测试
  Future<TtsTestResult> testConnection() async {

    try {
      // 构造一个简单的测试请求
      final requestBody = {
        'app': {
          'appid': 'test_app_id',
          'token': TtsConstants.apiKey,
          'cluster': 'volcano_tts',
        },
        'user': {
          'uid': 'test_user',
        },
        'audio': {
          'voice_type': TtsConstants.defaultVoiceType,
          'encoding': TtsConstants.audioFormat,
          'sample_rate': TtsConstants.sampleRate,
        },
        'request': {
          'text': '测试',
          'reqid': 'test_${DateTime.now().millisecondsSinceEpoch}',
          'operation': 'query',
        },
      };

      final response = await _dio.post(
        TtsConstants.apiUrl,
        data: requestBody,
        options: Options(
          validateStatus: (status) => true, // 接受所有状态码，自行处理
        ),
      );

      if (response.statusCode == 200) {
        return TtsTestResult(isSuccess: true);
      } else if (response.statusCode == 401) {
        return TtsTestResult(
          isSuccess: false,
          statusCode: 401,
          errorMessage: 'API Key 无效或已过期，请检查设置中的 TTS API Key',
        );
      } else if (response.statusCode == 403) {
        return TtsTestResult(
          isSuccess: false,
          statusCode: 403,
          errorMessage: '没有权限访问该服务，请检查 API Key 是否有 TTS 权限',
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
          errorMessage: '服务器错误: ${response.statusCode} - ${response.data?['message'] ?? '未知错误'}',
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

  /// 调用火山引擎 TTS API 下载音频
  /// 
  /// 在移动端：下载并保存到本地文件系统
  /// 在 Web 端：直接返回音频数据（通过 data 字段）
  Future<TtsResult> _downloadAudioFromApi(
    Poem poem, {
    Function(double)? onProgress,
  }) async {

    try {
      _currentCancelToken = CancelToken();

      final requestBody = {
        'app': {
          'appid': 'YOUR_APP_ID',
          'token': TtsConstants.apiKey,
          'cluster': 'volcano_tts',
        },
        'user': {
          'uid': 'user_${poem.id}',
        },
        'audio': {
          'voice_type': TtsConstants.defaultVoiceType,
          'encoding': TtsConstants.audioFormat,
          'sample_rate': TtsConstants.sampleRate,
        },
        'request': {
          'text': '${poem.title}。${poem.author}。${poem.content.replaceAll('\n', '。')}',
          'reqid': 'req_${poem.id}_${DateTime.now().millisecondsSinceEpoch}',
          'operation': 'query',
        },
      };

      final response = await _dio.post(
        TtsConstants.apiUrl,
        data: requestBody,
        cancelToken: _currentCancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        final audioBytes = response.data as List<int>;
        
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
      } else if (response.statusCode == 401) {
        return TtsResult(
          status: TtsResultStatus.apiError,
          errorMessage: 'API Key 无效，请在设置中配置正确的 TTS API Key',
        );
      } else {
        return TtsResult(
          status: TtsResultStatus.apiError,
          errorMessage: 'API 请求失败: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return TtsResult(
          status: TtsResultStatus.cancelled,
          errorMessage: '下载已取消',
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

    return await _downloadAudioFromApi(poem, onProgress: onProgress);
  }

  /// 取消当前下载
  void cancelDownload() {
    _currentCancelToken?.cancel('用户取消下载');
    _currentCancelToken = null;
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
}
