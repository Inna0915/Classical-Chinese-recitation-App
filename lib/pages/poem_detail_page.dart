import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
import '../controllers/player_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';
import '../widgets/karaoke_text.dart';

/// 诗词详情页 - 双视图模式
/// Page 1: 纯净版（大字、海报风格）
/// Page 2: 释义版（原文+释义）
class PoemDetailPage extends StatefulWidget {
  const PoemDetailPage({super.key});

  @override
  State<PoemDetailPage> createState() => _PoemDetailPageState();
}

class _PoemDetailPageState extends State<PoemDetailPage> {
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Obx(() => Text(
          controller.currentPoem.value?.title ?? '',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimaryColor, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final poem = controller.currentPoem.value;
            if (poem == null) return const SizedBox.shrink();
            final isFav = controller.isFavorite(poem.id!);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_outline,
                color: isFav ? context.primaryColor : context.textSecondaryColor,
                size: 22,
              ),
              onPressed: () => controller.toggleFavorite(poem.id!),
            );
          }),
        ],
      ),
      body: Obx(() {
        final poem = controller.currentPoem.value;
        if (poem == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => _currentPage.value = index,
                children: [
                  // Page 1: 纯净版
                  _buildCleanPage(context, poem),
                  // Page 2: 释义版
                  _buildAnnotatedPage(context, poem),
                ],
              ),
            ),
            // 页面指示器
            _buildPageIndicator(context),
            // 底部播放控制栏
            _buildPlayerBar(context, controller),
          ],
        );
      }),
    );
  }

  /// Page 1: 纯净版 - 简洁展示，支持卡拉OK高亮
  Widget _buildCleanPage(BuildContext context, dynamic poem) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 诗词卡片
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: UIConstants.cardHorizontalMargin, 
              vertical: UIConstants.cardVerticalMargin,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            ),
            child: Column(
              children: [
                // 标题
                Text(
                  poem.title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // 作者
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 正文 - 使用 Obx 监听播放进度和时间戳
                Obx(() {
                  final playerController = Get.find<PlayerController>();
                  final hasTimestamps = playerController.currentTimestamps.isNotEmpty;
                  final isPlayingOrPaused = playerController.playbackState.value == PlaybackState.playing || 
                                           playerController.playbackState.value == PlaybackState.paused;
                  
                  // 只有在播放/暂停状态且有时间戳时才显示卡拉OK效果
                  if (isPlayingOrPaused && hasTimestamps) {
                    return SmoothKaraokeText(
                      text: poem.cleanContent,
                      timestamps: playerController.currentTimestamps,
                      currentPosition: playerController.position.value,
                      fontSize: 18,
                      height: 2.4,
                      letterSpacing: 1.5,
                    );
                  }
                  
                  // 默认静态显示
                  return Text(
                    poem.cleanContent,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 18,
                      height: 2.4,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Page 2: 释义版 - 逐行原文+释义混排
  Widget _buildAnnotatedPage(BuildContext context, dynamic poem) {
    final hasAnnotation = poem.annotatedContent != null && 
                         poem.annotatedContent.toString().isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: UIConstants.cardHorizontalMargin, 
              vertical: UIConstants.cardVerticalMargin,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Center(
                  child: Text(
                    poem.title,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                // 作者信息
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(height: 1, color: context.dividerColor),
                const SizedBox(height: 24),
                // 释义内容 - 逐行原文+释义混排（annotated_content 已包含原文和释义）
                if (hasAnnotation)
                  Text(
                    poem.annotatedContent,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16,
                      height: 2.0,
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '暂无释义',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 页面指示器 - 显示当前是第几页
  Widget _buildPageIndicator(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(context, 0),
          const SizedBox(width: 8),
          _buildDot(context, 1),
          const SizedBox(width: 12),
          Text(
            _currentPage.value == 0 ? '左滑查看释义' : '右滑返回原文',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDot(BuildContext context, int index) {
    final isActive = _currentPage.value == index;
    return Container(
      width: isActive ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? context.primaryColor 
            : context.dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPlayerBar(BuildContext context, PoemController controller) {
    return Obx(() {
      final playerController = Get.find<PlayerController>();
      final poem = controller.currentPoem.value;
      
      // 只有当当前诗词在播放中，或者没有播放时才显示控制栏
      final isCurrentPoemPlaying = playerController.currentPoem?.id == poem?.id;
      final hasPlayback = playerController.currentPoem != null;
      
      // 如果播放的是其他诗词，显示切换播放按钮
      if (!isCurrentPoemPlaying && hasPlayback) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '正在播放: ${playerController.currentPoem?.title}',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击右侧按钮切换到当前诗词',
                        style: TextStyle(
                          color: context.textSecondaryColor.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // 清空播放列表，只播放当前诗词
                    if (poem != null) {
                      playerController.playPoemList([poem], 0);
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('切换播放'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 播放进度条（仅在播放或暂停时显示）
              Obx(() {
                final state = playerController.playbackState.value;
                if (state == PlaybackState.idle || state == PlaybackState.loading) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(playerController.position.value),
                        style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(Get.context!).copyWith(
                            activeTrackColor: context.primaryColor,
                            inactiveTrackColor: context.dividerColor,
                            thumbColor: context.primaryColor,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: playerController.position.value.inMilliseconds.toDouble(),
                            max: playerController.duration.value.inMilliseconds.toDouble().clamp(1, double.infinity),
                            onChanged: (value) => playerController.seekTo(Duration(milliseconds: value.toInt())),
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(playerController.duration.value),
                        style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                );
              }),

              // 加载进度条（仅在加载时显示）
              Obx(() {
                final state = playerController.playbackState.value;
                final progress = playerController.downloadProgress.value;
                if (state != PlaybackState.loading) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '正在合成语音...',
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(fontSize: 12, color: context.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          backgroundColor: context.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 控制按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 停止按钮
                  Obx(() {
                    final state = playerController.playbackState.value;
                    if (state != PlaybackState.playing && state != PlaybackState.paused) {
                      return const SizedBox(width: 48);
                    }
                    return IconButton(
                      icon: Icon(Icons.stop, color: context.textSecondaryColor, size: 24),
                      onPressed: () => playerController.stop(),
                    );
                  }),
                  
                  const SizedBox(width: 24),
                  
                  // 播放/暂停按钮
                  Obx(() {
                    final state = playerController.playbackState.value;
                    final isLoading = state == PlaybackState.loading;
                    
                    return GestureDetector(
                      onTap: isLoading ? null : () => controller.togglePlay(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isLoading 
                              ? context.dividerColor 
                              : context.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(context.textSecondaryColor),
                                  ),
                                )
                              : Icon(
                                  state == PlaybackState.playing ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(width: 24),
                  
                  // 音色选择按钮
                  Obx(() {
                    final settings = SettingsService.to;
                    final voice = TtsVoices.getAllVoices()
                        .firstWhereOrNull((v) => v.voiceType == settings.voiceType.value);
                    return IconButton(
                      icon: const Icon(Icons.record_voice_over, size: 22),
                      color: context.primaryColor,
                      onPressed: () => _showVoiceSelector(context, controller),
                      tooltip: voice?.displayName ?? '选择音色',
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 音色名称
              Obx(() {
                final settings = SettingsService.to;
                final voice = TtsVoices.getAllVoices()
                    .firstWhereOrNull((v) => v.voiceType == settings.voiceType.value);
                return Text(
                  voice?.displayName ?? settings.voiceType.value,
                  style: TextStyle(
                    fontSize: 12, 
                    color: context.textSecondaryColor,
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  void _showVoiceSelector(BuildContext context, PoemController controller) {
    final poem = controller.currentPoem.value;
    if (poem == null) return;

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(UIConstants.defaultRadius))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.dividerColor)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.record_voice_over, color: context.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '选择朗读音色',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20), 
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildVoiceSection(context, 'Doubao 1.0', TtsVoice1.voices, poem.id!),
                    _buildVoiceSection(context, 'Doubao 2.0', TtsVoice2.voices, poem.id!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceSection(BuildContext context, String title, List<TtsVoice> voices, int poemId) {
    final settings = SettingsService.to;
    final ttsService = TtsService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        ),
        ...voices.map((voice) => Obx(() {
          final isSelected = settings.voiceType.value == voice.voiceType;
          return FutureBuilder<bool>(
            future: ttsService.isVoiceCached(poemId, voice.voiceType),
            builder: (context, snapshot) {
              final isCached = snapshot.data ?? false;
              return InkWell(
                onTap: () {
                  settings.saveVoiceType(voice.voiceType);
                  Navigator.pop(Get.context!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? context.backgroundColor : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? context.primaryColor : context.dividerColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voice.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${voice.gender} · ${voice.description}',
                              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                      if (isCached)
                        Icon(Icons.offline_pin, color: context.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: voice is TtsVoice1 ? const Color(0xFFF0F0F0) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          voice is TtsVoice1 ? '1.0' : '2.0',
                          style: TextStyle(
                            fontSize: 10,
                            color: voice is TtsVoice1 ? context.textSecondaryColor : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        })),
      ],
    );
  }
}
