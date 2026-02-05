import 'package:flutter/material.dart';

/// 季节枚举
enum AppSeason { spring, summer, autumn, winter }

/// 扩展季节枚举，获取显示名称
extension AppSeasonExtension on AppSeason {
  String get displayName {
    switch (this) {
      case AppSeason.spring:
        return '春生';
      case AppSeason.summer:
        return '夏长';
      case AppSeason.autumn:
        return '秋收';
      case AppSeason.winter:
        return '冬藏';
    }
  }

  String get subtitle {
    switch (this) {
      case AppSeason.spring:
        return 'Spring';
      case AppSeason.summer:
        return 'Summer';
      case AppSeason.autumn:
        return 'Autumn';
      case AppSeason.winter:
        return 'Winter';
    }
  }
}

/// 传统颜色模型
class TraditionalColor {
  final String name; // 颜色名 (e.g., "黄白游")
  final String hex; // Hex 字符串 (e.g., "#FFF799")
  final Color color; // Color 对象

  TraditionalColor(this.name, this.hex) : color = _hexToColor(hex);

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex";
    }
    return Color(int.parse(hex, radix: 16));
  }
}

/// 节气模型
class SolarTerm {
  final String name; // 节气名 (e.g., "立春")
  final String pinyin; // 拼音 (e.g., "Lì Chūn")
  final List<TraditionalColor> colors;

  SolarTerm({
    required this.name,
    required this.pinyin,
    required this.colors,
  });
}

/// 季节数据模型
class SeasonData {
  final AppSeason season;
  final String name; // 春生, 夏长, 秋收, 冬藏
  final List<SolarTerm> terms;

  SeasonData(this.season, this.name, this.terms);
}
