import 'package:get/get.dart';
import '../models/poem_new.dart';
import '../models/collection.dart';
import 'database_helper.dart';

/// 诗词服务 - 处理业务逻辑和状态管理
class PoemService extends GetxService {
  final DatabaseHelper _db = DatabaseHelper();

  // 状态
  final RxList<Poem> allPoems = <Poem>[].obs;
  final RxList<Tag> allTags = <Tag>[].obs;
  final RxList<Collection> allCollections = <Collection>[].obs;
  final RxString selectedTag = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, int> stats = <String, int>{}.obs;

  // 当前播放上下文
  final Rx<PlaybackContext> currentContext = PlaybackContext.all().obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// 初始化服务
  Future<void> _initialize() async {
    isLoading.value = true;
    
    try {
      // 检查是否需要初始化数据
      if (await _db.needInitialization()) {
        await _db.initializeBuiltinData();
      }
      
      await refreshAll();
    } catch (e) {
      print('PoemService: 初始化失败 - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新所有数据
  Future<void> refreshAll() async {
    await Future.wait([
      loadPoems(),
      loadTags(),
      loadCollections(),
      loadStats(),
    ]);
  }

  // ==================== 诗词操作 ====================

  /// 加载所有诗词
  Future<void> loadPoems() async {
    allPoems.value = await _db.getAllPoems();
  }

  /// 根据当前筛选条件获取诗词列表
  List<Poem> getFilteredPoems() {
    if (searchQuery.value.isNotEmpty) {
      // 搜索模式
      final query = searchQuery.value.toLowerCase();
      return allPoems.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.author.toLowerCase().contains(query) ||
            p.cleanContent.toLowerCase().contains(query);
      }).toList();
    }

    if (selectedTag.value.isNotEmpty) {
      // 标签筛选模式
      return allPoems.where((p) {
        return p.tags.any((t) => t.name == selectedTag.value);
      }).toList();
    }

    // 默认显示全部
    return allPoems;
  }

  /// 获取诗词详情
  Future<Poem?> getPoem(int id) async {
    return await _db.getPoem(id);
  }

  /// 添加诗词
  Future<void> addPoem(Poem poem, {List<String> tags = const []}) async {
    await _db.insertPoem(poem, tagNames: tags);
    await refreshAll();
  }

  /// 更新诗词
  Future<void> updatePoem(Poem poem, {List<String>? tags}) async {
    await _db.updatePoem(poem, tagNames: tags);
    await refreshAll();
  }

  /// 删除诗词
  Future<void> deletePoem(int id) async {
    await _db.deletePoem(id);
    await refreshAll();
  }

  /// 切换收藏
  Future<void> toggleFavorite(int id) async {
    final poem = allPoems.firstWhereOrNull((p) => p.id == id);
    if (poem != null) {
      final newStatus = !poem.isFavorite;
      await _db.toggleFavorite(id, newStatus);
      
      // 更新本地状态
      final index = allPoems.indexWhere((p) => p.id == id);
      if (index != -1) {
        allPoems[index] = poem.copyWith(isFavorite: newStatus);
        allPoems.refresh();
      }
    }
  }

  /// 检查是否收藏
  bool isFavorite(int id) {
    final poem = allPoems.firstWhereOrNull((p) => p.id == id);
    return poem?.isFavorite ?? false;
  }

  /// 获取收藏列表
  List<Poem> getFavoritePoems() {
    return allPoems.where((p) => p.isFavorite).toList();
  }

  // ==================== 标签操作 ====================

  /// 加载所有标签
  Future<void> loadTags() async {
    allTags.value = await _db.getAllTags();
  }

  /// 选择标签
  void selectTag(String tagName) {
    selectedTag.value = tagName;
  }

  /// 清除标签筛选
  void clearTagFilter() {
    selectedTag.value = '';
  }

  /// 获取标签下的诗词数量
  int getPoemCountByTag(String tagName) {
    final tag = allTags.firstWhereOrNull((t) => t.name == tagName);
    return tag?.poemCount ?? 0;
  }

  // ==================== 搜索 ====================

  /// 设置搜索词
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// 清除搜索
  void clearSearch() {
    searchQuery.value = '';
  }

  // ==================== 小集操作 ====================

  /// 加载所有小集
  Future<void> loadCollections() async {
    allCollections.value = await _db.getAllCollections();
  }

  /// 获取小集详情
  Future<Collection?> getCollection(int id) async {
    return await _db.getCollection(id);
  }

  /// 创建小集
  Future<void> createCollection(String name, {String? description}) async {
    final collection = Collection(
      name: name,
      description: description,
    );
    await _db.insertCollection(collection);
    await loadCollections();
  }

  /// 更新小集
  Future<void> updateCollection(Collection collection) async {
    await _db.updateCollection(collection);
    await loadCollections();
  }

  /// 删除小集
  Future<void> deleteCollection(int id) async {
    await _db.deleteCollection(id);
    await loadCollections();
  }

  /// 添加诗词到小集
  Future<void> addPoemToCollection(int collectionId, int poemId) async {
    await _db.addPoemToCollection(collectionId, poemId);
    await loadCollections();
  }

  /// 从小集移除诗词
  Future<void> removePoemFromCollection(int collectionId, int poemId) async {
    await _db.removePoemFromCollection(collectionId, poemId);
    await loadCollections();
  }

  /// 更新小集内排序
  Future<void> reorderCollection(int collectionId, List<int> poemIds) async {
    await _db.updateCollectionOrder(collectionId, poemIds);
  }

  /// 检查诗词是否在小集中
  Future<bool> isPoemInCollection(int collectionId, int poemId) async {
    final collection = await getCollection(collectionId);
    return collection?.items.any((item) => item.poemId == poemId) ?? false;
  }

  // ==================== 播放上下文 ====================

  /// 设置播放上下文（全部）
  void setAllContext({int? initialPoemId}) {
    currentContext.value = PlaybackContext.all(initialPoemId: initialPoemId);
  }

  /// 设置播放上下文（标签）
  void setTagContext(String tagName, {int? initialPoemId}) {
    currentContext.value = PlaybackContext.tag(tagName, initialPoemId: initialPoemId);
  }

  /// 设置播放上下文（小集）
  void setCollectionContext(int collectionId, {int? initialPoemId}) {
    currentContext.value = PlaybackContext.collection(collectionId, initialPoemId: initialPoemId);
  }

  /// 设置播放上下文（收藏）
  void setFavoriteContext({int? initialPoemId}) {
    currentContext.value = PlaybackContext.favorite(initialPoemId: initialPoemId);
  }

  /// 设置播放上下文（搜索）
  void setSearchContext(String query, {int? initialPoemId}) {
    currentContext.value = PlaybackContext.search(query, initialPoemId: initialPoemId);
  }

  /// 根据当前上下文获取播放队列
  Future<List<Poem>> getPlaybackQueue() async {
    final context = currentContext.value;
    
    switch (context.type) {
      case PlaybackContextType.all:
        return allPoems.toList();
      
      case PlaybackContextType.tag:
        if (context.tagName != null) {
          return allPoems.where((p) {
            return p.tags.any((t) => t.name == context.tagName);
          }).toList();
        }
        return allPoems.toList();
      
      case PlaybackContextType.collection:
        if (context.collectionId != null) {
          final collection = await getCollection(context.collectionId!);
          return collection?.items.map((item) => item.poem!).toList() ?? [];
        }
        return [];
      
      case PlaybackContextType.favorite:
        return getFavoritePoems();
      
      case PlaybackContextType.search:
        if (context.searchQuery != null) {
          final query = context.searchQuery!.toLowerCase();
          return allPoems.where((p) {
            return p.title.toLowerCase().contains(query) ||
                p.author.toLowerCase().contains(query) ||
                p.cleanContent.toLowerCase().contains(query);
          }).toList();
        }
        return allPoems.toList();
    }
  }

  /// 获取当前播放索引
  Future<int> getCurrentIndex() async {
    final queue = await getPlaybackQueue();
    final context = currentContext.value;
    
    if (context.initialPoemId == null) return 0;
    
    return queue.indexWhere((p) => p.id == context.initialPoemId);
  }

  // ==================== 统计 ====================

  /// 加载统计数据
  Future<void> loadStats() async {
    stats.value = await _db.getStats();
  }

  /// 获取统计
  Map<String, int> getStats() {
    return {
      'poems': allPoems.length,
      'favorites': allPoems.where((p) => p.isFavorite).length,
      'tags': allTags.length,
      'collections': allCollections.length,
    };
  }
}
