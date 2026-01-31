/// 古诗数据模型
/// 
/// 包含诗词的基本信息以及本地音频缓存路径
class Poem {
  /// 诗词唯一标识（使用诗词标题的 hash 或固定ID）
  final int id;
  
  /// 诗词标题
  final String title;
  
  /// 作者
  final String author;
  
  /// 朝代（如：唐、宋、元等）
  final String? dynasty;
  
  /// 诗词正文内容
  final String content;
  
  /// 本地音频文件缓存路径（null 表示未缓存）
  final String? localAudioPath;
  
  /// 创建时间
  final DateTime? createdAt;

  Poem({
    required this.id,
    required this.title,
    required this.author,
    this.dynasty,
    required this.content,
    this.localAudioPath,
    this.createdAt,
  });

  /// 从数据库 Map 转换为 Poem 对象
  factory Poem.fromMap(Map<String, dynamic> map) {
    return Poem(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      dynasty: map['dynasty'] as String?,
      content: map['content'] as String,
      localAudioPath: map['local_audio_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
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
      'local_audio_path': localAudioPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// 创建 Poem 的副本，可修改部分字段
  Poem copyWith({
    int? id,
    String? title,
    String? author,
    String? dynasty,
    String? content,
    String? localAudioPath,
    DateTime? createdAt,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      dynasty: dynasty ?? this.dynasty,
      content: content ?? this.content,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Poem{id: $id, title: $title, author: $author, localAudioPath: $localAudioPath}';
  }
}
