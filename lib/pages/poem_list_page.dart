import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import 'add_poem_page.dart';
import 'poem_detail_page.dart';

/// 诗词列表页 - 书架式布局（带分组和拖拽）
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

      ),
      body: Obx(() {
        if (controller.poems.isEmpty) {
          return _buildEmptyView();
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 书架标题区
            SliverToBoxAdapter(
              child: _buildBookshelfHeader(controller),
            ),

            // 分组选择器
            SliverToBoxAdapter(
              child: _buildGroupSelector(controller),
            ),

            // 诗词网格（书架效果）
            SliverPadding(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final poem = controller.filteredPoems[index];
                    return _BookItem(
                      poem: poem,
                      onTap: () {
                        controller.selectPoem(poem);
                        Get.to(() => const PoemDetailPage());
                      },
                      onLongPress: () => _showGroupMenu(context, poem),
                    );
                  },
                  childCount: controller.filteredPoems.length,
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

  /// 分组选择器
  Widget _buildGroupSelector(PoemController controller) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding),
            itemCount: controller.groups.length + 3, // +3 为"全部"、"+"、"管理"按钮
            itemBuilder: (context, index) {
              // 最后一个按钮是管理分组
              if (index == controller.groups.length + 2) {
                return _buildManageGroupsButton();
              }
              
              // 倒数第二个按钮是添加分组
              if (index == controller.groups.length + 1) {
                return _buildAddGroupButton();
              }

              // 第一个是"全部"
              if (index == 0) {
                final isSelected = controller.selectedGroupId.value == -1;
                return _buildGroupChip(
                  label: '全部',
                  isSelected: isSelected,
                  onTap: () => controller.selectGroup(-1),
                  count: controller.poems.length,
                );
              }

              // 分组项
              final group = controller.groups[index - 1];
              final isSelected = controller.selectedGroupId.value == group.id;
              final count = controller.poems
                  .where((p) => p.groupId == group.id)
                  .length;

              return _buildGroupChip(
                label: group.name,
                isSelected: isSelected,
                onTap: () => controller.selectGroup(group.id),
                count: count,
                onLongPress: () => _showGroupOptions(context, group),
              );
            },
          )),
    );
  }
  
  /// 管理分组按钮
  Widget _buildManageGroupsButton() {
    return GestureDetector(
      onTap: () => _showManageGroupsDialog(),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Icons.drag_indicator,
              size: 16,
              color: Color(UIConstants.textSecondaryColor),
            ),
            SizedBox(width: 4),
            Text(
              '排序',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 显示管理分组对话框（支持拖拽排序）
  void _showManageGroupsDialog() {
    final controller = PoemController.to;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text(
          '管理分组',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() => ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: controller.groups.length,
            onReorder: (oldIndex, newIndex) {
              controller.reorderGroups(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final group = controller.groups[index];
              return Card(
                key: ValueKey(group.id),
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(UIConstants.backgroundColor),
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      Get.back();
                      _showRenameGroupDialog(group);
                    },
                  ),
                ),
              );
            },
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  /// 分组标签
  Widget _buildGroupChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int count,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(UIConstants.textPrimaryColor),
                fontSize: 14,
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
                  fontSize: 11,
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

  /// 显示移动诗词到分组菜单
  void _showGroupMenu(BuildContext context, Poem poem) {
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
              const Text(
                '移动到分组：',
                style: TextStyle(
                  color: Color(UIConstants.textSecondaryColor),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              
              // 删除按钮
              const Divider(height: 1),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  '删除诗文',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteConfirm(poem);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 显示删除确认对话框
  void _showDeleteConfirm(Poem poem) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('删除诗文'),
        content: Text('确定要删除《${poem.title}》吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePoem(poem.id);
              Get.back();
              Get.snackbar(
                '已删除',
                '《${poem.title}》已删除',
                snackPosition: SnackPosition.BOTTOM,
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
    final controller = TextEditingController();
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
          controller: controller,
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
              if (controller.text.trim().isNotEmpty) {
                PoemController.to.addGroup(controller.text.trim());
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
    final controller = TextEditingController(text: group.name);
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
          controller: controller,
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
              if (controller.text.trim().isNotEmpty) {
                final updated = group.copyWith(name: controller.text.trim());
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

/// 书本样式列表项
class _BookItem extends StatelessWidget {
  final Poem poem;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BookItem({
    required this.poem,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 标题
                          Text(
                            poem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: FontConstants.chineseSerif,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // 分隔线
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const SizedBox(height: 8),

                          // 作者
                          Text(
                            '[${poem.dynasty ?? '未知'}] ${poem.author}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

                    // 收藏标记
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Obx(() => controller.isFavorite(poem.id)
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 14,
                                color: Color(UIConstants.accentColor),
                              ),
                            )
                          : const SizedBox.shrink()),
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
