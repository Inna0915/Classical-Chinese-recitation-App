import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import 'poem_detail_page.dart';

/// 收藏页面
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Scaffold(
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '我的收藏',
          style: TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontFamily: FontConstants.chineseSerif,
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.favoritePoems.isEmpty) {
          return _buildEmptyView();
        }

        return CustomScrollView(
          slivers: [
            // 收藏统计
            SliverToBoxAdapter(
              child: _buildFavoritesHeader(controller),
            ),

            // 收藏列表
            SliverPadding(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final poem = controller.favoritePoems[index];
                    return _FavoritePoemItem(
                      poem: poem,
                      onTap: () {
                        controller.selectPoem(poem);
                        Get.to(() => const PoemDetailPage());
                      },
                      onRemove: () => controller.toggleFavorite(poem.id),
                    );
                  },
                  childCount: controller.favoritePoems.length,
                ),
              ),
            ),

            // 底部留白
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      }),
    );
  }

  /// 空收藏视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: const Color(UIConstants.textSecondaryColor).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在书架中点击收藏按钮添加',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 收藏头部
  Widget _buildFavoritesHeader(PoemController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: UIConstants.defaultPadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(UIConstants.accentColor).withOpacity(0.8),
            const Color(UIConstants.accentColor),
          ],
        ),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '我的收藏',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: FontConstants.chineseSerif,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  '共 ${controller.favoritePoems.length} 首诗词',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏列表项
class _FavoritePoemItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoritePoemItem({
    required this.poem,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('favorite_${poem.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(UIConstants.cardColor),
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          border: Border.all(
            color: const Color(UIConstants.dividerColor),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(UIConstants.accentColor).withOpacity(0.8),
                  const Color(UIConstants.accentColor),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                poem.title.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            poem.title,
            style: const TextStyle(
              color: Color(UIConstants.textPrimaryColor),
              fontFamily: FontConstants.chineseSerif,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '[${poem.dynasty ?? '未知'}] ${poem.author}',
              style: const TextStyle(
                color: Color(UIConstants.textSecondaryColor),
                fontSize: 13,
              ),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Color(UIConstants.accentColor),
            ),
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}
