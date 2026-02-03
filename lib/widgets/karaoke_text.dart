import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/tts_result.dart';

/// 卡拉 OK 风格文本组件 - 逐字高亮
/// 
/// 根据时间戳和当前播放位置，高亮显示正在朗读的文字
class KaraokeText extends StatelessWidget {
  /// 完整文本（纯净版诗词）
  final String text;
  
  /// 字级别时间戳列表
  final List<TimestampItem> timestamps;
  
  /// 当前播放位置
  final Duration currentPosition;
  
  /// 正常文字颜色
  final Color? normalColor;
  
  /// 高亮文字颜色（默认朱砂红）
  final Color? highlightColor;
  
  /// 字体大小
  final double fontSize;
  
  /// 行高
  final double height;
  
  /// 字间距
  final double letterSpacing;
  
  /// 字体
  final String? fontFamily;
  
  /// 对齐方式
  final TextAlign textAlign;

  const KaraokeText({
    super.key,
    required this.text,
    required this.timestamps,
    required this.currentPosition,
    this.normalColor,
    this.highlightColor,
    this.fontSize = 18,
    this.height = 2.4,
    this.letterSpacing = 1.5,
    this.fontFamily,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final normalStyle = TextStyle(
      color: normalColor ?? const Color(UIConstants.textPrimaryColor),
      fontFamily: fontFamily ?? FontConstants.chineseSerif,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );
    
    final highlightStyle = TextStyle(
      color: highlightColor ?? const Color(UIConstants.accentColor),
      fontFamily: fontFamily ?? FontConstants.chineseSerif,
      fontSize: fontSize * 1.15,
      height: height / 1.15,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.bold,
    );

    // 当前播放位置（毫秒）
    final currentMs = currentPosition.inMilliseconds;
    
    // 提取所有中文字符（去掉标点）用于索引匹配
    final chars = text.split('');
    final chineseChars = <String>[];
    final isChineseFlags = <bool>[];
    
    for (final char in chars) {
      final isChinese = _isChineseChar(char);
      isChineseFlags.add(isChinese);
      if (isChinese) {
        chineseChars.add(char);
      }
    }
    
    // 找到当前激活的字索引（基于时间戳列表）
    int activeTimestampIndex = -1;
    for (int i = 0; i < timestamps.length; i++) {
      final ts = timestamps[i];
      if (currentMs >= ts.startTime && currentMs < ts.endTime) {
        activeTimestampIndex = i;
        break;
      }
    }
    
    // 如果没有匹配到当前时间，检查是否已经超过最后一个字
    if (activeTimestampIndex == -1 && timestamps.isNotEmpty) {
      if (currentMs >= timestamps.last.endTime) {
        activeTimestampIndex = timestamps.length; // 全部已读完
      }
    }

    // 构建 TextSpan 列表
    final spans = <TextSpan>[];
    int chineseIndex = 0;
    
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final isChinese = isChineseFlags[i];
      
      bool isActive = false;
      if (isChinese && chineseIndex < timestamps.length) {
        // 检查当前字符是否对应激活的时间戳
        isActive = chineseIndex == activeTimestampIndex;
        chineseIndex++;
      } else if (!isChinese && chineseIndex > 0) {
        // 标点符号跟随前一个字的状态
        isActive = (chineseIndex - 1) == activeTimestampIndex;
      }
      
      spans.add(TextSpan(
        text: char,
        style: isActive ? highlightStyle : normalStyle,
      ));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
  
  /// 判断是否为中文字符
  bool _isChineseChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    // 中文范围：\u4e00-\u9fa5
    return code >= 0x4e00 && code <= 0x9fa5;
  }
}

/// 平滑过渡版本的卡拉 OK 文本
class SmoothKaraokeText extends StatelessWidget {
  final String text;
  final List<TimestampItem> timestamps;
  final Duration currentPosition;
  final Color? normalColor;
  final Color? highlightColor;
  final double fontSize;
  final double height;
  final double letterSpacing;
  final String? fontFamily;
  final TextAlign textAlign;

