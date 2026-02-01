/// 诗词分组模型
class PoemGroup {
  final int id;
  final String name;
  final int sortOrder;
  final DateTime? createdAt;

  PoemGroup({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory PoemGroup.fromMap(Map<String, dynamic> map) {
    return PoemGroup(
      id: map['id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  PoemGroup copyWith({
    int? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return PoemGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
