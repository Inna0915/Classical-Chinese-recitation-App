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
  
  /// API 错误
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

  TtsResult({
    required this.status,
    this.audioPath,
    this.errorMessage,
  });

  bool get isSuccess => status == TtsResultStatus.success;
}

/// TTS 服务类 - 核心业务逻辑
/// 
/// 处理"检查本地缓存 -> 下载音频（如需要）-> 返回文件路径"的完整流程
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
  /// 
  /// 返回：缓存文件路径（有效）或 null（无效/不存在）
  Future<String?> _checkLocalCache(int poemId) async {
    // Web 平台不支持本地文件缓存
    if (kIsWeb) return null;

    // 从数据库查询缓存路径
    final poem = await _db.getPoemById(poemId);
    if (poem?.localAudioPath == null) return null;

    // 检查文件是否仍然存在
    final file = File(poem!.localAudioPath!);
    if (await file.exists()) {
      return poem.localAudioPath;
    }

    // 文件已被删除，清除数据库中的记录
    await _db.updateAudioPath(poemId, null);
    return null;
  }

  /// 调用火山引擎 TTS API 下载音频
  /// 
  /// 模拟实现，实际使用时需要根据真实 API 文档调整
  Future<TtsResult> _downloadAudioFromApi(
    Poem poem, {
    Function(double)? onProgress,
  }) async {
    // Web 平台暂不支持文件下载缓存
    if (kIsWeb) {
      return TtsResult(
        status: TtsResultStatus.notSupported,
        errorMessage: 'Web 平台暂不支持音频缓存，请使用移动设备体验完整功能',
      );
    }

    try {
      _currentCancelToken = CancelToken();

      // 构造请求参数（根据火山引擎 TTS API 文档调整）
      final requestBody = {
        'app': {
          'appid': 'YOUR_APP_ID',
          'token': 'YOUR_ACCESS_TOKEN',
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

      // 发送请求获取音频数据
      // 注意：此处为模拟实现，真实 API 可能返回 JSON 包含音频 URL 或直接返回音频流
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

      // 处理响应
      // 模拟：假设 API 返回的是 MP3 音频字节流
      // 实际场景中可能需要解析 JSON 获取音频 URL，再下载音频
      if (response.statusCode == 200) {
        final audioBytes = response.data as List<int>;
        
        // 保存到本地
        final audioPath = await _saveAudioFile(poem.id, audioBytes);
        
        if (audioPath != null) {
          // 更新数据库缓存记录
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

  // ==================== 公共 API ====================

  /// 获取或下载音频 - 核心业务方法
  /// 
  /// 流程：
  /// 1. 检查本地缓存 -> 存在直接返回
  /// 2. 本地不存在 -> 调用 TTS API 下载
  /// 3. 下载成功 -> 保存到本地 -> 更新数据库 -> 返回路径
  /// 
  /// 参数：
  /// - [poem]：诗词对象
  /// - [forceDownload]：强制重新下载（即使已有缓存）
  /// - [onProgress]：下载进度回调 (0.0 ~ 1.0)
  Future<TtsResult> getOrDownloadAudio(
    Poem poem, {
    bool forceDownload = false,
    Function(double)? onProgress,
  }) async {
    // 1. 检查本地缓存（非强制下载模式）
    if (!forceDownload) {
      final cachedPath = await _checkLocalCache(poem.id);
      if (cachedPath != null) {
        print('使用本地缓存音频: $cachedPath');
        return TtsResult(
          status: TtsResultStatus.success,
          audioPath: cachedPath,
        );
      }
    }

    // 2. 本地无缓存，从 API 下载
    print('正在下载音频...');
    return await _downloadAudioFromApi(poem, onProgress: onProgress);
  }

  /// 取消当前下载
  void cancelDownload() {
    _currentCancelToken?.cancel('用户取消下载');
    _currentCancelToken = null;
  }

  /// 清除指定诗词的音频缓存
  Future<bool> clearAudioCache(int poemId) async {
    // Web 平台不支持
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
    // Web 平台不支持
    if (kIsWeb) return;

    try {
      final audioDir = await _getAudioCacheDir();
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
        await audioDir.create();
      }

      // 清除数据库中的缓存记录
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
    // Web 平台不支持
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

      return totalSize / (1024 * 1024); // 转换为 MB
    } catch (e) {
      return 0.0;
    }
  }
}