  const SmoothKaraokeText({
    super.key,
    required this.text,
    required this.timestamps,
    required this.currentPosition,
    this.normalColor,
    this.highlightColor,
    this.fontSize = 18,
    this.height = 2.4,
    this.letterSpacing = 1.5,
    this.fontFamily,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final currentMs = currentPosition.inMilliseconds;
    
    // 提取所有中文字符
    final chars = text.split('');
    final chineseIndices = <int>[]; // 记录中文字符在chars中的索引
    
    for (int i = 0; i < chars.length; i++) {
      if (_isChineseChar(chars[i])) {
        chineseIndices.add(i);
      }
    }
    
    // 找到当前激活的时间戳索引
    int activeTsIndex = -1;
    for (int i = 0; i < timestamps.length; i++) {
      final ts = timestamps[i];
      if (currentMs >= ts.startTime && currentMs < ts.endTime) {
        activeTsIndex = i;
        break;
      }
    }
    
    // 如果已经读完所有字
    if (activeTsIndex == -1 && timestamps.isNotEmpty && currentMs >= timestamps.last.endTime) {
      activeTsIndex = timestamps.length;
    }
    
    // 构建TextSpan
    final spans = <TextSpan>[];
    int tsIndex = 0; // 时间戳索引
    
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final isChinese = _isChineseChar(char);
      
      bool isActive = false;
      bool wasActive = false;
      
      if (isChinese) {
        if (tsIndex < timestamps.length) {
          isActive = tsIndex == activeTsIndex;
          wasActive = tsIndex < activeTsIndex;
          tsIndex++;
        } else {
          // 时间戳用完了，视为已读完
          wasActive = true;
        }
      } else {
        // 标点符号 - 跟随前一个中文字符
        final prevTsIndex = tsIndex - 1;
        isActive = prevTsIndex >= 0 && prevTsIndex == activeTsIndex;
        wasActive = prevTsIndex >= 0 && prevTsIndex < activeTsIndex;
      }
      
      // 颜色插值：已读字 -> 当前字 -> 未读字
      Color color;
      if (isActive) {
        color = highlightColor ?? const Color(UIConstants.accentColor);
      } else if (wasActive) {
        // 已读的字可以用稍微淡一点的颜色，或者用原色
        color = normalColor ?? const Color(UIConstants.textPrimaryColor);
      } else {
        color = normalColor ?? const Color(UIConstants.textPrimaryColor);
      }
      
      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontFamily: fontFamily ?? FontConstants.chineseSerif,
          fontSize: isActive ? fontSize * 1.1 : fontSize,
          height: isActive ? height / 1.1 : height,
          letterSpacing: letterSpacing,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }
    
    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
  
  bool _isChineseChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 0x4e00 && code <= 0x9fa5;
  }
}

/// 简化版本 - 仅高亮当前字，无其他特效
class SimpleKaraokeText extends StatelessWidget {
  final String text;
  final List<TimestampItem> timestamps;
  final Duration currentPosition;
  final Color? normalColor;
  final Color? highlightColor;
  final double fontSize;
  final double height;
  final double letterSpacing;
  final String? fontFamily;
  final TextAlign textAlign;

  const SimpleKaraokeText({
    super.key,
    required this.text,
    required this.timestamps,
    required this.currentPosition,
    this.normalColor,
    this.highlightColor,
    this.fontSize = 18,
    this.height = 2.4,
    this.letterSpacing = 1.5,
    this.fontFamily,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final currentMs = currentPosition.inMilliseconds;
    
    // 找到当前激活的时间戳
    int activeIndex = -1;
    for (int i = 0; i < timestamps.length; i++) {
      if (currentMs >= timestamps[i].startTime && currentMs < timestamps[i].endTime) {
        activeIndex = i;
        break;
      }
    }
    
    // 过滤出中文字符及其映射
    final chars = text.split('');
    final chineseCharIndices = <int>[];
    for (int i = 0; i < chars.length; i++) {
      if (_isChineseChar(chars[i])) {
        chineseCharIndices.add(i);
      }
    }
    
    // 构建文本片段
    final spans = <TextSpan>[];
    int chineseIdx = 0;
    
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final isChinese = _isChineseChar(char);
      
      bool isHighlight = false;
      if (isChinese && chineseIdx < chineseCharIndices.length) {
        // 使用映射找到对应的时间戳索引
        final mapIdx = chineseCharIndices.indexOf(i);
        if (mapIdx >= 0) {
          isHighlight = mapIdx == activeIndex;
        }
        chineseIdx++;
      } else if (!isChinese && chineseIdx > 0) {
        // 标点跟随前一个
        isHighlight = (chineseIdx - 1) == activeIndex;
      }
      
      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          color: isHighlight 
              ? (highlightColor ?? const Color(UIConstants.accentColor))
              : (normalColor ?? const Color(UIConstants.textPrimaryColor)),
          fontFamily: fontFamily ?? FontConstants.chineseSerif,
          fontSize: isHighlight ? fontSize * 1.15 : fontSize,
          height: height,
          letterSpacing: letterSpacing,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }
    
    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
  
  bool _isChineseChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 0x4e00 && code <= 0x9fa5;
  }
}
