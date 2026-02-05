import 'package:flutter/material.dart';
import 'dart:math';

/// 小集封面预设
class CollectionCover {
  final String name;
  final List<Color> gradientColors;
  final IconData icon;

  const CollectionCover({
    required this.name,
    required this.gradientColors,
    required this.icon,
  });
}

/// 预设封面列表
class CollectionCovers {
  static const List<CollectionCover> presets = [
    // 诗词经典 - 红色系
    CollectionCover(
      name: '朱砂红',
      gradientColors: [Color(0xFFE57373), Color(0xFFC62828)],
      icon: Icons.menu_book,
    ),
    // 竹林清风 - 绿色系
    CollectionCover(
      name: '竹青绿',
      gradientColors: [Color(0xFF81C784), Color(0xFF2E7D32)],
      icon: Icons.forest,
    ),
    // 蓝天白云 - 蓝色系
    CollectionCover(
      name: '天空蓝',
      gradientColors: [Color(0xFF64B5F6), Color(0xFF1565C0)],
      icon: Icons.wb_cloudy,
    ),
    // 金秋时节 - 橙色系
    CollectionCover(
      name: '秋叶黄',
      gradientColors: [Color(0xFFFFB74D), Color(0xFFEF6C00)],
      icon: Icons.eco,
    ),
    // 紫气东来 - 紫色系
    CollectionCover(
      name: '暮山紫',
      gradientColors: [Color(0xFFBA68C8), Color(0xFF6A1B9A)],
      icon: Icons.nightlight_round,
    ),
    // 水墨丹青 - 灰色系
    CollectionCover(
      name: '水墨灰',
      gradientColors: [Color(0xFF90A4AE), Color(0xFF455A64)],
      icon: Icons.brush,
    ),
    // 桃红柳绿 - 粉色系
    CollectionCover(
      name: '桃花粉',
      gradientColors: [Color(0xFFF06292), Color(0xFFC2185B)],
      icon: Icons.local_florist,
    ),
    // 碧海青天 - 青色系
    CollectionCover(
      name: '碧海青',
      gradientColors: [Color(0xFF4DB6AC), Color(0xFF00695C)],
      icon: Icons.waves,
    ),
  ];

  /// 随机获取一个预设封面
  static CollectionCover getRandom() {
    final random = Random();
    return presets[random.nextInt(presets.length)];
  }

  /// 根据索引获取预设封面
  static CollectionCover getByIndex(int index) {
    return presets[index % presets.length];
  }

  /// 获取预设封面数量
  static int get count => presets.length;
}
