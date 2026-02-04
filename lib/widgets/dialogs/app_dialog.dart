import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';

/// 通用应用对话框组件
/// 
/// 特性：
/// - 圆角 16.0
/// - 背景色跟随主题（白/黑）
/// - 居中的标题和内容
/// - 底部居中排列的按钮
class AppDialog extends StatelessWidget {
  /// 对话框标题
  final String title;
  
  /// 对话框内容
  final Widget content;
  
  /// 确认按钮文字
  final String? confirmText;
  
  /// 取消按钮文字
  final String? cancelText;
  
  /// 确认按钮回调
  final VoidCallback? onConfirm;
  
  /// 取消按钮回调
  final VoidCallback? onCancel;
  
  /// 是否显示取消按钮
  final bool showCancel;
  
  /// 是否显示确认按钮
  final bool showConfirm;
  
  /// 确认按钮颜色
  final Color? confirmColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
    this.showConfirm = true,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DefaultTextStyle(
          style: TextStyle(color: context.textSecondaryColor),
          child: content,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (showCancel)
          TextButton(
            onPressed: onCancel ?? () => Get.back(),
            child: Text(
              cancelText ?? '取消',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
        if (showConfirm)
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? context.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText ?? '确定'),
          ),
      ],
    );
  }

  /// 显示对话框
  static Future<T?> show<T>({
    required String title,
    required Widget content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancel = true,
    bool showConfirm = true,
    Color? confirmColor,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      AppDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showCancel: showCancel,
        showConfirm: showConfirm,
        confirmColor: confirmColor,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// 显示确认对话框
  static Future<bool?> confirm({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    return show<bool>(
      title: title,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
      confirmText: confirmText ?? '确定',
      cancelText: cancelText ?? '取消',
      confirmColor: confirmColor,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );
  }

  /// 显示信息对话框（只有一个确定按钮）
  static Future<void> info({
    required String title,
    required String message,
    String? confirmText,
  }) {
    return show(
      title: title,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
      confirmText: confirmText ?? '确定',
      showCancel: false,
      onConfirm: () => Get.back(),
    );
  }

  /// 显示成功对话框
  static Future<void> success({
    required String title,
    String? message,
    String? confirmText,
  }) {
    return show(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4CAF50),
            size: 48,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
      confirmText: confirmText ?? '确定',
      showCancel: false,
      onConfirm: () => Get.back(),
      confirmColor: const Color(0xFF4CAF50),
    );
  }
}
