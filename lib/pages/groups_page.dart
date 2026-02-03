import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import 'poem_detail_page.dart';
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
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '分组浏览',
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
        if (controller.groups.isEmpty) {
          return _buildEmptyView();
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
            Icons.folder_outlined,
            size: 80,
            color: const Color(UIConstants.textSecondaryColor).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无分组',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在书架页面创建分组并添加诗词',
            style: TextStyle(
              color: const Color(UIConstants.textSecondaryColor).withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示分组详情
  void _showGroupDetail(PoemGroup group, List<Poem> poems) {
    Get.to(() => GroupDetailPage(group: group, poems: poems));
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      color: const Color(UIConstants.accentColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder,
                      color: Color(UIConstants.accentColor),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(UIConstants.textPrimaryColor),
                            fontFamily: FontConstants.chineseSerif,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '共 ${poems.length} 首诗词',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(UIConstants.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(UIConstants.textSecondaryColor),
                    size: 16,
                  ),
                ],
              ),
              
              // 预览部分诗词
              if (poems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...poems.take(3).map((poem) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 14,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          poem.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(UIConstants.textSecondaryColor),
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
                        color: const Color(UIConstants.textSecondaryColor).withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 分组详情页
class GroupDetailPage extends StatelessWidget {
  final PoemGroup group;
  final List<Poem> poems;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.poems,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Scaffold(
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        title: Text(
          group.name,
          style: const TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontFamily: FontConstants.chineseSerif,
          ),
        ),
        actions: [
          // 顺序播放按钮
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            color: const Color(UIConstants.accentColor),
            tooltip: '顺序播放',
            onPressed: () => controller.playGroupInOrder(poems),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        itemCount: poems.length,
        itemBuilder: (context, index) {
          final poem = poems[index];
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(UIConstants.accentColor).withOpacity(0.1),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(UIConstants.accentColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                poem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: FontConstants.chineseSerif,
                ),
              ),
              subtitle: Text(
                '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                style: const TextStyle(
                  color: Color(UIConstants.textSecondaryColor),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(UIConstants.textSecondaryColor),
              ),
              onTap: () {
                controller.selectPoem(poem);
                Get.to(() => const PoemDetailPage());
              },
            ),
          );
        },
      ),
    );
  }
}
