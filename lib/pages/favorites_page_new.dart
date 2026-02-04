import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../services/poem_service.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'poem_detail_page_new.dart';

/// 收藏页 - 新架构版本
class FavoritesPageNew extends StatefulWidget {
  const FavoritesPageNew({super.key});

  @override
  State<FavoritesPageNew> createState() => _FavoritesPageNewState();
}

class _FavoritesPageNewState extends State<FavoritesPageNew> {
  final PoemService _poemService = Get.find<PoemService>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Poem> get _filteredFavorites {
    final favorites = _poemService.getFavoritePoems();
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) return favorites;
    
    return favorites.where((p) {
      return p.title.toLowerCase().contains(query) ||
          p.author.toLowerCase().contains(query) ||
          p.cleanContent.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('我的收藏'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(context),
          
          // 收藏列表
          Expanded(
            child: Obx(() {
              final favorites = _filteredFavorites;
              
              if (_poemService.getFavoritePoems().isEmpty) {
                return _buildEmptyView(context);
              }
              
              if (favorites.isEmpty) {
                return _buildNoResultsView(context);
              }

              return ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final poem = favorites[index];
                  return _buildPoemItem(context, poem);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          hintText: '搜索收藏...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withAlpha(153),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.textSecondaryColor,
            size: 20,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: context.textSecondaryColor, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: context.textSecondaryColor.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏',
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在书架中点击收藏按钮添加',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor.withAlpha(153),
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
            color: context.textSecondaryColor.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的收藏',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoemItem(BuildContext context, Poem poem) {
    return Dismissible(
      key: Key('favorite_${poem.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.errorColor,
          borderRadius: BorderRadius.circular(12),
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
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await AppDialog.confirm(
          title: '取消收藏',
          message: '确定要取消收藏《${poem.title}》吗？',
          confirmText: '取消收藏',
          cancelText: '保留',
          confirmColor: context.errorColor,
        );
      },
      onDismissed: (_) => _poemService.toggleFavorite(poem.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: context.cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _onPoemTap(poem),
          borderRadius: BorderRadius.circular(12),
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
                        poem.author,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      if (poem.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: poem.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, 
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 10,
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
                // 收藏按钮（实心红心）
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  onPressed: () => _showRemoveConfirm(poem),
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

  void _showRemoveConfirm(Poem poem) {
    AppDialog.confirm(
      title: '取消收藏',
      message: '确定要取消收藏《${poem.title}》吗？',
      confirmText: '取消收藏',
      cancelText: '保留',
      confirmColor: context.errorColor,
    ).then((confirmed) {
      if (confirmed == true) {
        _poemService.toggleFavorite(poem.id!);
      }
    });
  }

  void _onPoemTap(Poem poem) {
    _poemService.setFavoriteContext(initialPoemId: poem.id);
    Get.to(() => PoemDetailPageNew(poemId: poem.id!));
  }
}
