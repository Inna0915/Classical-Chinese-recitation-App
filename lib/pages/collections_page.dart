import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../models/collection.dart';
import '../models/poem_new.dart';
import '../services/poem_service.dart';
import '../widgets/dialogs/app_dialog.dart';
import 'poem_detail_page_new.dart';

/// 小集页 - 歌单封面墙风格
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
        title: const Text('我的小集'),
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _poemService.allCollections.length,
          itemBuilder: (context, index) {
            final collection = _poemService.allCollections[index];
            return CollectionCard(
              collection: collection,
              onTap: () => _openCollection(collection),
              onLongPress: () => _showCollectionOptions(collection),
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

  void _showCollectionOptions(Collection collection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                collection.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              subtitle: Text('${collection.poemCount} 首诗词'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.edit, color: context.textSecondaryColor),
              title: Text('编辑', style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Get.back();
                _showEditCollectionDialog(collection);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: context.errorColor),
              title: Text('删除', style: TextStyle(color: context.errorColor)),
              onTap: () {
                Get.back();
                _confirmDeleteCollection(collection);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    AppDialog.show(
      title: '创建小集',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '小集名称',
              hintText: '如：我的睡前故事',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              hintText: '添加一些描述...',
            ),
            maxLines: 2,
          ),
        ],
      ),
      confirmText: '创建',
      onConfirm: () async {
        if (nameController.text.trim().isEmpty) {
          return;
        }
        await _poemService.createCollection(
          nameController.text.trim(),
          description: descController.text.trim().isEmpty 
              ? null 
              : descController.text.trim(),
        );
        Get.back();
      },
    );
  }

  void _showEditCollectionDialog(Collection collection) {
    final nameController = TextEditingController(text: collection.name);
    final descController = TextEditingController(text: collection.description ?? '');

    AppDialog.show(
      title: '编辑小集',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '小集名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: '描述'),
            maxLines: 2,
          ),
        ],
      ),
      confirmText: '保存',
      onConfirm: () async {
        if (nameController.text.trim().isEmpty) {
          return;
        }
        await _poemService.updateCollection(
          collection.copyWith(
            name: nameController.text.trim(),
            description: descController.text.trim().isEmpty 
                ? null 
                : descController.text.trim(),
          ),
        );
        Get.back();
      },
    );
  }

  void _confirmDeleteCollection(Collection collection) {
    AppDialog.confirm(
      title: '删除小集',
      message: '确定要删除《${collection.name}》吗？\n小集内的诗词不会被删除。',
      confirmText: '删除',
      confirmColor: context.errorColor,
    ).then((confirmed) {
      if (confirmed == true) {
        _poemService.deleteCollection(collection.id!);
      }
    });
  }
}

/// 小集卡片 - 歌单封面风格
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面区域
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryColor.withAlpha(204),
                      context.primaryColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.folder_special,
                    size: 48,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ),
            ),
            // 信息区域
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.poemCount} 首诗词',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    if (collection.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondaryColor.withAlpha(179),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(_collection?.name ?? '小集详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _collection == null ? null : () {
              // TODO: 显示编辑对话框
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection == null
              ? const Center(child: Text('小集不存在'))
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final items = _collection!.items;

    return Column(
      children: [
        // 头部信息
        _buildHeader(context),
        
        // 诗词列表
        Expanded(
          child: items.isEmpty
              ? _buildEmptyList(context)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final poem = item.poem!;
                    return _buildPoemListItem(
                      context,
                      key: ValueKey(item.poemId),
                      poem: poem,
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryColor.withAlpha(204),
                        context.primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_special,
                    size: 40,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _collection!.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (_collection!.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _collection!.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${_collection!.poemCount} 首诗词',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 播放全部按钮
            if (_collection!.items.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _playAll,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('播放全部'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyList(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: context.textSecondaryColor.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            '小集是空的',
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在诗词详情页点击"添加到小集"',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoemListItem(
    BuildContext context, {
    required Key key,
    required Poem poem,
    required int index,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      color: context.cardColor,
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
          ),
        ),
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
              icon: Icon(Icons.remove_circle_outline, color: context.errorColor),
              onPressed: () => _removePoem(poem.id!),
            ),
            Icon(Icons.drag_handle, color: context.textSecondaryColor),
          ],
        ),
        onTap: () => _onPoemTap(poem),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _collection!.items.removeAt(oldIndex);
      _collection!.items.insert(newIndex, item);
    });
    
    // 保存排序
    final poemIds = _collection!.items.map((i) => i.poemId).toList();
    _poemService.reorderCollection(widget.collectionId, poemIds);
  }

  void _onPoemTap(Poem poem) {
    _poemService.setCollectionContext(
      widget.collectionId,
      initialPoemId: poem.id,
    );
    Get.to(() => PoemDetailPageNew(poemId: poem.id!));
  }

  void _playAll() {
    if (_collection!.items.isEmpty) return;
    
    _poemService.setCollectionContext(
      widget.collectionId,
      initialPoemId: _collection!.items.first.poemId,
    );
    Get.to(() => PoemDetailPageNew(
      poemId: _collection!.items.first.poemId,
    ));
  }

  void _removePoem(int poemId) {
    _poemService.removePoemFromCollection(widget.collectionId, poemId);
    _loadCollection();
  }
}
