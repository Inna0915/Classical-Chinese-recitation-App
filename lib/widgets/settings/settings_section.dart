import 'package:flutter/material.dart';

/// 设置分组卡片组件 (Cherry Studio / iOS 风格)
/// 
/// 特性：
/// - 圆角卡片容器
/// - 支持顶部标题
/// - 支持自定义子项列表
class SettingsSection extends StatelessWidget {
  /// 分组标题（可选，显示在卡片上方）
  final String? title;
  
  /// 子项列表
  final List<Widget> children;
  
  /// 卡片外边距
  final EdgeInsetsGeometry margin;
  
  /// 卡片内边距
  final EdgeInsetsGeometry padding;
  
  /// 卡片圆角
  final double borderRadius;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(0),
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分组标题
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
          ),
        
        // 卡片容器
        Container(
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildChildrenWithDividers(),
            ),
          ),
        ),
      ],
    );
  }

  /// 为子项添加分割线（最后一项除外）
  List<Widget> _buildChildrenWithDividers() {
    final result = <Widget>[];
    
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      
      // 不是最后一项，添加分割线
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56, // 与 Leading 图标对齐
            color: Colors.grey[200],
          ),
        );
      }
    }
    
    return result;
  }
}
