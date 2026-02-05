import 'package:flutter/material.dart';

/// 根据背景色计算对比文字颜色
/// 亮度 > 0.5 返回黑色，否则返回白色
Color getContrastingTextColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5 
      ? Colors.black 
      : Colors.white;
}

/// 获取半透明的对比文字颜色（用于次要文字）
Color getContrastingTextColorWithOpacity(Color backgroundColor, {double opacity = 0.7}) {
  final baseColor = getContrastingTextColor(backgroundColor);
  return baseColor.withAlpha((255 * opacity).round());
}

/// 判断颜色是否为浅色
bool isLightColor(Color color) {
  return color.computeLuminance() > 0.5;
}

/// 判断颜色是否为深色
bool isDarkColor(Color color) {
  return color.computeLuminance() <= 0.5;
}

/// 将颜色转换为 Hex 字符串
String colorToHex(Color color, {bool withAlpha = false}) {
  final alpha = color.a.round().toRadixString(16).padLeft(2, '0');
  final red = color.r.round().toRadixString(16).padLeft(2, '0');
  final green = color.g.round().toRadixString(16).padLeft(2, '0');
  final blue = color.b.round().toRadixString(16).padLeft(2, '0');
  
  if (withAlpha) {
    return '#$alpha$red$green$blue'.toUpperCase();
  }
  return '#$red$green$blue'.toUpperCase();
}

/// 混合两种颜色
Color blendColors(Color color1, Color color2, double ratio) {
  assert(ratio >= 0 && ratio <= 1);
  return Color.lerp(color1, color2, ratio)!;
}
