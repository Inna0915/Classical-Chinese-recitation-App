// import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/poem_new.dart' as new_model;
import '../models/collection.dart';
import '../models/tts_result.dart';
import '../services/poem_service.dart';
// import '../services/settings_service.dart';
import '../services/tts_service.dart';
import 'player_controller.dart';

// 导出 TimestampItem 供 UI 使用
export '../models/tts_result.dart' show TimestampItem;

/// 播放状态
enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  error,
}

/// 诗词控制器 - GetX (v2.0 新架构)
/// 
/// 管理诗词列表、当前播放状态等
class PoemController extends GetxController {
  static PoemController get to => Get.find();

  final PoemService _poemService = Get.find<PoemService>();
  final TtsService _ttsService = TtsService();
  AudioPlayer? _audioPlayer;

  // ==================== 状态变量 ====================
  
  /// 诗词列表
  final RxList<new_model.Poem> poems = <new_model.Poem>[].obs;
  
  /// 当前选中的诗词
  final Rx<new_model.Poem?> currentPoem = Rx<new_model.Poem?>(null);
  
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

  /// 标签列表
  final RxList<new_model.Tag> tags = <new_model.Tag>[].obs;

  /// 当前选中的标签
  final RxString selectedTag = ''.obs;

  /// 收藏列表
  final RxList<new_model.Poem> favoritePoems = <new_model.Poem>[].obs;

  /// 当前底部导航索引
  final RxInt currentTabIndex = 0.obs;
  
  /// 当前播放的时间戳数据（用于卡拉OK高亮）
  final RxList<TimestampItem> currentTimestamps = <TimestampItem>[].obs;
  
  // ==================== 搜索相关 ====================
  
  /// 搜索关键词
  final RxString searchText = ''.obs;
  
  /// 显示用的诗词列表（已过滤）
  final RxList<new_model.Poem> displayPoems = <new_model.Poem>[].obs;
  
  /// 所有原始诗词数据
  final RxList<new_model.Poem> allPoems = <new_model.Poem>[].obs;

  // ==================== 初始化 ====================

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      // 等待 PoemService 初始化完成
      // PoemService 已经在 main.dart 中初始化
      // 等待数据加载
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 初始化 TTS 服务
      _ttsService.init();
      
      // 初始化音频播放器（非 Web 平台）
      if (!kIsWeb) {
        _audioPlayer = AudioPlayer();
        _initAudioPlayer();
      }
      
      // 绑定数据监听
      _bindPoemService();
      
