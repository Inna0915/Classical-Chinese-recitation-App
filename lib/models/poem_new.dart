/// 诗词数据模型 (新架构 - 标签+歌单模式)
class Poem {
  final int? id;
  final String title;
  final String author;
  final String cleanContent;
  final String annotatedContent;
  final String? localAudioPath;
  final bool isFavorite;
  final DateTime createdAt;
  
  // 关联数据（非数据库字段，运行时填充）
  final List<Tag> tags;

  Poem({
    this.id,
    required this.title,
    required this.author,
    required this.cleanContent,
    required this.annotatedContent,
    this.localAudioPath,
    this.isFavorite = false,
    DateTime? createdAt,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从数据库Map创建
  factory Poem.fromMap(Map<String, dynamic> map) {
    return Poem(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      cleanContent: map['clean_content'] as String,
      annotatedContent: map['annotated_content'] as String,
      localAudioPath: map['local_audio_path'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      tags: [],
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'clean_content': cleanContent,
      'annotated_content': annotatedContent,
      'local_audio_path': localAudioPath,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 从JSON初始化数据创建
  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      title: json['title'] as String,
      author: json['author'] as String,
      cleanContent: json['clean_content'] as String,
      annotatedContent: json['annotated_content'] as String,
      tags: [],
    );
  }

  Poem copyWith({
    int? id,
    String? title,
    String? author,
    String? cleanContent,
    String? annotatedContent,
    String? localAudioPath,
    bool? isFavorite,
    DateTime? createdAt,
    List<Tag>? tags,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      cleanContent: cleanContent ?? this.cleanContent,
      annotatedContent: annotatedContent ?? this.annotatedContent,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}

/// 标签数据模型
class Tag {
  final int? id;
  final String name;
  final int poemCount; // 关联的诗词数量（运行时计算）

  Tag({
    this.id,
    required this.name,
    this.poemCount = 0,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  Tag copyWith({
    int? id,
    String? name,
    int? poemCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      poemCount: poemCount ?? this.poemCount,
    );
  }
}

/// 诗词-标签关联
class PoemTag {
  final int poemId;
  final int tagId;

  PoemTag({
    required this.poemId,
    required this.tagId,
  });

  Map<String, dynamic> toMap() {
    return {
      'poem_id': poemId,
      'tag_id': tagId,
    };
  }
}
