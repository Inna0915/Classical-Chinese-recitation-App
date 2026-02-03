import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import 'add_poem_page.dart';
import 'poem_detail_page.dart';

/// 诗词列表页 - 列表式布局
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
          // 搜索按钮
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(UIConstants.accentColor),
            ),
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
            // 分组选择器 - 支持拖拽排序
            _buildGroupSelector(controller),
            
            // 统计信息
            _buildStatsHeader(controller),
            
            // 诗词列表
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
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
            
            // 底部留白
            const SizedBox(height: 80),
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

  /// 统计信息头部
  Widget _buildStatsHeader(PoemController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: UIConstants.defaultPadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Obx(() => Row(
        children: [
          const Icon(
            Icons.menu_book,
            color: Color(UIConstants.accentColor),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '共 ${controller.filteredPoems.length} 首',
            style: const TextStyle(
              color: Color(UIConstants.textSecondaryColor),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (controller.selectedGroupId.value != -1)
            TextButton.icon(
              onPressed: () => controller.selectGroup(-1),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('清除筛选'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(UIConstants.textSecondaryColor),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      )),
    );
  }

  /// 分组选择器 - 支持拖拽排序
  Widget _buildGroupSelector(PoemController controller) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        // 构建分组列表项
        final List<Widget> groupWidgets = [];
        
        // 添加"全部"选项（不可拖拽）- 使用 Key
        groupWidgets.add(
          Container(
            key: const ValueKey('group_all'),
            child: _buildGroupChip(
              label: '全部',
              isSelected: controller.selectedGroupId.value == -1,
              onTap: () => controller.selectGroup(-1),
              count: controller.poems.length,
              draggable: false,
            ),
          ),
        );
        
        // 添加分组项（可拖拽）
        for (int i = 0; i < controller.groups.length; i++) {
          final group = controller.groups[i];
          final count = controller.poems.where((p) => p.groupId == group.id).length;
          
          groupWidgets.add(
            _buildDraggableGroupChip(
              key: ValueKey('group_${group.id}'),
              group: group,
              index: i,
              isSelected: controller.selectedGroupId.value == group.id,
              count: count,
              onTap: () => controller.selectGroup(group.id),
              onLongPress: () => _showGroupOptions(context, group),
            ),
          );
        }
        
        // 添加"新建分组"按钮（不可拖拽）- 使用 Key
        groupWidgets.add(
          Container(
            key: const ValueKey('group_add_new'),
            child: _buildAddGroupButton(),
          ),
        );
        
        return ReorderableListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.05,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) {
            // 调整索引，因为第一个是"全部"
            final adjustedOldIndex = oldIndex - 1;
            final adjustedNewIndex = newIndex - 1;
            
            // 确保在有效范围内
            if (adjustedOldIndex < 0 || adjustedOldIndex >= controller.groups.length) return;
            if (adjustedNewIndex < 0 || adjustedNewIndex > controller.groups.length) return;
            
            // 调用控制器重新排序
            controller.reorderGroups(adjustedOldIndex, adjustedNewIndex);
          },
          children: groupWidgets,
        );
      }),
    );
  }
  
  /// 可拖拽的分组标签
  Widget _buildDraggableGroupChip({
    Key? key,
    required PoemGroup group,
    required int index,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return ReorderableDragStartListener(
      key: key,
      index: index + 1, // +1 因为第一个是"全部"
      child: GestureDetector(
        onLongPress: onLongPress,
        child: _buildGroupChip(
          label: group.name,
          isSelected: isSelected,
          onTap: onTap,
          count: count,
          draggable: true,
        ),
      ),
    );
  }

  /// 分组标签
  Widget _buildGroupChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int count,
    bool draggable = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(UIConstants.accentColor)
              : const Color(UIConstants.cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(UIConstants.accentColor)
                : const Color(UIConstants.dividerColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draggable)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : const Color(UIConstants.textSecondaryColor).withOpacity(0.5),
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(UIConstants.textPrimaryColor),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : const Color(UIConstants.backgroundColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(UIConstants.textSecondaryColor),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加分组按钮
  Widget _buildAddGroupButton() {
    return GestureDetector(
      onTap: () => _showAddGroupDialog(),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(UIConstants.cardColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(UIConstants.dividerColor),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: Color(UIConstants.textSecondaryColor),
            ),
            SizedBox(width: 4),
            Text(
              '新建分组',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示分组选项菜单
  void _showGroupOptions(BuildContext context, PoemGroup group) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(UIConstants.dividerColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '分组：${group.name}',
                style: const TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(UIConstants.textPrimaryColor),
                ),
                title: const Text('重命名'),
                onTap: () {
                  Get.back();
                  _showRenameGroupDialog(group);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  '删除分组',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteGroupConfirm(group);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示诗词选项菜单（包含移动分组和删除）
  void _showPoemOptions(BuildContext context, Poem poem) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(UIConstants.dividerColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '《${poem.title}》',
                style: const TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '[${poem.dynasty ?? '未知'}] ${poem.author}',
                style: const TextStyle(
                  color: Color(UIConstants.textSecondaryColor),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // 移动到分组
              const Text(
                '移动到分组：',
                style: TextStyle(
                  color: Color(UIConstants.textSecondaryColor),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // 未分组选项
                  _buildMoveToGroupChip(
                    label: '未分组',
                    isSelected: poem.groupId == null,
                    onTap: () {
                      controller.movePoemToGroup(poem.id, null);
                      Get.back();
                    },
                  ),
                  // 各分组选项
                  ...controller.groups.map((group) => _buildMoveToGroupChip(
                        label: group.name,
                        isSelected: poem.groupId == group.id,
                        onTap: () {
                          controller.movePoemToGroup(poem.id, group.id);
                          Get.back();
                        },
                      )),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // 删除按钮
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  '删除诗词',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _showDeletePoemConfirm(poem);
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 显示删除诗词确认
  void _showDeletePoemConfirm(Poem poem) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '删除诗词',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Text(
          '确定要删除《${poem.title}》吗？\n此操作不可恢复。',
          style: const TextStyle(
            color: Color(UIConstants.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePoem(poem.id);
              Get.back();
              Get.snackbar(
                '已删除',
                '《${poem.title}》已删除',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
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

  /// 移动到分组的标签
  Widget _buildMoveToGroupChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(UIConstants.accentColor).withOpacity(0.1)
              : const Color(UIConstants.backgroundColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(UIConstants.accentColor)
                : const Color(UIConstants.dividerColor),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(UIConstants.accentColor)
                : const Color(UIConstants.textPrimaryColor),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 显示添加分组对话框
  void _showAddGroupDialog() {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '新建分组',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入分组名称',
            hintStyle: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.accentColor),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                PoemController.to.addGroup(textController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示重命名分组对话框
  void _showRenameGroupDialog(PoemGroup group) {
    final textController = TextEditingController(text: group.name);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '重命名分组',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入新名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.accentColor),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                final updated = group.copyWith(name: textController.text.trim());
                PoemController.to.groups[PoemController.to.groups
                    .indexWhere((g) => g.id == group.id)] = updated;
                // TODO: 更新数据库
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示删除分组确认
  void _showDeleteGroupConfirm(PoemGroup group) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '删除分组',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Text(
          '确定要删除"${group.name}"分组吗？\n分组内的诗词将变为未分组状态。',
          style: const TextStyle(
            color: Color(UIConstants.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PoemController.to.deleteGroup(group.id);
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

/// 列表项 - 诗词列表项
class _PoemListItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;

  const _PoemListItem({
    required this.poem,
    required this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(UIConstants.cardColor),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        side: const BorderSide(
          color: Color(UIConstants.dividerColor),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 左侧：诗词信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      poem.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(UIConstants.textPrimaryColor),
                        fontFamily: FontConstants.chineseSerif,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 作者信息
                    Text(
                      '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 右侧：操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 更多按钮
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(UIConstants.textSecondaryColor),
                      size: 20,
                    ),
                    onPressed: onMorePressed ?? () {},
                    tooltip: '更多操作',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
