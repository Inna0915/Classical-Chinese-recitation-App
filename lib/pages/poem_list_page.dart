import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import 'add_poem_page.dart';
import 'poem_detail_page.dart';

/// 诗词列表页 - WeChat-like Minimalism
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
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        title: const Text(
          '古韵诵读',
          style: TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(UIConstants.textPrimaryColor)),
            onPressed: () => _showSearchDialog(controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.poems.isEmpty) {
          return _buildEmptyView();
        }

        return Column(
          children: [
            // 分组选择器
            _buildGroupSelector(controller),
            // 诗词列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.filteredPoems.length,
                itemBuilder: (context, index) {
                  final poem = controller.filteredPoems[index];
                  return _PoemListItem(
                    poem: poem,
                    onTap: () {
                      controller.selectPoem(poem);
                      Get.to(() => const PoemDetailPage());
                    },
                    onMorePressed: () => _showPoemOptions(context, poem),
                  );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddPoemPage()),
        backgroundColor: const Color(UIConstants.accentColor),
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: const Color(UIConstants.textSecondaryColor).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无诗词',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(PoemController controller) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        final List<Widget> chips = [];
        
        // 全部
        chips.add(_buildGroupChip(
          label: '全部',
          isSelected: controller.selectedGroupId.value == -1,
          onTap: () => controller.selectGroup(-1),
        ));
        
        // 分组
        for (final group in controller.groups) {
          chips.add(_buildGroupChip(
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
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(UIConstants.accentColor) : const Color(UIConstants.cardColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(UIConstants.textPrimaryColor),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context, PoemGroup group) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
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
                  color: const Color(UIConstants.dividerColor),
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
                  _showRenameGroupDialog(group);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除分组', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showDeleteGroupConfirm(group);
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
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
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
                  color: const Color(UIConstants.dividerColor),
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
                  _showMoveToGroupDialog(poem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _showDeletePoemConfirm(poem);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveToGroupDialog(Poem poem) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('移动到分组', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMoveChip('未分组', poem.groupId == null, () {
              controller.movePoemToGroup(poem.id, null);
              Get.back();
            }),
            ...controller.groups.map((g) => _buildMoveChip(
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

  Widget _buildMoveChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(UIConstants.accentColor) : const Color(UIConstants.backgroundColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(UIConstants.textPrimaryColor),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showDeletePoemConfirm(Poem poem) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('删除诗词', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('确定要删除《${poem.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消', style: TextStyle(color: Color(UIConstants.textSecondaryColor))),
          ),
          TextButton(
            onPressed: () {
              controller.deletePoem(poem.id);
              Get.back();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameGroupDialog(PoemGroup group) {
    final controller = TextEditingController(text: group.name);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('重命名分组', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '分组名称',
            filled: true,
            fillColor: const Color(UIConstants.backgroundColor),
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

  void _showDeleteGroupConfirm(PoemGroup group) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('删除分组', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('确定要删除"${group.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              PoemController.to.deleteGroup(group.id);
              Get.back();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(PoemController controller) {
    final searchController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.defaultRadius)),
        title: const Text('搜索诗词', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标题、作者或内容',
            filled: true,
            fillColor: const Color(UIConstants.backgroundColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.loadPoems();
              Get.back();
            },
            child: const Text('重置'),
          ),
          TextButton(
            onPressed: () {
              controller.searchPoems(searchController.text);
              Get.back();
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
}

/// 诗词列表项
class _PoemListItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const _PoemListItem({
    required this.poem,
    required this.onTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poem.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(UIConstants.textPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${poem.dynasty ?? ''} · ${poem.author}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(UIConstants.textSecondaryColor)),
                onPressed: onMorePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
