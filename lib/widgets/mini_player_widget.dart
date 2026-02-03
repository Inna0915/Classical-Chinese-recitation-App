import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../pages/poem_detail_page.dart';

/// 迷你播放控制条 - 悬浮在底部导航栏上方
/// 参考 QQ 音乐设计风格，古风元素适配
class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Obx(() {
      final poem = controller.currentPoem.value;
      final isPlaying = controller.playbackState.value == PlaybackState.playing;
      final isLoading = controller.playbackState.value == PlaybackState.loading;
      
      // 如果没有播放任务，隐藏
      if (poem == null) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: const Color(UIConstants.dividerColor),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 左侧：意境图/旋转唱片
            _buildLeadingIcon(poem, isPlaying),
            
            // 中间：诗词信息
            Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => const PoemDetailPage()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 诗词标题
                      Text(
                        poem.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(UIConstants.textPrimaryColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 作者信息
                      Text(
                        '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(UIConstants.textSecondaryColor),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 右侧：控制按钮
            _buildControlButtons(poem, isPlaying, isLoading, controller),
            
            const SizedBox(width: 8),
          ],
        ),
      );
    });
  }

  /// 左侧意境图/旋转图标
  Widget _buildLeadingIcon(Poem poem, bool isPlaying) {
    return GestureDetector(
      onTap: () => Get.to(() => const PoemDetailPage()),
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(left: 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外圈装饰（模拟黑胶唱片）
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(UIConstants.accentColor).withOpacity(0.1),
                border: Border.all(
                  color: const Color(UIConstants.accentColor).withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            // 旋转的内容
            AnimatedContainer(
              duration: const Duration(seconds: 10),
              curve: Curves.linear,
              child: isPlaying
                  ? _RotatingPoemIcon(poem: poem)
                  : _StaticPoemIcon(poem: poem),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧控制按钮组
  Widget _buildControlButtons(
    Poem poem,
    bool isPlaying,
    bool isLoading,
    PoemController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮
        Obx(() {
          final isFavorite = controller.isFavorite(poem.id);
          return IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? const Color(UIConstants.accentColor)
                  : const Color(UIConstants.textSecondaryColor),
              size: 22,
            ),
            onPressed: () => controller.toggleFavorite(poem.id),
          );
        }),
        
        // 播放/暂停按钮（带进度环）
        GestureDetector(
          onTap: isLoading ? null : () => controller.togglePlay(),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 进度环
                if (isPlaying || isLoading)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: isLoading
                          ? controller.downloadProgress.value
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(UIConstants.accentColor),
                      ),
                      backgroundColor: const Color(UIConstants.dividerColor),
                    ),
                  ),
                // 播放按钮
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(UIConstants.accentColor),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 播放列表按钮
        IconButton(
          icon: const Icon(
            Icons.queue_music,
            color: Color(UIConstants.textSecondaryColor),
            size: 24,
          ),
          onPressed: () => _showPlaylistBottomSheet(controller),
        ),
      ],
    );
  }

  /// 显示播放列表 BottomSheet
  void _showPlaylistBottomSheet(PoemController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(UIConstants.dividerColor),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.queue_music,
                      color: Color(UIConstants.accentColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '当前播放',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => controller.stop(),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('清空'),
                    ),
                  ],
                ),
              ),
              
              // 当前播放的诗词
              if (controller.currentPoem.value != null)
                _buildPlaylistItem(
                  controller.currentPoem.value!,
                  isPlaying: true,
                  onTap: () => Get.back(),
                ),
              
              const Divider(height: 1),
              
              // 提示：暂无播放列表功能（当前只支持单首播放）
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text(
                  '当前仅支持单首播放\n连续播放功能即将上线',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(UIConstants.textSecondaryColor),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 播放列表项
  Widget _buildPlaylistItem(
    Poem poem, {
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(UIConstants.accentColor).withOpacity(0.1)
              : const Color(UIConstants.backgroundColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isPlaying
              ? const Icon(
                  Icons.volume_up,
                  color: Color(UIConstants.accentColor),
                  size: 20,
                )
              : const Icon(
                  Icons.music_note,
                  color: Color(UIConstants.textSecondaryColor),
                  size: 20,
                ),
        ),
      ),
      title: Text(
        poem.title,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying
              ? const Color(UIConstants.accentColor)
              : const Color(UIConstants.textPrimaryColor),
        ),
      ),
      subtitle: Text(
        '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(UIConstants.textSecondaryColor),
        ),
      ),
      trailing: isPlaying
          ? const Icon(
              Icons.equalizer,
              color: Color(UIConstants.accentColor),
              size: 20,
            )
          : null,
      onTap: onTap,
      tileColor: isPlaying
          ? const Color(UIConstants.accentColor).withOpacity(0.05)
          : null,
    );
  }
}

/// 静态诗词图标
class _StaticPoemIcon extends StatelessWidget {
  final Poem poem;

  const _StaticPoemIcon({required this.poem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(UIConstants.accentColor).withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          poem.title.isNotEmpty ? poem.title[0] : '诗',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(UIConstants.accentColor),
            fontFamily: FontConstants.chineseSerif,
          ),
        ),
      ),
    );
  }
}

/// 旋转的诗词图标（播放时）
class _RotatingPoemIcon extends StatefulWidget {
  final Poem poem;

  const _RotatingPoemIcon({required this.poem});

  @override
  State<_RotatingPoemIcon> createState() => _RotatingPoemIconState();
}

class _RotatingPoemIconState extends State<_RotatingPoemIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(UIConstants.accentColor).withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            widget.poem.title.isNotEmpty ? widget.poem.title[0] : '诗',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(UIConstants.accentColor),
              fontFamily: FontConstants.chineseSerif,
            ),
          ),
        ),
      ),
    );
  }
}
