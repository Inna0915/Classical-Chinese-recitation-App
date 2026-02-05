import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/player_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../services/poem_service.dart';
import 'add_poem_page.dart';
import 'poem_detail_page_new.dart';

/// 书架页 - Cherry Studio风格 (标签+搜索)
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  final PoemService _poemService = Get.find<PoemService>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 多选模式
  final RxBool _isMultiSelectMode = false.obs;
  final RxSet<int> _selectedPoemIds = <int>{}.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _poemService.setSearchQuery(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    _poemService.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _isMultiSelectMode.value ? _buildMultiSelectAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // 搜索栏 (Cherry Studio风格)
          if (!_isMultiSelectMode.value) _buildSearchBar(context),
          
          // 标签筛选栏
          if (!_isMultiSelectMode.value) _buildTagFilter(context),
          
          // 诗词列表
          Expanded(
            child: Obx(() {
              if (_poemService.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final poems = _poemService.getFilteredPoems();
              
              if (poems.isEmpty) {
                return _buildEmptyView(context);
              }

              return ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: poems.length,
                itemBuilder: (context, index) {
                  final poem = poems[index];
                  final isSelected = _selectedPoemIds.contains(poem.id);
                  return PoemCard(
                    poem: poem,
                    isMultiSelectMode: _isMultiSelectMode.value,
                    isSelected: isSelected,
                    onTap: () => _isMultiSelectMode.value 
                        ? _toggleSelection(poem.id!)
                        : _onPoemTap(poem),
                    onLongPress: () {
                      if (!_isMultiSelectMode.value) {
                        _isMultiSelectMode.value = true;
                        _selectedPoemIds.add(poem.id!);
                      }
                    },
                    onFavorite: () => _poemService.toggleFavorite(poem.id!),
                    onAddToCollection: () => _showAddToCollectionSheet(context, poem),
                    onAddToPlaylist: () => _addToPlaylist(poem),
                  );
                },
              );
            }),
          ),
          
          // 多选模式下的底部操作栏
          if (_isMultiSelectMode.value) _buildMultiSelectBottomBar(),
        ],
      ),
      floatingActionButton: !_isMultiSelectMode.value ? FloatingActionButton.small(
        onPressed: () => _showAddPoemPage(),
        backgroundColor: context.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    ));
  }
  
  /// 普通模式 AppBar（透明背景，只用于处理状态栏）
  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: context.backgroundColor,
      elevation: 0,
      toolbarHeight: 0, // 隐藏 AppBar 内容，只保留状态栏处理
    );
  }
  
  /// 多选模式的 AppBar
  AppBar _buildMultiSelectAppBar() {
    return AppBar(
      title: Obx(() => Text('已选择 ${_selectedPoemIds.length} 项')),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          _isMultiSelectMode.value = false;
          _selectedPoemIds.clear();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            final poems = _poemService.getFilteredPoems();
            if (_selectedPoemIds.length == poems.length) {
              _selectedPoemIds.clear();
            } else {
              _selectedPoemIds.addAll(poems.map((p) => p.id!));
            }
          },
          child: Obx(() {
            final poems = _poemService.getFilteredPoems();
            final isAllSelected = _selectedPoemIds.length == poems.length && poems.isNotEmpty;
            return Text(
              isAllSelected ? '取消全选' : '全选',
              style: const TextStyle(color: Colors.white),
            );
          }),
        ),
      ],
    );
  }
  
  /// 多选模式的底部操作栏
  Widget _buildMultiSelectBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomBarItem(
              icon: Icons.playlist_add,
              label: '添加到小集',
              onTap: () => _showBatchAddToCollectionSheet(),
            ),
            _buildBottomBarItem(
              icon: Icons.queue_music,
              label: '添加到播放',
              onTap: () => _batchAddToPlaylist(),
            ),
            _buildBottomBarItem(
              icon: Icons.favorite,
              label: '批量收藏',
              onTap: () => _batchToggleFavorite(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 切换选择状态
  void _toggleSelection(int poemId) {
    if (_selectedPoemIds.contains(poemId)) {
      _selectedPoemIds.remove(poemId);
      if (_selectedPoemIds.isEmpty) {
        _isMultiSelectMode.value = false;
      }
    } else {
      _selectedPoemIds.add(poemId);
    }
  }
  
  /// 添加到播放列表
  void _addToPlaylist(Poem poem) {
    final playerController = Get.find<PlayerController>();
    playerController.addToPlaylist(poem);
    Get.snackbar(
      '已添加到播放列表',
      '《${poem.title}》已加入待播',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  /// 批量添加到播放列表
  void _batchAddToPlaylist() {
    final playerController = Get.find<PlayerController>();
    final poems = _poemService.allPoems
        .where((p) => _selectedPoemIds.contains(p.id))
        .toList();
    for (final poem in poems) {
      playerController.addToPlaylist(poem);
    }
    Get.snackbar(
      '批量添加完成',
      '已将 ${poems.length} 首诗词加入播放列表',
      snackPosition: SnackPosition.BOTTOM,
    );
    _isMultiSelectMode.value = false;
    _selectedPoemIds.clear();
  }
  
  /// 批量收藏
  void _batchToggleFavorite() {
    for (final id in _selectedPoemIds) {
      _poemService.toggleFavorite(id);
    }
    Get.snackbar(
      '批量操作完成',
      '已处理 ${_selectedPoemIds.length} 首诗词',
      snackPosition: SnackPosition.BOTTOM,
    );
    _isMultiSelectMode.value = false;
    _selectedPoemIds.clear();
  }
  
  /// 批量添加到小集
  void _showBatchAddToCollectionSheet() {
    final collections = _poemService.allCollections;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '批量添加到小集 (${_selectedPoemIds.length}首)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (collections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '还没有小集',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return ListTile(
                      leading: Icon(Icons.folder_special, color: context.primaryColor),
                      title: Text(
                        collection.name,
                        style: TextStyle(color: context.textPrimaryColor),
                      ),
                      subtitle: Text(
                        '${collection.poemCount} 首诗词',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                      ),
                      onTap: () async {
                        for (final poemId in _selectedPoemIds) {
                          await _poemService.addPoemToCollection(collection.id!, poemId);
                        }
                        Get.back();
                        Get.snackbar(
                          '添加成功',
                          '已将 ${_selectedPoemIds.length} 首诗词添加到《${collection.name}》',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        _isMultiSelectMode.value = false;
                        _selectedPoemIds.clear();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showAddPoemPage() {
    Get.to(() => const AddPoemPage())?.then((_) {
      // 返回后刷新数据
      _poemService.refreshAll();
    });
  }

  /// 搜索栏 (Cherry Studio风格: 灰底圆角)
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: context.isAppDarkMode 
            ? const Color(0xFF2C2C2C) 
            : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: context.textPrimaryColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: '搜索诗词、作者...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withAlpha(153),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.textSecondaryColor,
            size: 20,
          ),
          suffixIcon: Obx(() {
            if (_poemService.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(Icons.clear, color: context.textSecondaryColor, size: 18),
              onPressed: _clearSearch,
            );
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// 标签筛选栏
  Widget _buildTagFilter(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(() {
        final tags = _poemService.allTags;
        final selectedTag = _poemService.selectedTag.value;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tags.length + 2, // +1 for "全部", +1 for "管理"
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              // "全部" 标签
              final isSelected = selectedTag.isEmpty && 
                                 _poemService.searchQuery.value.isEmpty;
              return _buildTagChip(
                context,
                label: '全部',
                isSelected: isSelected,
                onTap: () {
                  _poemService.clearTagFilter();
                  _clearSearch();
                },
              );
            }

            if (index == tags.length + 1) {
              // "管理" 按钮
              return _buildTagChip(
                context,
                label: '+ 管理',
                isSelected: false,
                onTap: () => _showTagManager(context),
              );
            }

            final tag = tags[index - 1];
            final isSelected = tag.name == selectedTag;
            
            return _buildTagChip(
              context,
              label: '${tag.name} (${tag.poemCount})',
              isSelected: isSelected,
              onTap: () => _poemService.selectTag(tag.name),
            );
          },
        );
      }),
    );
  }

  /// 显示标签管理器
  void _showTagManager(BuildContext context) {
    Get.bottomSheet(
      const TagManagerSheet(),
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  /// 标签Chip
  Widget _buildTagChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? context.primaryColor : context.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? null 
                  : Border.all(color: context.dividerColor),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : context.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: context.textSecondaryColor.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无诗词',
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _onPoemTap(Poem poem) {
    // 设置播放上下文
    if (_poemService.selectedTag.value.isNotEmpty) {
      _poemService.setTagContext(
        _poemService.selectedTag.value,
        initialPoemId: poem.id,
      );
    } else if (_poemService.searchQuery.value.isNotEmpty) {
      _poemService.setSearchContext(
        _poemService.searchQuery.value,
        initialPoemId: poem.id,
      );
    } else {
      _poemService.setAllContext(initialPoemId: poem.id);
    }
    
    Get.to(() => PoemDetailPageNew(poemId: poem.id!));
  }

  /// 显示添加到小集 BottomSheet
  void _showAddToCollectionSheet(BuildContext context, Poem poem) {
    final collections = _poemService.allCollections;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '添加到小集',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      _showCreateCollectionDialog(context);
                    },
                    icon: Icon(Icons.add, size: 18, color: context.primaryColor),
                    label: Text('新建小集', style: TextStyle(color: context.primaryColor)),
                  ),
                ],
              ),
            ),
            if (collections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '还没有小集，点击右上角创建',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return ListTile(
                      leading: Icon(Icons.folder_special, color: context.primaryColor),
                      title: Text(
                        collection.name,
                        style: TextStyle(color: context.textPrimaryColor),
                      ),
                      subtitle: Text(
                        '${collection.poemCount} 首诗词',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                      ),
                      onTap: () async {
                        await _poemService.addPoemToCollection(collection.id!, poem.id!);
                        Get.back();
                        Get.snackbar(
                          '添加成功',
                          '《${poem.title}》已添加到《${collection.name}》',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示创建小集对话框
  void _showCreateCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('创建小集', style: TextStyle(color: context.textPrimaryColor)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '小集名称',
            hintText: '请输入小集名称',
          ),
          style: TextStyle(color: context.textPrimaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _poemService.createCollection(nameController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑诗词标签面板
  void _showEditPoemTagsSheet(BuildContext context, Poem poem) {
    final selectedTagIds = <int>{};
    // 初始化已选标签
    for (final tag in poem.tags) {
      if (tag.id != null) {
        selectedTagIds.add(tag.id!);
      }
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动条
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '编辑标签：${poem.title}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showTagManager(context),
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('管理'),
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(height: 1, color: context.dividerColor),
                  
                  // 标签选择区域
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Obx(() {
                      final allTags = _poemService.allTags;
                      
                      if (allTags.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '暂无标签，请先创建标签',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allTags.map((tag) {
                            final isSelected = selectedTagIds.contains(tag.id);
                            return FilterChip(
                              selected: isSelected,
                              label: Text(tag.name),
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : context.textPrimaryColor,
                                fontSize: 14,
                              ),
                              selectedColor: context.primaryColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: context.backgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected 
                                      ? context.primaryColor 
                                      : context.dividerColor,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTagIds.add(tag.id!);
                                  } else {
                                    selectedTagIds.remove(tag.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ),
                  
                  // 底部按钮
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: context.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _poemService.setPoemTags(
                                poem.id!, 
                                selectedTagIds.toList(),
                              );
                              Get.back();
                              Get.snackbar(
                                '标签已更新',
                                '《${poem.title}》的标签已保存',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('保存'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 诗词卡片 - 新中式极简风格
class PoemCard extends StatelessWidget {
  final Poem poem;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback? onAddToCollection;
  final VoidCallback? onAddToPlaylist;

  const PoemCard({
    super.key,
    required this.poem,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    required this.onFavorite,
    this.onAddToCollection,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? context.primaryColor.withAlpha(26)
            : context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: context.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isAppDarkMode ? 26 : 13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 多选模式下的复选框
                  if (isMultiSelectMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? context.primaryColor : context.dividerColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      poem.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  // 非多选模式下的操作按钮
                  if (!isMultiSelectMode) ...[
                    // 添加到播放列表按钮
                    if (onAddToPlaylist != null)
                      IconButton(
                        icon: Icon(
                          Icons.queue_music,
                          color: context.textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: onAddToPlaylist,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                    // 添加到小集按钮
                    if (onAddToCollection != null)
                      IconButton(
                        icon: Icon(
                          Icons.playlist_add,
                          color: context.textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: onAddToCollection,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                    // 收藏按钮
                    IconButton(
                      icon: Icon(
                        poem.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: poem.isFavorite 
                            ? context.primaryColor 
                            : context.textSecondaryColor,
                        size: 20,
                      ),
                      onPressed: onFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 6),
              
              // 作者
              Text(
                poem.author,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 内容预览
              Text(
                poem.cleanContent.split('\n').first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textPrimaryColor.withAlpha(204),
                  height: 1.5,
                ),
              ),
              
              // 标签
              ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // 获取 BookshelfPage 的状态并调用编辑标签方法
                    final bookshelfState = context.findAncestorStateOfType<_BookshelfPageState>();
                    bookshelfState?._showEditPoemTagsSheet(context, poem);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: poem.tags.isEmpty
                              ? Text(
                                  '+ 添加标签',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondaryColor,
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ...poem.tags.take(3).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.primaryColor.withAlpha(26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag.name,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.primaryColor,
                                          ),
                                        ),
                                      );
                                    }),
                                    if (poem.tags.length > 3)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.backgroundColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '+${poem.tags.length - 3}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 14,
                          color: context.textSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签管理底部面板
class TagManagerSheet extends StatefulWidget {
  const TagManagerSheet({super.key});

  @override
  State<TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<TagManagerSheet> {
  final PoemService _poemService = Get.find<PoemService>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              // 拖动条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '管理标签',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCreateTagDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('新建'),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: context.dividerColor),
              
              // 标签列表
              Expanded(
                child: Obx(() {
                  final tags = _poemService.allTags;
                  
                  if (tags.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无标签',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              tag.name.isNotEmpty ? tag.name[0] : '#',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          tag.name,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${tag.poemCount} 首诗词',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: context.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: () => _showEditTagDialog(tag),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: context.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: () => _showDeleteTagConfirm(tag),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              
              // 底部关闭按钮
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: context.dividerColor),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.backgroundColor,
                    foregroundColor: context.textPrimaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示创建标签对话框
  void _showCreateTagDialog() {
    _nameController.clear();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          '新建标签',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '标签名称',
            hintText: '请输入标签名称',
          ),
          style: TextStyle(color: context.textPrimaryColor),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                await _poemService.createTag(_nameController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑标签对话框
  void _showEditTagDialog(Tag tag) {
    _nameController.text = tag.name;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          '编辑标签',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '标签名称',
            hintText: '请输入标签名称',
          ),
          style: TextStyle(color: context.textPrimaryColor),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                await _poemService.updateTag(tag.id!, _nameController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除标签确认对话框
  void _showDeleteTagConfirm(Tag tag) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          '删除标签',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: Text(
          '确定要删除标签"${tag.name}"吗？\n关联的诗词将自动取消该标签。',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _poemService.deleteTag(tag.id!);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
