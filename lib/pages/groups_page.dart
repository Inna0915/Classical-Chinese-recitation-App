import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../models/poem_group.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'poem_detail_page.dart';
import 'group_detail_page.dart';
import 'add_poem_page.dart';

/// 分组页面 - 独立的分组浏览界面
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final PoemController controller = PoemController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('分组浏览'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(Icons.search, color: context.primaryColor),
            onPressed: () => _showSearchDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.groups.isEmpty) {
          return _buildEmptyView(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: UIConstants.defaultPadding,
            right: UIConstants.defaultPadding,
            top: UIConstants.defaultPadding,
            bottom: 80, // 增加底部padding，防止被MiniPlayer遮挡
          ),
          itemCount: controller.groups.length,
          itemBuilder: (context, index) {
            final group = controller.groups[index];
            final groupPoems = controller.poems
                .where((p) => p.groupId == group.id)
                .toList()
              ..sort((a, b) {
                final aTime = a.createdAt ?? DateTime(2000);
                final bTime = b.createdAt ?? DateTime(2000);
                return bTime.compareTo(aTime);
              });
            
            return _GroupCard(
              group: group,
              poems: groupPoems,
              onTap: () => _showGroupDetail(group, groupPoems),
            );
          },
        );
      }),

      // 添加按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddPoemPage()),
        backgroundColor: context.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('录入诗词'),
      ),
    );
  }

  /// 空数据视图
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 80,
            color: context.textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无分组',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在书架页面创建分组并添加诗词',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示分组详情
  void _showGroupDetail(PoemGroup group, List<Poem> poems) {
    Get.to(() => GroupDetailPage(group: group));
  }

  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context, PoemController controller) {
    final searchController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Text('搜索诗词', style: TextStyle(color: context.textPrimaryColor)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: '输入标题、作者或内容...',
            hintStyle: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.primaryColor),
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
            child: Text('重置', style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.searchPoems(searchController.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

/// 分组卡片
class _GroupCard extends StatelessWidget {
  final PoemGroup group;
  final List<Poem> poems;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.poems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 分组标题
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder,
                        color: context.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '共 ${poems.length} 首诗词',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.textSecondaryColor,
                      size: 16,
                    ),
                  ],
                ),
                
                // 预览部分诗词
                if (poems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: context.dividerColor),
                  const SizedBox(height: 8),
                  ...poems.take(3).map((poem) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 14,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            poem.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (poems.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '还有 ${poems.length - 3} 首...',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 分组详情页
class GroupDetailPage extends StatelessWidget {
  final PoemGroup group;

  const GroupDetailPage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          // 顺序播放按钮
          IconButton(
            icon: Icon(Icons.play_circle_outline, color: context.primaryColor),
            tooltip: '顺序播放',
            onPressed: () {
              final poems = _getGroupPoems(controller);
              controller.playGroupInOrder(poems);
            },
          ),
        ],
      ),
      body: Obx(() {
        final poems = _getGroupPoems(controller);
        
        if (poems.isEmpty) {
          return Center(
            child: Text(
              '该分组暂无诗词',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          itemCount: poems.length,
          itemBuilder: (context, index) {
            final poem = poems[index];
            return _GroupPoemItem(
              poem: poem,
              index: index,
              onTap: () {
                controller.selectPoem(poem);
                Get.to(() => const PoemDetailPage());
              },
              onRemove: () => _showRemoveConfirm(context, controller, poem),
            );
          },
        );
      }),
    );
  }
  
  List<Poem> _getGroupPoems(PoemController controller) {
    return controller.poems
        .where((p) => p.groupId == group.id)
        .toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
  }
  
  void _showRemoveConfirm(BuildContext context, PoemController controller, Poem poem) {
    AppDialog.confirm(
      title: '移出分组',
      message: '确定将《${poem.title}》移出当前分组吗？',
      confirmText: '移出',
      cancelText: '取消',
      confirmColor: Colors.orange,
    ).then((confirmed) {
      if (confirmed == true) {
        controller.removePoemFromGroup(poem.id!);
      }
    });
  }
}

/// 分组诗词项
class _GroupPoemItem extends StatelessWidget {
  final Poem poem;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _GroupPoemItem({
    required this.poem,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poem.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: context.errorColor,
                    size: 20,
                  ),
                  tooltip: '移出分组',
                  onPressed: onRemove,
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
