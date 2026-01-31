import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import 'add_poem_page.dart';
import 'poem_detail_page.dart';
import 'settings_page.dart';

/// 诗词列表页 - 书架式布局
class PoemListPage extends StatelessWidget {
  const PoemListPage({super.key});

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
          '古韵诵读',
          style: TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontFamily: FontConstants.chineseSerif,
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 设置按钮
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(UIConstants.textPrimaryColor),
            ),
            onPressed: () => Get.to(() => const SettingsPage()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.poems.isEmpty) {
          return _buildEmptyView();
        }

        return CustomScrollView(
          slivers: [
            // 书架标题区
            SliverToBoxAdapter(
              child: _buildBookshelfHeader(controller),
            ),
            
            // 诗词网格（书架效果）
            SliverPadding(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final poem = controller.poems[index];
                    return _BookItem(
                      poem: poem,
                      onTap: () {
                        controller.selectPoem(poem);
                        Get.to(() => const PoemDetailPage());
                      },
                    );
                  },
                  childCount: controller.poems.length,
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
      
      // 添加按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddPoemPage()),
        backgroundColor: const Color(UIConstants.accentColor),
        icon: const Icon(Icons.add),
        label: const Text(
          '录入诗词',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
          ),
        ),
      ),
    );
  }

  /// 空数据视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: const Color(UIConstants.textSecondaryColor).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '书架空空如也',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮录入诗词',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 书架头部
  Widget _buildBookshelfHeader(PoemController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: UIConstants.defaultPadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 统计信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我的书架',
                  style: TextStyle(
                    color: const Color(UIConstants.textPrimaryColor),
                    fontFamily: FontConstants.chineseSerif,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                  '共收录 ${controller.poems.length} 首诗词',
                  style: const TextStyle(
                    color: Color(UIConstants.textSecondaryColor),
                    fontSize: 14,
                  ),
                )),
              ],
            ),
          ),
          
          // 搜索按钮
          Container(
            decoration: BoxDecoration(
              color: const Color(UIConstants.accentColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(UIConstants.accentColor),
              ),
              onPressed: () => _showSearchDialog(controller),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog(PoemController controller) {
    final searchController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '搜索诗词',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标题、作者或内容...',
            hintStyle: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.dividerColor),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.accentColor),
              ),
            ),
          ),
          onSubmitted: (value) {
            controller.searchPoems(value);
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.loadPoems();
              Get.back();
            },
            child: const Text(
              '重置',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.searchPoems(searchController.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

/// 书本样式列表项
class _BookItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;

  const _BookItem({
    required this.poem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // 书本封面
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // 书皮背景
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(UIConstants.accentColor).withOpacity(0.8),
                            const Color(UIConstants.accentColor),
                          ],
                        ),
                      ),
                    ),
                    
                    // 装饰纹理
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          border: Border(
                            left: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 内容
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 标题
                          Text(
                            poem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: FontConstants.chineseSerif,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          
                          // 分隔线
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          const SizedBox(height: 12),
                          
                          // 作者
                          Text(
                            '[${poem.dynasty ?? '未知'}] ${poem.author}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // 缓存标记
                    if (poem.localAudioPath != null)
                      Positioned(
                        top: 8,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.headphones,
                            size: 14,
                            color: Color(UIConstants.accentColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 书名（下方）
          Text(
            poem.title,
            style: const TextStyle(
              color: Color(UIConstants.textPrimaryColor),
              fontFamily: FontConstants.chineseSerif,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // 作者
          Text(
            poem.author,
            style: const TextStyle(
              color: Color(UIConstants.textSecondaryColor),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
