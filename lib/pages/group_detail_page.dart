import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/player_controller.dart';
import '../controllers/poem_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';


/// 分组详情页 - 展示分组内所有诗词，支持播放全部
class GroupDetailPage extends StatelessWidget {
  final PoemGroup group;
  final List<Poem> poems;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.poems,
  });

  @override
  Widget build(BuildContext context) {
    final poemController = PoemController.to;
    final playerController = Get.find<PlayerController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          group.name,
          style: const TextStyle(
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // 播放全部按钮
          if (poems.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(UIConstants.defaultPadding),
              child: ElevatedButton.icon(
                onPressed: () => playerController.playGroup(poems, 0),
                icon: const Icon(Icons.play_arrow),
                label: Text('播放全部 (${poems.length}首)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                  ),
                ),
              ),
            ),

          // 诗词列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: UIConstants.defaultPadding,
                right: UIConstants.defaultPadding,
                bottom: 80, // 防止被MiniPlayer遮挡
              ),
              itemCount: poems.length,
              itemBuilder: (context, index) {
                final poem = poems[index];
                return _PoemListItem(
                  poem: poem,
                  index: index,
                  onTap: () {
                    // 点击从当前位置开始播放整个列表
                    playerController.playGroup(poems, index);
                    poemController.selectPoem(poem);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 诗词列表项
class _PoemListItem extends StatelessWidget {
  final Poem poem;
  final int index;
  final VoidCallback onTap;

  const _PoemListItem({
    required this.poem,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Obx(() {
      // 检查是否正在播放这首诗词
      final isCurrentPlaying = playerController.currentPoem?.id == poem.id &&
          playerController.playbackState.value == PlaybackState.playing;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          border: isCurrentPlaying
              ? Border.all(color: context.primaryColor, width: 1.5)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCurrentPlaying
                  ? context.primaryColor.withValues(alpha: 0.1)
                  : context.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isCurrentPlaying
                  ? Icon(
                      Icons.volume_up,
                      color: context.primaryColor,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          title: Text(
            poem.title,
            style: TextStyle(
              fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
              color: isCurrentPlaying
                  ? context.primaryColor
                  : context.textPrimaryColor,
            ),
          ),
          subtitle: Text(
            '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
          trailing: isCurrentPlaying
              ? Icon(
                  Icons.equalizer,
                  color: context.primaryColor,
                  size: 20,
                )
              : Icon(
                  Icons.play_circle_outline,
                  color: context.textSecondaryColor,
                ),
          onTap: onTap,
        ),
      );
    });
  }
}
