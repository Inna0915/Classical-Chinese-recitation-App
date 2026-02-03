/// 古诗数据模型
/// 
/// 包含诗词的基本信息以及本地音频缓存路径
class Poem {
  /// 诗词唯一标识
  final int id;
  
  /// 诗词标题
  final String title;
  
  /// 作者
  final String author;
  
  /// 朝代（如：唐、宋、元等）
  final String? dynasty;
  
  /// 诗词正文内容（兼容旧字段）
  final String content;
  
  /// 纯净版原文（用于展示和TTS朗读）
  final String cleanContent;
  
  /// 带释义的原文（用于展示释义版）
  final String? annotatedContent;
  
  /// 本地音频文件缓存路径（null 表示未缓存）
  final String? localAudioPath;
  
  /// 创建时间
  final DateTime? createdAt;

  /// 所属分组ID
  final int? groupId;

  /// 是否收藏
  final bool isFavorite;

  Poem({
    required this.id,
    required this.title,
    required this.author,
    this.dynasty,
    required this.content,
    this.cleanContent = '',
    this.annotatedContent,
    this.localAudioPath,
    this.createdAt,
    this.groupId,
    this.isFavorite = false,
  });

  /// 从数据库 Map 转换为 Poem 对象
  factory Poem.fromMap(Map<String, dynamic> map) {
    final content = map['content'] as String;
    final clean = map['clean_content'] as String?;
    final annotated = map['annotated_content'] as String?;
    
    return Poem(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      dynasty: map['dynasty'] as String?,
      content: content,
      // 兼容旧数据：如果没有 clean_content，使用 content
      cleanContent: clean ?? content,
      // 兼容旧数据：如果没有 annotated_content，显示 cleanContent
      annotatedContent: annotated,
      localAudioPath: map['local_audio_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      groupId: map['group_id'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  /// 将 Poem 对象转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'dynasty': dynasty,
      'content': content,
      'clean_content': cleanContent,
      'annotated_content': annotatedContent,
      'local_audio_path': localAudioPath,
      'created_at': createdAt?.toIso8601String(),
      'group_id': groupId,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// 创建 Poem 的副本，可修改部分字段
  Poem copyWith({
    int? id,
    String? title,
    String? author,
    String? dynasty,
    String? content,
    String? cleanContent,
    String? annotatedContent,
    String? localAudioPath,
    DateTime? createdAt,
    int? groupId,
    bool? isFavorite,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      dynasty: dynasty ?? this.dynasty,
      content: content ?? this.content,
      cleanContent: cleanContent ?? this.cleanContent,
      annotatedContent: annotatedContent ?? this.annotatedContent,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'Poem{id: $id, title: $title, author: $author, localAudioPath: $localAudioPath, groupId: $groupId, isFavorite: $isFavorite}';
  }
}
