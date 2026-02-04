import 'package:flutter/material.dart';
import '../../models/config/llm_config.dart';

/// 服务商 Logo 组件
/// 
/// 特性：
/// - 优先加载本地图片 assets/logos/{type}.png
/// - 图片加载失败时显示品牌色背景的缩写文字
/// - 支持自定义大小
class ProviderLogo extends StatelessWidget {
  final LlmProviderType provider;
  final double size;
  final double borderRadius;

  const ProviderLogo({
    super.key,
    required this.provider,
    this.size = 40,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          provider.logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 图片加载失败时显示品牌色背景 + 缩写文字
            return _buildFallbackLogo();
          },
        ),
      ),
    );
  }

  /// 备用 Logo（品牌色背景 + 缩写文字）
  Widget _buildFallbackLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(provider.brandColor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          provider.logoInitial,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: Color(provider.brandColor),
          ),
        ),
      ),
    );
  }
}

/// 小型 Logo 徽章（用于列表项左侧）
class ProviderLogoBadge extends StatelessWidget {
  final LlmProviderType provider;
  final double size;

  const ProviderLogoBadge({
    super.key,
    required this.provider,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderLogo(
      provider: provider,
      size: size,
      borderRadius: 10,
    );
  }
}

/// 状态徽章（已开启/未配置）
class StatusBadge extends StatelessWidget {
  final bool isEnabled;
  final String? customText;

  const StatusBadge({
    super.key,
    required this.isEnabled,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final text = customText ?? (isEnabled ? '已开启' : '未配置');
    final bgColor = isEnabled 
        ? const Color(0xFFE8F5E9) // 淡绿色背景
        : const Color(0xFFF5F5F5); // 灰色背景
    final textColor = isEnabled 
        ? const Color(0xFF4CAF50) // 绿色文字
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
