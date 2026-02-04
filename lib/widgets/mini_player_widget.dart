import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/player_controller.dart';
import '../controllers/poem_controller.dart';
import '../models/enums.dart';
import '../models/poem.dart';
import '../pages/poem_detail_page.dart';

/// 迷你播放控制条 - 悬浮在底部导航栏上方
/// 参考 QQ 音乐设计风格，古风元素适配
class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.to;

    return Obx(() {
      final poem = controller.currentPoemRx.value;
      final isPlaying = controller.playbackState.value == PlaybackState.playing;
      final isLoading = controller.playbackState.value == PlaybackState.loading;
      
      // 如果没有播放任务，隐藏
      if (poem == null) {
        return const SizedBox.shrink();
      }

      // 手势检测：左右滑动切换上一首/下一首
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          // 左滑 -> 下一首，右滑 -> 上一首
          if (details.primaryVelocity! < -100) {
            controller.playNext();
          } else if (details.primaryVelocity! > 100) {
            controller.playPrevious();
          }
        },
        child: Container(
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
              // 左侧：意境图/旋转图标
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
            // 外圈装饰
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
            isPlaying
                ? _RotatingPoemIcon(poem: poem)
                : _StaticPoemIcon(poem: poem),
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
    PlayerController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮
        _FavoriteButton(poem: poem),
        
        // 上一首按钮
        IconButton(
          icon: const Icon(
            Icons.skip_previous,
            color: Color(UIConstants.textSecondaryColor),
            size: 24,
          ),
          onPressed: () => controller.playPrevious(),
        ),

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

        // 下一首按钮
        IconButton(
          icon: const Icon(
            Icons.skip_next,
            color: Color(UIConstants.textSecondaryColor),
            size: 24,
          ),
          onPressed: () => controller.playNext(),
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
  void _showPlaylistBottomSheet(PlayerController controller) {
    Get.bottomSheet(
      const PlaylistBottomSheet(),
      isScrollControlled: true,
    );
  }
}

/// 播放列表 BottomSheet
class PlaylistBottomSheet extends StatelessWidget {
  const PlaylistBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.to;

    return Container(
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
            // 拖动指示条
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(UIConstants.dividerColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Expanded(
                    child: Obx(() => Text(
                      '当前播放 (${controller.playlist.length}首)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ),
                  
                  // 播放模式切换按钮
                  _buildPlayModeButton(controller),
                  
                  const SizedBox(width: 8),
                  
                  // 清空按钮
                  TextButton.icon(
                    onPressed: () {
                      controller.clearPlaylist();
                      Get.back();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清空'),
                  ),
                ],
              ),
            ),
            
            // 播放列表
            Flexible(
              child: Obx(() {
                if (controller.playlist.isEmpty) {
                  return const Center(
                    child: Text(
                      '播放列表为空',
                      style: TextStyle(
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.playlist.length,
                  itemBuilder: (context, index) {
                    final poem = controller.playlist[index];
                    final isCurrent = index == controller.currentIndex.value;
                    final isPlaying = isCurrent && 
                        controller.playbackState.value == PlaybackState.playing;
                    
                    return _PlaylistItem(
                      poem: poem,
                      index: index,
                      isCurrent: isCurrent,
                      isPlaying: isPlaying,
                      onTap: () {
                        controller.currentIndex.value = index;
                        controller.playGroup(controller.playlist, index);
                      },
                      onRemove: () => controller.removeFromPlaylist(index),
                    );
                  },
                );
              }),
            ),
            
            // 关闭按钮
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(UIConstants.dividerColor),
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(UIConstants.backgroundColor),
                  foregroundColor: const Color(UIConstants.textPrimaryColor),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 播放模式切换按钮
  Widget _buildPlayModeButton(PlayerController controller) {
    return Obx(() {
      final mode = controller.playMode.value;
      return TextButton.icon(
        onPressed: () => controller.togglePlayMode(),
        icon: Icon(mode.icon, size: 18),
        label: Text(mode.displayName),
        style: TextButton.styleFrom(
          foregroundColor: const Color(UIConstants.textSecondaryColor),
        ),
      );
    });
  }
}

/// 播放列表项
class _PlaylistItem extends StatelessWidget {
  final Poem poem;
  final int index;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistItem({
    required this.poem,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(UIConstants.accentColor).withOpacity(0.1)
              : const Color(UIConstants.backgroundColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isPlaying
              ? const _PlayingIndicator()
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent
                        ? const Color(UIConstants.accentColor)
                        : const Color(UIConstants.textSecondaryColor),
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
        ),
      ),
      title: Text(
        poem.title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent
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
      trailing: IconButton(
        icon: const Icon(
          Icons.close,
          size: 18,
          color: Color(UIConstants.textSecondaryColor),
        ),
        onPressed: onRemove,
      ),
      onTap: onTap,
      tileColor: isCurrent
          ? const Color(UIConstants.accentColor).withOpacity(0.05)
          : null,
    );
  }
}

/// 正在播放指示器（波纹动画）
class _PlayingIndicator extends StatelessWidget {
  const _PlayingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBar(0.4),
        const SizedBox(width: 2),
        _buildBar(0.7),
        const SizedBox(width: 2),
        _buildBar(0.5),
      ],
    );
  }

  Widget _buildBar(double heightFactor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 3,
      height: 16 * heightFactor,
      decoration: BoxDecoration(
        color: const Color(UIConstants.accentColor),
        borderRadius: BorderRadius.circular(1.5),
      ),
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

/// 收藏按钮
class _FavoriteButton extends StatelessWidget {
  final Poem poem;

  const _FavoriteButton({required this.poem});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PoemController>();
    
    return Obx(() {
      final isFavorite = controller.isFavorite(poem.id!);
      return IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : const Color(UIConstants.textSecondaryColor),
          size: 22,
        ),
        onPressed: () => controller.toggleFavorite(poem.id!),
      );
    });
  }
}