      isInitialized.value = true;
    } catch (e, stackTrace) {
      initError.value = '初始化失败: $e';
      debugPrint('初始化错误: $e');
      debugPrint('$stackTrace');
    }
  }

  @override
  void onClose() {
    _audioPlayer?.dispose();
    super.onClose();
  }

  /// 绑定 PoemService 的数据变化
  void _bindPoemService() {
    // 监听诗词列表变化
    ever(_poemService.allPoems, (list) {
      poems.value = list;
      allPoems.value = list;
      _applyFilter();
    });

    // 监听标签列表变化
    ever(_poemService.allTags, (list) {
      tags.value = list;
    });

    // 初始加载
    poems.value = _poemService.allPoems;
    allPoems.value = _poemService.allPoems;
    tags.value = _poemService.allTags;
    _applyFilter();
    loadFavoritePoems();
  }

  /// 初始化音频播放器监听
  void _initAudioPlayer() {
    if (_audioPlayer == null) return;
    
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

    _audioPlayer!.onPositionChanged.listen((pos) {
      position.value = pos;
    });

    _audioPlayer!.onDurationChanged.listen((dur) {
      duration.value = dur;
    });

    _audioPlayer!.onPlayerComplete.listen((_) {
      playbackState.value = PlaybackState.idle;
      position.value = Duration.zero;
    });
  }

  // ==================== 数据操作 ====================

  /// 加载所有诗词
  Future<void> loadPoems() async {
    try {
      await _poemService.loadPoems();
    } catch (e) {
      errorMessage.value = '加载数据失败: $e';
      debugPrint('加载诗词失败: $e');
    }
  }

  /// 搜索诗词（实时过滤）
  void searchPoems(String keyword) {
    searchText.value = keyword;
    _poemService.setSearchQuery(keyword);
    _applyFilter();
  }
  
  /// 应用搜索和标签过滤
  void _applyFilter() {
    var filtered = _poemService.getFilteredPoems();
    
    // 按创建时间倒序排序
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    displayPoems.value = filtered;
  }
  
  /// 获取过滤后的诗词列表
  List<new_model.Poem> get filteredPoems {
    if (displayPoems.isEmpty && allPoems.isNotEmpty) {
      return poems;
    }
    return displayPoems;
  }

  /// 选择当前诗词
  void selectPoem(new_model.Poem poem) {
    currentPoem.value = poem;
    playbackState.value = PlaybackState.idle;
    downloadProgress.value = 0.0;
    errorMessage.value = '';
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  /// 选择标签并筛选诗词
  void selectTag(String? tagName) {
    selectedTag.value = tagName ?? '';
    _poemService.selectTag(tagName ?? '');
    _applyFilter();
  }

  /// 添加新诗词
  Future<void> addPoem(new_model.Poem poem, {List<String> tags = const []}) async {
    try {
      await _poemService.addPoem(poem, tags: tags);
    } catch (e) {
      errorMessage.value = '添加诗词失败: $e';
    }
  }

  /// 删除诗词
  Future<void> deletePoem(int poemId) async {
    try {
      if (currentPoem.value?.id == poemId) {
        await stop();
        currentPoem.value = null;
      }
      
      await _poemService.deletePoem(poemId);
      await loadFavoritePoems();
    } catch (e) {
      errorMessage.value = '删除诗文失败: $e';
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int poemId) async {
    try {
      await _poemService.toggleFavorite(poemId);
      await loadFavoritePoems();
      
      // 更新当前诗词
      if (currentPoem.value?.id == poemId) {
        final updated = await _poemService.getPoem(poemId);
        if (updated != null) {
          currentPoem.value = updated;
        }
      }
    } catch (e) {
      errorMessage.value = '切换收藏状态失败: $e';
    }
  }

  /// 加载收藏列表
  Future<void> loadFavoritePoems() async {
    try {
      favoritePoems.value = _poemService.getFavoritePoems();
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
    }
  }

  /// 检查是否已收藏
  bool isFavorite(int poemId) {
    return _poemService.isFavorite(poemId);
  }

  // ==================== 播放控制 ====================

  /// 播放/暂停切换
  Future<void> togglePlay() async {
    debugPrint('[PoemController] togglePlay called');
    final poem = currentPoem.value;
    if (poem == null) {
      debugPrint('[PoemController] no poem selected');
      errorMessage.value = '错误: 未选择诗词';
      return;
    }
    
    final playerController = Get.find<PlayerController>();
    debugPrint('[PoemController] playerController.currentPoem: ${playerController.currentPoem?.title}');
    
    final isInPlaylist = playerController.isInPlaylist(poem.id!);
    if (!isInPlaylist) {
      debugPrint('[PoemController] poem not in playlist, clearing and playing ${poem.title}');
      playerController.clearPlaylist();
      await playerController.playPoemList([poem], 0);
      return;
    }
    
    if (playerController.currentPoem?.id != poem.id) {
      final index = playerController.playlist.indexWhere((p) => p.id == poem.id);
      if (index != -1) {
        debugPrint('[PoemController] switching to poem at index $index');
        playerController.currentIndex.value = index;
        await playerController.playPoemList(playerController.playlist as List<new_model.Poem>, index);
        return;
      }
    }
    
    debugPrint('[PoemController] toggling play/pause');
    await playerController.togglePlay();
  }
  
  /// 播放诗词列表
  Future<void> playPoemList(List<new_model.Poem> poems, int initialIndex) async {
    final playerController = Get.find<PlayerController>();
    await playerController.playPoemList(poems, initialIndex);
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
    currentTimestamps.clear();
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
    await _ttsService.clearAudioCache(poem.id!);
    
    final updated = await _poemService.getPoem(poem.id!);
    if (updated != null) {
      currentPoem.value = updated;
    }
  }

  /// 获取缓存大小
  Future<double> getCacheSize() async {
    return await _ttsService.getCacheSize();
  }

  // ==================== 小集管理 ====================

  /// 获取所有小集
  List<Collection> get collections => _poemService.allCollections;

  /// 创建小集
  Future<void> createCollection(String name, {String? description}) async {
    try {
      await _poemService.createCollection(name, description: description);
    } catch (e) {
      errorMessage.value = '创建小集失败: $e';
    }
  }

  /// 删除小集
  Future<void> deleteCollection(int collectionId) async {
    try {
      await _poemService.deleteCollection(collectionId);
    } catch (e) {
      errorMessage.value = '删除小集失败: $e';
    }
  }

  /// 添加诗词到小集
  Future<void> addPoemToCollection(int collectionId, int poemId) async {
    try {
      await _poemService.addPoemToCollection(collectionId, poemId);
    } catch (e) {
      errorMessage.value = '添加到小集失败: $e';
    }
  }

  /// 从小集移除诗词
  Future<void> removePoemFromCollection(int collectionId, int poemId) async {
    try {
      await _poemService.removePoemFromCollection(collectionId, poemId);
    } catch (e) {
      errorMessage.value = '从小集移除失败: $e';
    }
  }

  /// 播放小集
  Future<void> playCollection(int collectionId, {int initialIndex = 0}) async {
    try {
      final collection = await _poemService.getCollection(collectionId);
      if (collection == null || collection.items.isEmpty) {
        errorMessage.value = '小集为空';
        return;
      }

      final poems = collection.items.map((item) => item.poem!).toList();
      final playerController = Get.find<PlayerController>();
      await playerController.playPoemList(poems, initialIndex);
      
      if (poems.isNotEmpty) {
        selectPoem(poems[0]);
      }
    } catch (e) {
      errorMessage.value = '播放小集失败: $e';
    }
  }
}
