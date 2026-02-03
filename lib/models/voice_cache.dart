/// 语音缓存模型 - 支持多音色缓存
class VoiceCache {
  final int? id;
  final int poemId;
  final String voiceType;
  final String filePath;
  final String? timestampPath; // 时间戳文件路径
  final int fileSize;
  final DateTime createdAt;

  VoiceCache({
    this.id,
    required this.poemId,
    required this.voiceType,
    required this.filePath,
    this.timestampPath,
    required this.fileSize,
    required this.createdAt,
  });

  factory VoiceCache.fromMap(Map<String, dynamic> map) {
    return VoiceCache(
      id: map['id'] as int?,
      poemId: map['poem_id'] as int,
      voiceType: map['voice_type'] as String,
      filePath: map['file_path'] as String,
      timestampPath: map['timestamp_path'] as String?,
      fileSize: map['file_size'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'poem_id': poemId,
      'voice_type': voiceType,
      'file_path': filePath,
      'timestamp_path': timestampPath,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VoiceCache copyWith({
    int? id,
    int? poemId,
    String? voiceType,
    String? filePath,
    String? timestampPath,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return VoiceCache(
      id: id ?? this.id,
      poemId: poemId ?? this.poemId,
      voiceType: voiceType ?? this.voiceType,
      filePath: filePath ?? this.filePath,
      timestampPath: timestampPath ?? this.timestampPath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
