import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/player_controller.dart';
import '../controllers/poem_controller.dart';
import '../models/poem.dart';
import '../models/poem_group.dart';
import '../pages/poem_detail_page.dart';

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
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        centerTitle: true,
        title: Text(
          group.name,
          style: const TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontFamily: FontConstants.chineseSerif,
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(UIConstants.textPrimaryColor),
          ),
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
                  backgroundColor: const Color(UIConstants.accentColor),
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
          color: const Color(UIConstants.cardColor),
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          border: isCurrentPlaying
              ? Border.all(color: const Color(UIConstants.accentColor), width: 1.5)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCurrentPlaying
                  ? const Color(UIConstants.accentColor).withOpacity(0.1)
                  : const Color(UIConstants.backgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isCurrentPlaying
                  ? const Icon(
                      Icons.volume_up,
                      color: Color(UIConstants.accentColor),
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: const Color(UIConstants.textSecondaryColor),
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
          trailing: isCurrentPlaying
              ? const Icon(
                  Icons.equalizer,
                  color: Color(UIConstants.accentColor),
                  size: 20,
                )
              : const Icon(
                  Icons.play_circle_outline,
                  color: Color(UIConstants.textSecondaryColor),
                ),
          onTap: onTap,
        ),
      );
    });
  }
}
