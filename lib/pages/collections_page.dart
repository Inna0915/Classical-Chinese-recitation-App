import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/player_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/collection.dart';
import '../models/poem_new.dart';
import '../services/poem_service.dart';
import '../utils/collection_covers.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'poem_detail_page_new.dart';

/// 小集页 - 列表卡片风格
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final PoemService _poemService = Get.find<PoemService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('小集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCollectionDialog,
          ),
        ],
      ),
      body: Obx(() {
        if (_poemService.allCollections.isEmpty) {
          return _buildEmptyView(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _poemService.allCollections.length,
          itemBuilder: (context, index) {
            final collection = _poemService.allCollections[index];
            return _CollectionCard(
              collection: collection,
              onTap: () => _openCollection(collection),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: context.textSecondaryColor.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有小集',
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showCreateCollectionDialog,
            child: const Text('创建第一个小集'),
          ),
        ],
      ),
    );
  }

  void _openCollection(Collection collection) {
    Get.to(() => CollectionDetailPage(collectionId: collection.id!));
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('创建小集', style: TextStyle(color: context.textPrimaryColor)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '小集名称',
            hintText: '请输入小集名称',
          ),
          style: TextStyle(color: context.textPrimaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _poemService.createCollection(nameController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

/// 小集卡片 - 横向列表风格
class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PoemService poemService = Get.find<PoemService>();
    
    return Dismissible(
      key: Key('collection_${collection.id}'),
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
              '删除',
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
          title: '删除小集',
          message: '确定要删除小集《${collection.name}》吗？小集内的诗词不会被删除。',
          confirmText: '删除',
          cancelText: '保留',
          confirmColor: context.errorColor,
        );
      },
      onDismissed: (_) => poemService.deleteCollection(collection.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: context.cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 左侧：渐变封面
                _buildCoverImage(context),
                const SizedBox(width: 12),
                // 中间：信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              collection.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (collection.isPinned)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.push_pin,
                                size: 12,
                                color: context.primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${collection.poemCount} 首诗词',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      // 显示前3个诗词标题
                      if (collection.items.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: collection.items.take(3).map((item) {
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
                                item.poem?.title ?? '未知',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // 右侧：操作按钮
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 置顶按钮
                    IconButton(
                      icon: Icon(
                        collection.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: collection.isPinned 
                            ? context.primaryColor 
                            : context.textSecondaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        poemService.setCollectionPinned(
                          collection.id!, 
                          !collection.isPinned,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: collection.isPinned ? '取消置顶' : '置顶',
                    ),
                    // 删除按钮
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.textSecondaryColor,
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await AppDialog.confirm(
                          title: '删除小集',
                          message: '确定要删除小集《${collection.name}》吗？',
                          confirmText: '删除',
                          cancelText: '取消',
                          confirmColor: context.errorColor,
                        );
                        if (confirm == true) {
                          poemService.deleteCollection(collection.id!);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: '删除',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建封面图片
  Widget _buildCoverImage(BuildContext context) {
    final coverIndex = collection.id != null 
        ? collection.id! % CollectionCovers.count 
        : collection.name.hashCode % CollectionCovers.count;
    final cover = CollectionCovers.getByIndex(coverIndex);

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cover.gradientColors,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          cover.icon,
          size: 32,
          color: Colors.white.withAlpha(230),
        ),
      ),
    );
  }
}

/// 小集详情页
class CollectionDetailPage extends StatefulWidget {
  final int collectionId;

  const CollectionDetailPage({super.key, required this.collectionId});

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final PoemService _poemService = Get.find<PoemService>();
  Collection? _collection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    setState(() => _isLoading = true);
    _collection = await _poemService.getCollection(widget.collectionId);
    setState(() => _isLoading = false);
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context) {
    if (_collection == null) return;
    
    final nameController = TextEditingController(text: _collection!.name);
    final descController = TextEditingController(text: _collection!.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text('编辑小集', style: TextStyle(color: context.textPrimaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '小集名称',
              ),
              style: TextStyle(color: context.textPrimaryColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
              ),
              style: TextStyle(color: context.textPrimaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _poemService.updateCollection(_collection!.copyWith(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty 
                      ? null 
                      : descController.text.trim(),
                ));
                await _loadCollection();
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 播放全部
  void _playAll() {
    if (_collection == null || _collection!.items.isEmpty) return;
    
    final poems = _collection!.items
        .where((item) => item.poem != null)
        .map((item) => item.poem!)
        .toList();
    
    if (poems.isNotEmpty) {
      final playerController = Get.find<PlayerController>();
      playerController.playPoemList(poems, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(_collection?.name ?? '小集详情'),
        actions: [
          if (_collection != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection == null
              ? Center(
                  child: Text(
                    '小集不存在',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                )
              : Column(
                  children: [
                    // 播放全部按钮
                    if (_collection!.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _playAll,
                            icon: const Icon(Icons.play_arrow),
                            label: Text('播放全部 (${_collection!.items.length}首)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    // 诗词列表
                    Expanded(
                      child: _collection!.items.isEmpty
                          ? Center(
                              child: Text(
                                '小集中还没有诗词',
                                style: TextStyle(color: context.textSecondaryColor),
                              ),
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _collection!.items.length,
                              onReorder: (oldIndex, newIndex) async {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = _collection!.items.removeAt(oldIndex);
                                _collection!.items.insert(newIndex, item);
                                
                                // 更新数据库排序
                                final poemIds = _collection!.items
                                    .map((i) => i.poemId)
                                    .toList();
                                await _poemService.reorderCollection(
                                  widget.collectionId, 
                                  poemIds,
                                );
                                setState(() {});
                              },
                              itemBuilder: (context, index) {
                                final item = _collection!.items[index];
                                return _CollectionPoemItem(
                                  key: Key('item_${item.poemId}'),
                                  item: item,
                                  onRemove: () async {
                                    await _poemService.removePoemFromCollection(
                                      widget.collectionId, 
                                      item.poemId,
                                    );
                                    await _loadCollection();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

/// 小集内的诗词项
class _CollectionPoemItem extends StatelessWidget {
  final CollectionItem item;
  final VoidCallback onRemove;

  const _CollectionPoemItem({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final poem = item.poem;
    if (poem == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.dividerColor),
      ),
      child: ListTile(
        title: Text(
          poem.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          poem.author,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondaryColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.play_circle_outline,
                color: context.primaryColor,
              ),
              onPressed: () {
                final playerController = Get.find<PlayerController>();
                playerController.playPoemList([poem], 0);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: context.errorColor,
              ),
              onPressed: () async {
                final confirm = await AppDialog.confirm(
                  title: '移除诗词',
                  message: '确定要从小集中移除《${poem.title}》吗？',
                  confirmText: '移除',
                  cancelText: '保留',
                  confirmColor: context.errorColor,
                );
                if (confirm == true) {
                  onRemove();
                }
              },
            ),
          ],
        ),
        onTap: () {
          Get.to(() => PoemDetailPageNew(poemId: poem.id!));
        },
      ),
    );
  }
}
