import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../services/poem_service.dart';
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
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 搜索栏 (Cherry Studio风格)
            _buildSearchBar(context),
            
            // 标签筛选栏
            _buildTagFilter(context),
            
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
                    return PoemCard(
                      poem: poem,
                      onTap: () => _onPoemTap(poem),
                      onFavorite: () => _poemService.toggleFavorite(poem.id!),
                      onAddToCollection: () => _showAddToCollectionSheet(context, poem),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
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
          itemCount: tags.length + 1, // +1 for "全部"
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
}

/// 诗词卡片 - 新中式极简风格
class PoemCard extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onAddToCollection;

  const PoemCard({
    super.key,
    required this.poem,
    required this.onTap,
    required this.onFavorite,
    this.onAddToCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
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
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
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
              if (poem.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: poem.tags.take(3).map((tag) {
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
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
