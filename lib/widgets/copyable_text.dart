import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 可复制文本组件
class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const CopyableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showCopyDialog(context, text),
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }

  void _showCopyDialog(BuildContext context, String text) {
    Get.dialog(
      AlertDialog(
        title: const Text('复制文本'),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Get.back();
              Get.snackbar(
                '已复制',
                '文本已复制到剪贴板',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('复制全部'),
          ),
        ],
      ),
    );
  }
}

/// 可复制的错误信息显示组件
class CopyableErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const CopyableErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('关闭'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            Get.back();
            Get.snackbar(
              '已复制',
              '错误信息已复制到剪贴板',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制'),
        ),
      ],
    );
  }
}

/// 显示可复制的成功对话框
void showCopyableSuccessDialog(String title, String message) {
  Get.dialog(
    AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('关闭'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            Get.back();
            Get.snackbar(
              '已复制',
              '信息已复制到剪贴板',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制'),
        ),
      ],
    ),
  );
}

/// 显示可复制的错误对话框
void showCopyableErrorDialog(String title, String message) {
  Get.dialog(
    CopyableErrorDialog(
      title: title,
      message: message,
    ),
  );
}
