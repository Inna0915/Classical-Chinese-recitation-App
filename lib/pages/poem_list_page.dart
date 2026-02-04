import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../controllers/poem_controller.dart';
import '../models/poem_new.dart';
import '../models/poem_group.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'add_poem_page.dart';
import 'poem_detail_page.dart';

/// 诗词列表页 - WeChat-like Minimalism with Fixed Search Bar
class PoemListPage extends StatefulWidget {
  const PoemListPage({super.key});

  @override
  State<PoemListPage> createState() => _PoemListPageState();
}

class _PoemListPageState extends State<PoemListPage> {
  final PoemController controller = PoemController.to;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('古韵诵读'),
      ),
      body: Column(
        children: [
          // 1. 固定搜索栏
          SearchBarWithController(
            onSearch: (keyword) => controller.searchPoems(keyword),
            hintText: '搜索诗词...',
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          
          // 2. 分组选择器
          _buildGroupSelector(context, controller),
          
          // 3. 诗词列表
          Expanded(
            child: Obx(() {
              if (controller.poems.isEmpty) {
                return _buildEmptyView(context);
              }
              
              if (controller.displayPoems.isEmpty) {
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
                itemCount: controller.displayPoems.length,
                itemBuilder: (context, index) {
                  final poem = controller.displayPoems[index];
                  return PoemListItem(
                    poem: poem,
                    onTap: () {
                      // 收起键盘
                      FocusScope.of(context).unfocus();
                      controller.selectPoem(poem);
                      Get.to(() => const PoemDetailPage());
                    },
                    onMorePressed: () {
                      // 收起键盘
                      FocusScope.of(context).unfocus();
                      _showPoemOptions(context, poem);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddPoemPage()),
        backgroundColor: context.primaryColor,
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: context.textSecondaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无诗词',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
              fontSize: 15,
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
            '未找到匹配的诗词',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(BuildContext context, PoemController controller) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: Obx(() {
        final List<Widget> chips = [];
        
        // 全部（仅添加一次）
        chips.add(_buildGroupChip(
          context: context,
          label: '全部',
          isSelected: controller.selectedGroupId.value == -1,
          onTap: () => controller.selectGroup(-1),
        ));
        
        // 分组（过滤掉名为"全部"的分组，避免重复）
        for (final group in controller.groups) {
          if (group.name == '全部') continue; // 跳过名为"全部"的分组
          chips.add(_buildGroupChip(
            context: context,
            label: group.name,
            isSelected: controller.selectedGroupId.value == group.id,
            onTap: () => controller.selectGroup(group.id),
            onLongPress: () => _showGroupOptions(context, group),
          ));
        }
        
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => chips[index],
        );
      }),
    );
  }

  Widget _buildGroupChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    // 限制标签长度，最多显示6个字符
    String displayLabel = label;
    if (label.length > 6) {
      displayLabel = '${label.substring(0, 5)}...';
    }
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textPrimaryColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context, PoemGroup group) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(UIConstants.defaultRadius)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('分组操作'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('重命名'),
                onTap: () {
                  Get.back();
                  _showRenameGroupDialog(context, group);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除分组', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showDeleteGroupConfirm(context, group);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showPoemOptions(BuildContext context, Poem poem) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(UIConstants.defaultRadius)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: Text('《${poem.title}》', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('[${poem.dynasty ?? '未知'}] ${poem.author}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outlined),
                title: const Text('移动到分组'),
                onTap: () {
                  Get.back();
                  _showMoveToGroupDialog(context, poem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showDeletePoemConfirm(context, poem);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveToGroupDialog(BuildContext context, Poem poem) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('移动到分组', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMoveChip(context, '未分组', poem.groupId == null, () {
              controller.movePoemToGroup(poem.id, null);
              Get.back();
            }),
            ...controller.groups.map((g) => _buildMoveChip(
              context,
              g.name,
              poem.groupId == g.id,
              () {
                controller.movePoemToGroup(poem.id, g.id);
                Get.back();
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textPrimaryColor,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showDeletePoemConfirm(BuildContext context, Poem poem) {
    AppDialog.confirm(
      title: '删除诗词',
      message: '确定要删除《${poem.title}》吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
    ).then((confirmed) {
      if (confirmed == true) {
        controller.deletePoem(poem.id);
      }
    });
  }

  void _showRenameGroupDialog(BuildContext context, PoemGroup group) {
    final controller = TextEditingController(text: group.name);
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('重命名分组', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '分组名称',
            filled: true,
            fillColor: context.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final updated = group.copyWith(name: controller.text.trim());
                PoemController.to.updateGroup(updated);
                Get.back();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupConfirm(BuildContext context, PoemGroup group) {
    AppDialog.confirm(
      title: '删除分组',
      message: '确定要删除"${group.name}"吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: Colors.red,
    ).then((confirmed) {
      if (confirmed == true) {
        PoemController.to.deleteGroup(group.id);
      }
    });
  }
}

/// 诗词列表项 - 公共组件，可被书架页和收藏页复用
class PoemListItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const PoemListItem({
    super.key,
    required this.poem,
    required this.onTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PoemController>();
    
    return Container(
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
              // 收藏按钮（放在最右侧按钮旁边）
              Obx(() {
                final isFavorite = controller.isFavorite(poem.id!);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? context.primaryColor : context.textSecondaryColor,
                    size: 20,
                  ),
                  onPressed: () => controller.toggleFavorite(poem.id!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                );
              }),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.more_vert, color: context.textSecondaryColor),
                onPressed: onMorePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
