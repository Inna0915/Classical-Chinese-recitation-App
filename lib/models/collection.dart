import 'poem_new.dart';

/// 小集/歌单数据模型
class Collection {
  final int? id;
  final String name;
  final String? description;
  final String? coverImage;
  final bool isPinned;
  final DateTime createdAt;
  
  // 运行时数据
  final int poemCount;
  final List<CollectionItem> items;

  Collection({
    this.id,
    required this.name,
    this.description,
    this.coverImage,
    this.isPinned = false,
    DateTime? createdAt,
    this.poemCount = 0,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      coverImage: map['cover_image'] as String?,
      isPinned: (map['is_pinned'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_image': coverImage,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Collection copyWith({
    int? id,
    String? name,
    String? description,
    String? coverImage,
    bool? isPinned,
    DateTime? createdAt,
    int? poemCount,
    List<CollectionItem>? items,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      poemCount: poemCount ?? this.poemCount,
      items: items ?? this.items,
    );
  }
}

/// 小集内的诗词项（支持排序）
class CollectionItem {
  final int collectionId;
  final int poemId;
  final int sortOrder;
  
  // 关联的诗词数据
  final Poem? poem;

  CollectionItem({
    required this.collectionId,
    required this.poemId,
    required this.sortOrder,
    this.poem,
  });

  factory CollectionItem.fromMap(Map<String, dynamic> map) {
    return CollectionItem(
      collectionId: map['collection_id'] as int,
      poemId: map['poem_id'] as int,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collection_id': collectionId,
      'poem_id': poemId,
      'sort_order': sortOrder,
    };
  }
}

/// 播放上下文类型
enum PlaybackContextType {
  all,        // 全部诗词
  tag,        // 按标签
  collection, // 按小集
  favorite,   // 收藏
  search,     // 搜索结果
}

/// 播放上下文
class PlaybackContext {
  final PlaybackContextType type;
  final String? tagName;      // type=tag时使用
  final int? collectionId;    // type=collection时使用
  final String? searchQuery;  // type=search时使用
  final int? initialPoemId;   // 初始播放的诗词ID

  const PlaybackContext({
    required this.type,
    this.tagName,
    this.collectionId,
    this.searchQuery,
    this.initialPoemId,
  });

  /// 全部诗词上下文
  factory PlaybackContext.all({int? initialPoemId}) {
    return PlaybackContext(
      type: PlaybackContextType.all,
      initialPoemId: initialPoemId,
    );
  }

  /// 标签播放上下文
  factory PlaybackContext.tag(String tagName, {int? initialPoemId}) {
    return PlaybackContext(
      type: PlaybackContextType.tag,
      tagName: tagName,
      initialPoemId: initialPoemId,
    );
  }

  /// 小集播放上下文
  factory PlaybackContext.collection(int collectionId, {int? initialPoemId}) {
    return PlaybackContext(
      type: PlaybackContextType.collection,
      collectionId: collectionId,
      initialPoemId: initialPoemId,
    );
  }

  /// 收藏播放上下文
  factory PlaybackContext.favorite({int? initialPoemId}) {
    return PlaybackContext(
      type: PlaybackContextType.favorite,
      initialPoemId: initialPoemId,
    );
  }

  /// 搜索播放上下文
  factory PlaybackContext.search(String query, {int? initialPoemId}) {
    return PlaybackContext(
      type: PlaybackContextType.search,
      searchQuery: query,
      initialPoemId: initialPoemId,
    );
  }
}
