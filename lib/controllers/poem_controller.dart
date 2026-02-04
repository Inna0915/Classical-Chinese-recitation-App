import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import '../models/tts_result.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'player_controller.dart';

// 导出 TimestampItem 供 UI 使用
export '../models/tts_result.dart' show TimestampItem;
import '../services/database_helper.dart';
import '../services/settings_service.dart';
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

  /// 分组列表
  final RxList<PoemGroup> groups = <PoemGroup>[].obs;

  /// 当前选中的分组ID (-1 表示全部)
  final RxInt selectedGroupId = RxInt(-1);

  /// 收藏列表
  final RxList<Poem> favoritePoems = <Poem>[].obs;

  /// 当前底部导航索引
  final RxInt currentTabIndex = 0.obs;
  
  /// 当前播放的时间戳数据（用于卡拉OK高亮）
  final RxList<TimestampItem> currentTimestamps = <TimestampItem>[].obs;
  
  // ==================== 搜索相关 ====================
  
  /// 搜索关键词
  final RxString searchText = ''.obs;
  
  /// 显示用的诗词列表（已过滤）
  final RxList<Poem> displayPoems = <Poem>[].obs;
  
  /// 所有原始诗词数据
  final RxList<Poem> allPoems = <Poem>[].obs;

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
      
      // 加载分组列表
      await loadGroups();
      
      // 加载收藏列表
      await loadFavoritePoems();
      
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
      allPoems.value = list;
      // 初始化显示列表
      _applyFilter();
    } catch (e) {
      errorMessage.value = '加载数据失败: $e';
      print('加载诗词失败: $e');
    }
  }

  /// 搜索诗词（实时过滤，带 debounce）
  void searchPoems(String keyword) {
    searchText.value = keyword;
    _applyFilter();
  }
  
  /// 应用搜索和分组过滤
  void _applyFilter() {
    var filtered = allPoems.toList();
    
    // 1. 先应用分组过滤
    if (selectedGroupId.value != -1) {
      filtered = filtered.where((p) => p.groupId == selectedGroupId.value).toList();
    }
    
    // 2. 再应用搜索过滤
    final keyword = searchText.value.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((poem) {
        final titleMatch = poem.title.toLowerCase().contains(keyword);
        final authorMatch = poem.author.toLowerCase().contains(keyword);
        final contentMatch = poem.content.toLowerCase().contains(keyword);
        return titleMatch || authorMatch || contentMatch;
      }).toList();
    }
    
    // 3. 按创建时间倒序排序
    filtered.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    
    displayPoems.value = filtered;
  }
  
  /// 获取过滤后的诗词列表
  List<Poem> get filteredPoems {
    // 如果显示列表为空，返回原始列表（兼容旧代码）
    if (displayPoems.isEmpty && allPoems.isNotEmpty) {
      return poems;
    }
    return displayPoems;
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

  /// 加载分组列表
  Future<void> loadGroups() async {
    try {
      final list = await _db.getAllGroups();
      groups.value = list;
    } catch (e) {
      print('加载分组失败: $e');
    }
  }

  /// 选择分组并筛选诗词
  void selectGroup(int? groupId) {
    selectedGroupId.value = groupId ?? -1;
    _applyFilter(); // 应用过滤
  }

  /// 添加新分组
  Future<void> addGroup(String name) async {
    try {
      final newGroup = PoemGroup(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        sortOrder: groups.length,
        createdAt: DateTime.now(),
      );
      await _db.insertGroup(newGroup);
      await loadGroups();
    } catch (e) {
      errorMessage.value = '添加分组失败: $e';
    }
  }

  /// 删除分组
  Future<void> deleteGroup(int groupId) async {
    try {
      await _db.deleteGroup(groupId);
      await loadGroups();
      // 如果删除的是当前选中的分组，重置为全部
      if (selectedGroupId.value == groupId) {
        selectedGroupId.value = -1;
      }
    } catch (e) {
      errorMessage.value = '删除分组失败: $e';
    }
  }
  
  /// 重新排序分组
  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 || oldIndex >= groups.length) return;
      if (newIndex < 0 || newIndex > groups.length) return;
      
      // 调整新索引（如果是在列表中向下移动）
      if (newIndex > oldIndex) {
        newIndex--;
      }
      
      // 本地重新排序
      final group = groups.removeAt(oldIndex);
      groups.insert(newIndex, group);
      
      // 更新数据库
      await _db.updateGroupsSortOrder(groups);
      
      // 刷新列表
      await loadGroups();
    } catch (e) {
      errorMessage.value = '排序分组失败: $e';
    }
  }

  /// 更新分组
  Future<void> updateGroup(PoemGroup group) async {
    try {
      await _db.updateGroup(group);
      await loadGroups();
    } catch (e) {
      errorMessage.value = '更新分组失败: $e';
    }
  }
  
  /// 删除诗词
  Future<void> deletePoem(int poemId) async {
    try {
      // 停止当前播放（如果是同一首）
      if (currentPoem.value?.id == poemId) {
        await stop();
        currentPoem.value = null;
      }
      
      await _db.deletePoem(poemId);
      await loadPoems();
      await loadFavoritePoems();
    } catch (e) {
      errorMessage.value = '删除诗文失败: $e';
    }
  }

  /// 移动诗词到分组
  Future<void> movePoemToGroup(int poemId, int? groupId) async {
    try {
      await _db.updatePoemGroup(poemId, groupId);
      await loadPoems();
      await loadGroups();
      
      // 如果当前诗词是被移动的，也更新它
      if (currentPoem.value?.id == poemId) {
        final updated = await _db.getPoemById(poemId);
        if (updated != null) {
          currentPoem.value = updated;
        }
      }
    } catch (e) {
      errorMessage.value = '移动诗词失败: $e';
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int poemId) async {
    try {
      final newStatus = await _db.toggleFavorite(poemId);
      await loadPoems();
      await loadFavoritePoems();
      
      // 如果当前诗词是被操作的，也更新它
      if (currentPoem.value?.id == poemId) {
        final updated = await _db.getPoemById(poemId);
        if (updated != null) {
          currentPoem.value = updated;
        }
      }
      
      // 收藏状态已切换，不显示弹窗
    } catch (e) {
      errorMessage.value = '切换收藏状态失败: $e';
    }
  }

  /// 加载收藏列表
  Future<void> loadFavoritePoems() async {
    try {
      final list = await _db.getFavoritePoems();
      favoritePoems.value = list;
    } catch (e) {
      print('加载收藏列表失败: $e');
    }
  }

  /// 检查是否已收藏
  bool isFavorite(int poemId) {
    final poem = poems.firstWhereOrNull((p) => p.id == poemId);
    return poem?.isFavorite ?? false;
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
    
    // 委托给 PlayerController
    final playerController = Get.find<PlayerController>();
    debugPrint('[PoemController] playerController.currentPoem: ${playerController.currentPoem?.title}');
    
    // 如果要播放的诗词不在当前播放列表中，清空列表并播放新的
    final isInPlaylist = playerController.isInPlaylist(poem.id!);
    if (!isInPlaylist) {
      // 清空当前播放列表，播放新诗词
      debugPrint('[PoemController] poem not in playlist, clearing and playing ${poem.title}');
      playerController.clearPlaylist();
      await playerController.playGroup([poem], 0);
      return;
    }
    
    // 如果在播放列表中但不是当前播放的，切换到该诗词
    if (playerController.currentPoem?.id != poem.id) {
      final index = playerController.playlist.indexWhere((p) => p.id == poem.id);
      if (index != -1) {
        debugPrint('[PoemController] switching to poem at index $index');
        playerController.currentIndex.value = index;
        await playerController.playGroup(playerController.playlist, index);
        return;
      }
    }
    
    // 当前正在播放的诗词，切换播放/暂停
    debugPrint('[PoemController] toggling play/pause');
    await playerController.togglePlay();
  }
  
  /// 播放分组（供分组页面调用）
  Future<void> playGroup(List<Poem> poems, int initialIndex) async {
    final playerController = Get.find<PlayerController>();
    await playerController.playGroup(poems, initialIndex);
  }

  /// 开始播放（带缓存逻辑）
  Future<void> _startPlay(Poem poem) async {
    playbackState.value = PlaybackState.loading;
    downloadProgress.value = 0.0;
    errorMessage.value = '';

    try {
      final settings = SettingsService.to;
      
      // 同步音色设置
      _ttsService.setVoiceType(settings.voiceType.value);
      
      final audioParams = AudioParams(
        speechRate: settings.speechRate.value,
        loudnessRate: settings.loudnessRate.value,
      );

      // 构建朗读文本：标题 + 作者 + 纯净内容（TTS 只读 cleanContent）
      final poemText = '${poem.title}。${poem.dynasty != null ? '${poem.dynasty}·' : ''}${poem.author}。${poem.cleanContent}';
      
      final result = await _ttsService.synthesizeText(
        text: poemText,
        voiceType: settings.voiceType.value,
        audioParams: audioParams,
        poemId: poem.id,
        onProgress: (progress) {
          downloadProgress.value = progress;
        },
      );

      if (!result.isSuccess) {
        playbackState.value = PlaybackState.error;
        errorMessage.value = result.errorMessage ?? '播放失败';
        return;
      }

      // 保存时间戳数据
      if (result.timestamps != null && result.timestamps!.isNotEmpty) {
        currentTimestamps.value = result.timestamps!;
        print('【Controller】=== 加载时间戳到UI ===');
        print('【Controller】时间戳数量: ${result.timestamps!.length} 条');
        print('【Controller】第一条: char="${result.timestamps!.first.char}", time=${result.timestamps!.first.startTime}ms~${result.timestamps!.first.endTime}ms');
        print('【Controller】最后一条: char="${result.timestamps!.last.char}", time=${result.timestamps!.last.startTime}ms~${result.timestamps!.last.endTime}ms');
        print('【Controller】==============================');
      } else {
        currentTimestamps.clear();
        print('【Controller】无时间戳数据， KaraOK 效果将不生效');
      }

      // 播放音频
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        _initAudioPlayer();
      }
      
      final file = File(result.audioPath!);
      final bytes = await file.readAsBytes();
      await _audioPlayer!.setSource(BytesSource(bytes));
      await _audioPlayer!.resume();
      
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
    print('【播放】移动端播放, audioPlayer=$_audioPlayer, path=${result.audioPath}');
    
    if (_audioPlayer == null) {
      print('【播放】错误: AudioPlayer 为 null');
      throw Exception('播放器未初始化');
    }
    
    if (result.audioPath == null || result.audioPath!.isEmpty) {
      print('【播放】错误: 音频路径为空');
      throw Exception('音频路径为空');
    }
    
    final file = File(result.audioPath!);
    if (!await file.exists()) {
      print('【播放】错误: 音频文件不存在: ${result.audioPath}');
      throw Exception('音频文件不存在');
    }
    
    print('【播放】文件大小: ${await file.length()} bytes');
    
    try {
      await _audioPlayer!.setSourceDeviceFile(result.audioPath!);
      print('【播放】设置音频源成功');
      await _audioPlayer!.resume();
      print('【播放】开始播放');
    } catch (e) {
      print('【播放】播放失败: $e');
      rethrow;
    }
    
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
    currentTimestamps.clear(); // 清除时间戳
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

  // ==================== 分组顺序播放 ====================

  /// 按分组顺序播放 - 使用 PlayerController
  Future<void> playGroupInOrder(List<Poem> poems) async {
    if (poems.isEmpty) {
      AppDialog.info(
        title: '提示',
        message: '该分组没有诗词',
      );
      return;
    }

    // 使用 PlayerController 播放
    final playerController = Get.find<PlayerController>();
    await playerController.playGroup(poems, 0);
    
    // 同时更新当前选中的诗词
    selectPoem(poems[0]);
  }

  /// 从分组中移除诗词
  Future<void> removePoemFromGroup(int poemId) async {
    try {
      final poem = poems.firstWhereOrNull((p) => p.id == poemId);
      if (poem == null) return;
      
      // 更新数据库
      await _db.updatePoemGroup(poemId, null);
      
      // 重新加载数据确保界面刷新
      await loadPoems();
      await loadGroups();
      
      AppDialog.success(
        title: '移出成功',
        message: '已从分组中移除',
      );
    } catch (e) {
      debugPrint('移除分组失败: $e');
      AppDialog.info(
        title: '移除失败',
        message: '移除失败: $e',
      );
    }
  }
}
