import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../controllers/poem_controller.dart';
import '../models/poem_new.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'poem_detail_page.dart';

/// 收藏页面 - 与书架页风格统一
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final PoemController controller = PoemController.to;
  final ScrollController _scrollController = ScrollController();
  
  /// 搜索关键词
  final RxString _searchText = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: Column(
        children: [
          // 1. 固定搜索栏
          SearchBarWithController(
            onSearch: (keyword) => _searchText.value = keyword,
            hintText: '搜索收藏...',
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          
          // 2. 收藏列表
          Expanded(
            child: Obx(() {
              if (controller.favoritePoems.isEmpty) {
                return _buildEmptyView(context);
              }
              
              // 过滤收藏列表
              final filteredFavorites = _getFilteredFavorites();
              
              if (filteredFavorites.isEmpty) {
                return _buildNoResultsView(context);
              }

              return ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 80, // 增加底部padding，防止被MiniPlayer遮挡
                ),
                itemCount: filteredFavorites.length,
                itemBuilder: (context, index) {
                  final poem = filteredFavorites[index];
                  return FavoritePoemItem(
                    poem: poem,
                    onTap: () {
                      // 收起键盘
                      FocusScope.of(context).unfocus();
                      controller.selectPoem(poem);
                      Get.to(() => const PoemDetailPage());
                    },
                    onRemove: () {
                      // 收起键盘
                      FocusScope.of(context).unfocus();
                      _showRemoveConfirm(context, poem);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
  
  /// 获取过滤后的收藏列表
  List<Poem> _getFilteredFavorites() {
    final keyword = _searchText.value.trim().toLowerCase();
    if (keyword.isEmpty) {
      return controller.favoritePoems.toList();
    }
    
    return controller.favoritePoems.where((poem) {
      final titleMatch = poem.title.toLowerCase().contains(keyword);
      final authorMatch = poem.author.toLowerCase().contains(keyword);
      final contentMatch = poem.content.toLowerCase().contains(keyword);
      return titleMatch || authorMatch || contentMatch;
    }).toList();
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: context.textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在书架中点击收藏按钮添加',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResultsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: context.textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的收藏',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirm(BuildContext context, Poem poem) {
    AppDialog.confirm(
      title: '取消收藏',
      message: '确定要取消收藏《${poem.title}》吗？',
      confirmText: '取消收藏',
      cancelText: '保留',
      confirmColor: context.primaryColor,
    ).then((confirmed) {
      if (confirmed == true) {
        controller.toggleFavorite(poem.id!);
      }
    });
  }
}

/// 收藏列表项 - 与书架页的 PoemListItem 风格一致
class FavoritePoemItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoritePoemItem({
    super.key,
    required this.poem,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PoemController>();
    
    return Dismissible(
      key: Key('favorite_${poem.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '取消收藏',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
          ],
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poem.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${poem.dynasty ?? ''} · ${poem.author}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 收藏按钮（实心红心）
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
