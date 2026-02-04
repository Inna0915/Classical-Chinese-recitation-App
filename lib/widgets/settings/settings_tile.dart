import 'package:flutter/material.dart';

/// 设置项组件 (Cherry Studio / iOS 风格)
/// 
/// 特性：
/// - 支持左侧图标
/// - 支持多种右侧尾部：箭头、开关、文本标签、徽章
/// - 支持副标题
/// - 点击反馈
class SettingsTile extends StatelessWidget {
  /// 左侧图标
  final IconData? icon;
  
  /// 图标背景色
  final Color? iconBackgroundColor;
  
  /// 图标颜色
  final Color? iconColor;
  
  /// 主标题
  final String title;
  
  /// 副标题（可选）
  final String? subtitle;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 右侧尾部类型
  final SettingsTileTrailing trailing;
  
  /// 开关值（当 trailing 为 switch 时使用）
  final bool? switchValue;
  
  /// 开关变化回调
  final ValueChanged<bool>? onSwitchChanged;
  
  /// 右侧文本标签（当 trailing 为 text 时使用）
  final String? trailingText;
  
  /// 右侧徽章文本（当 trailing 为 badge 时使用）
  final String? badgeText;
  
  /// 徽章颜色
  final Color? badgeColor;
  
  /// 是否启用
  final bool enabled;
  
  /// 自定义右侧组件（当 trailing 为 custom 时使用）
  final Widget? customTrailing;
  
  /// 自定义副标题组件（可选，优先级高于 subtitle）
  final Widget? subtitleWidget;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconBackgroundColor,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing = SettingsTileTrailing.arrow,
    this.switchValue,
    this.onSwitchChanged,
    this.trailingText,
    this.badgeText,
    this.badgeColor,
    this.enabled = true,
    this.customTrailing,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? Colors.grey[800];
    final effectiveSubtitleColor = Colors.grey[500];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: Colors.grey[100],
        highlightColor: Colors.grey[50],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 左侧图标
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ?? Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: effectiveIconColor,
                  ),
                )
              else
                const SizedBox(width: 0),
              
              // 标题区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: enabled 
                          ? Colors.grey[900] 
                          : Colors.grey[400],
                        height: 1.2,
                      ),
                    ),
                    if (subtitleWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: subtitleWidget!,
                      )
                    else if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: enabled 
                              ? effectiveSubtitleColor 
                              : Colors.grey[300],
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 右侧尾部
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建右侧尾部
  Widget _buildTrailing(BuildContext context) {
    switch (trailing) {
      case SettingsTileTrailing.arrow:
        return Icon(
          Icons.chevron_right,
          size: 20,
          color: Colors.grey[400],
        );
        
      case SettingsTileTrailing.switch_:
        return _buildSwitch();
        
      case SettingsTileTrailing.text:
        return Text(
          trailingText ?? '',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        );
        
      case SettingsTileTrailing.badge:
        return _buildBadge();
        
      case SettingsTileTrailing.none:
        return const SizedBox.shrink();
        
      case SettingsTileTrailing.custom:
        return customTrailing ?? const SizedBox.shrink();
    }
  }

  /// 构建 Switch
  Widget _buildSwitch() {
    return SizedBox(
      height: 28,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: switchValue ?? false,
          onChanged: enabled ? onSwitchChanged : null,
          activeColor: const Color(0xFFC93836), // 朱砂红
          activeTrackColor: const Color(0xFFC93836).withOpacity(0.3),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
        ),
      ),
    );
  }

  /// 构建徽章
  Widget _buildBadge() {
    final bgColor = badgeColor ?? const Color(0xFF34C759); // 默认绿色
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText ?? '',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: bgColor,
        ),
      ),
    );
  }
}

/// 设置项尾部类型
enum SettingsTileTrailing {
  /// 箭头 >
  arrow,
  
  /// 开关
  switch_,
  
  /// 文本标签
  text,
  
  /// 徽章（如"已连接"）
  badge,
  
  /// 无
  none,
  
  /// 自定义组件
  custom,
}
