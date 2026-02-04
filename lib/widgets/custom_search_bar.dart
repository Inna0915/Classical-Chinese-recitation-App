import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';

/// 通用搜索栏组件
/// 
/// 特性：
/// - 圆角搜索框，浅灰背景
/// - 实时搜索输入
/// - 清除按钮
/// - Cherry Studio 风格
class CustomSearchBar extends StatelessWidget {
  /// 搜索控制器
  final TextEditingController? controller;
  
  /// 搜索文本变化回调
  final ValueChanged<String>? onChanged;
  
  /// 搜索提交回调
  final ValueChanged<String>? onSubmitted;
  
  /// 提示文字
  final String hintText;
  
  /// 是否自动聚焦
  final bool autofocus;
  
  /// 外边距
  final EdgeInsetsGeometry margin;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '搜索诗词...',
    this.autofocus = false,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        style: TextStyle(
          fontSize: 15,
          color: context.textPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 15,
            color: context.textSecondaryColor.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.textSecondaryColor.withValues(alpha: 0.6),
            size: 22,
          ),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? Obx(() {
                  // 使用 Obx 监听文本变化
                  final hasText = controller!.text.isNotEmpty;
                  if (!hasText) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      controller!.clear();
                      onChanged?.call('');
                    },
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.textSecondaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: context.textSecondaryColor,
                        size: 14,
                      ),
                    ),
                  );
                })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// 带状态管理的搜索栏组件
class SearchBarWithController extends StatefulWidget {
  /// 搜索文本变化回调（已 debounce）
  final ValueChanged<String> onSearch;
  
  /// 提示文字
  final String hintText;
  
  /// 外边距
  final EdgeInsetsGeometry margin;
  
  /// debounce 延迟
  final Duration debounce;

  const SearchBarWithController({
    super.key,
    required this.onSearch,
    this.hintText = '搜索诗词...',
    this.margin = const EdgeInsets.all(16),
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<SearchBarWithController> createState() => _SearchBarWithControllerState();
}

class _SearchBarWithControllerState extends State<SearchBarWithController> {
  late TextEditingController _controller;
  DateTime _lastSearchTime = DateTime.now();
  String _pendingSearch = '';
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final now = DateTime.now();
    _pendingSearch = _controller.text;
    _lastSearchTime = now;

    if (!_isDebouncing) {
      _isDebouncing = true;
      _startDebounce(now);
    }
    
    // 触发 UI 刷新以显示/隐藏清除按钮
    setState(() {});
  }

  void _startDebounce(DateTime triggerTime) {
    Future.delayed(widget.debounce, () {
      if (!mounted) return;
      
      // 检查是否有更新的搜索请求
      if (_lastSearchTime == triggerTime) {
        // 这是最后一次搜索，执行回调
        widget.onSearch(_pendingSearch);
        _isDebouncing = false;
      } else {
        // 有新的搜索请求，继续等待
        _startDebounce(_lastSearchTime);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomSearchBar(
      controller: _controller,
      onChanged: (_) {}, // 空实现，监听在 _onTextChanged 中处理
      onSubmitted: (value) {
        _pendingSearch = value;
        _lastSearchTime = DateTime.now();
        widget.onSearch(value);
      },
      hintText: widget.hintText,
      margin: widget.margin,
    );
  }
}
