import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/poem.dart';
import '../services/database_helper.dart';
import '../services/tts_service.dart';

/// 播放状态
enum PlaybackState {
  /// 空闲/停止
  idle,
  
  /// 加载中（下载音频）
  loading,
  
  /// 正在播放
  playing,
  
  /// 暂停
  paused,
  
  /// 错误
  error,
}

/// 诗词控制器 - GetX
/// 
/// 管理诗词列表、当前播放状态等
class PoemController extends GetxController {
  static PoemController get to => Get.find();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final TtsService _ttsService = TtsService();
  AudioPlayer? _audioPlayer;

  // ==================== 状态变量 ====================
  
  /// 诗词列表
  final RxList<Poem> poems = <Poem>[].obs;
  
  /// 当前选中的诗词
  final Rx<Poem?> currentPoem = Rx<Poem?>(null);
  
  /// 播放状态
  final Rx<PlaybackState> playbackState = PlaybackState.idle.obs;
  
  /// 下载进度 (0.0 ~ 1.0)
  final RxDouble downloadProgress = 0.0.obs;
  
  /// 错误信息
  final RxString errorMessage = ''.obs;
  
  /// 播放进度（秒）
  final Rx<Duration> position = Duration.zero.obs;
  
  /// 音频总时长
  final Rx<Duration> duration = Duration.zero.obs;
  
  /// 初始化状态
  final RxBool isInitialized = false.obs;
  
  /// 初始化错误
  final RxString initError = ''.obs;

  // ==================== 初始化 ====================

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      // 初始化数据库
      DatabaseHelper.initialize();
      
      // 初始化 TTS 服务
      _ttsService.init();
      
      // 初始化音频播放器（非 Web 平台）
      if (!kIsWeb) {
        _audioPlayer = AudioPlayer();
        _initAudioPlayer();
      }
      
      // 加载诗词数据
      await loadPoems();
      
      isInitialized.value = true;
    } catch (e, stackTrace) {
      initError.value = '初始化失败: $e';
      print('初始化错误: $e');
      print(stackTrace);
    }
  }

  @override
  void onClose() {
    _audioPlayer?.dispose();
    super.onClose();
  }

  /// 初始化音频播放器监听
  void _initAudioPlayer() {
    if (_audioPlayer == null) return;
    
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
        case PlayerState.disposed:
          playbackState.value = PlaybackState.idle;
          position.value = Duration.zero;
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

    // 错误监听
    _audioPlayer!.onPlayerComplete.listen((_) {
      playbackState.value = PlaybackState.idle;
      position.value = Duration.zero;
    });
  }

  // ==================== 数据操作 ====================

  /// 加载所有诗词
  Future<void> loadPoems() async {
    try {
      final list = await _db.getAllPoems();
      poems.value = list;
    } catch (e) {
      errorMessage.value = '加载数据失败: $e';
      print('加载诗词失败: $e');
    }
  }

  /// 搜索诗词
  Future<void> searchPoems(String keyword) async {
    try {
      if (keyword.isEmpty) {
        await loadPoems();
        return;
      }
      final list = await _db.searchPoems(keyword);
      poems.value = list;
    } catch (e) {
      errorMessage.value = '搜索失败: $e';
    }
  }

  /// 选择当前诗词
  void selectPoem(Poem poem) {
    currentPoem.value = poem;
    // 重置播放状态
    playbackState.value = PlaybackState.idle;
    downloadProgress.value = 0.0;
    errorMessage.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  // ==================== 播放控制 ====================

  /// 播放/暂停切换
  Future<void> togglePlay() async {
    final poem = currentPoem.value;
    if (poem == null) return;

    switch (playbackState.value) {
      case PlaybackState.idle:
      case PlaybackState.error:
        await _startPlay(poem);
        break;
      case PlaybackState.loading:
        // 加载中，可以取消
        _ttsService.cancelDownload();
        playbackState.value = PlaybackState.idle;
        break;
      case PlaybackState.playing:
        await pause();
        break;
      case PlaybackState.paused:
        await resume();
        break;
    }
  }

  /// 开始播放（带缓存逻辑）
  Future<void> _startPlay(Poem poem) async {
    playbackState.value = PlaybackState.loading;
    downloadProgress.value = 0.0;
    errorMessage.value = '';

    final result = await _ttsService.getOrDownloadAudio(
      poem,
      onProgress: (progress) {
        downloadProgress.value = progress;
      },
    );

    if (!result.isSuccess) {
      playbackState.value = PlaybackState.error;
      errorMessage.value = result.errorMessage ?? '播放失败';
      return;
    }

    // 播放音频
    try {
      if (kIsWeb) {
        // Web 平台：使用字节数据播放
        await _playAudioOnWeb(result);
      } else {
        // 移动端：使用本地文件播放
        await _playAudioOnMobile(result, poem);
      }
    } catch (e) {
      playbackState.value = PlaybackState.error;
      errorMessage.value = '播放失败: $e';
    }
  }

  /// Web 平台播放音频
  Future<void> _playAudioOnWeb(TtsResult result) async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    }
    
    // Web 端使用字节数据播放
    if (result.audioBytes != null) {
      // audioplayers 支持通过 setSourceBytes 播放
      await _audioPlayer!.setSource(BytesSource(Uint8List.fromList(result.audioBytes!)));
      await _audioPlayer!.resume();
    } else {
      throw Exception('Web 端音频数据为空');
    }
  }

  /// 移动端播放音频
  Future<void> _playAudioOnMobile(TtsResult result, Poem poem) async {
    if (_audioPlayer == null) return;
    
    await _audioPlayer!.setSourceDeviceFile(result.audioPath!);
    await _audioPlayer!.resume();
    
    // 更新当前诗词的缓存状态（如果有变化）
    if (poem.localAudioPath != result.audioPath) {
      final updatedPoem = await _db.getPoemById(poem.id);
      if (updatedPoem != null) {
        currentPoem.value = updatedPoem;
      }
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.resume();
  }

  /// 停止播放
  Future<void> stop() async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.stop();
    playbackState.value = PlaybackState.idle;
    position.value = Duration.zero;
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.seek(position);
  }

  // ==================== 缓存管理 ====================

  /// 清除当前诗词的缓存
  Future<void> clearCurrentCache() async {
    final poem = currentPoem.value;
    if (poem == null) return;

    await stop();
    await _ttsService.clearAudioCache(poem.id);
    
    // 刷新当前诗词数据
    final updatedPoem = await _db.getPoemById(poem.id);
    if (updatedPoem != null) {
      currentPoem.value = updatedPoem;
    }
  }

  /// 获取缓存大小
  Future<double> getCacheSize() async {
    return await _ttsService.getCacheSize();
  }
}
