import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
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
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        title: Obx(() => Text(
          controller.currentPoem.value?.title ?? '',
          style: const TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(UIConstants.textPrimaryColor), size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final poem = controller.currentPoem.value;
            if (poem == null) return const SizedBox.shrink();
            final isFav = controller.isFavorite(poem.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_outline,
                color: isFav ? const Color(UIConstants.accentColor) : const Color(UIConstants.textSecondaryColor),
                size: 22,
              ),
              onPressed: () => controller.toggleFavorite(poem.id),
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
                  _buildCleanPage(poem),
                  // Page 2: 释义版
                  _buildAnnotatedPage(poem),
                ],
              ),
            ),
            // 页面指示器
            _buildPageIndicator(),
            // 底部播放控制栏
            _buildPlayerBar(controller),
          ],
        );
      }),
    );
  }

  /// Page 1: 纯净版 - 简洁展示，支持卡拉OK高亮
  Widget _buildCleanPage(dynamic poem) {
    final controller = PoemController.to;
    
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
              color: const Color(UIConstants.cardColor),
              borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            ),
            child: Column(
              children: [
                // 标题
                Text(
                  poem.title,
                  style: const TextStyle(
                    color: Color(UIConstants.textPrimaryColor),
                    fontFamily: FontConstants.chineseSerif,
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
                    color: const Color(UIConstants.backgroundColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                    style: const TextStyle(
                      color: Color(UIConstants.textSecondaryColor),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // 正文 - 使用 Obx 监听播放进度和时间戳
                Obx(() {
                  final hasTimestamps = controller.currentTimestamps.isNotEmpty;
                  final isPlayingOrPaused = controller.playbackState.value == PlaybackState.playing || 
                                           controller.playbackState.value == PlaybackState.paused;
                  
                  // 只有在播放/暂停状态且有时间戳时才显示卡拉OK效果
                  if (isPlayingOrPaused && hasTimestamps) {
                    return SmoothKaraokeText(
                      text: poem.cleanContent,
                      timestamps: controller.currentTimestamps,
                      currentPosition: controller.position.value,
                      fontSize: 18,
                      height: 2.4,
                      letterSpacing: 1.5,
                    );
                  }
                  
                  // 默认静态显示
                  return Text(
                    poem.cleanContent,
                    style: const TextStyle(
                      color: Color(UIConstants.textPrimaryColor),
                      fontFamily: FontConstants.chineseSerif,
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
  Widget _buildAnnotatedPage(dynamic poem) {
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
              color: const Color(UIConstants.cardColor),
              borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Center(
                  child: Text(
                    poem.title,
                    style: const TextStyle(
                      color: Color(UIConstants.textPrimaryColor),
                      fontFamily: FontConstants.chineseSerif,
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
                      color: const Color(UIConstants.backgroundColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                      style: const TextStyle(
                        color: Color(UIConstants.textSecondaryColor),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(UIConstants.dividerColor)),
                const SizedBox(height: 24),
                // 释义内容 - 逐行原文+释义混排（annotated_content 已包含原文和释义）
                if (hasAnnotation)
                  Text(
                    poem.annotatedContent,
                    style: const TextStyle(
                      color: Color(UIConstants.textPrimaryColor),
                      fontFamily: FontConstants.chineseSerif,
                      fontSize: 16,
                      height: 2.0,
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      '暂无释义',
                      style: TextStyle(
                        color: Color(UIConstants.textSecondaryColor),
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
  Widget _buildPageIndicator() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(0),
          const SizedBox(width: 8),
          _buildDot(1),
          const SizedBox(width: 12),
          Text(
            _currentPage.value == 0 ? '左滑查看释义' : '右滑返回原文',
            style: const TextStyle(
              fontSize: 12,
              color: Color(UIConstants.textSecondaryColor),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage.value == index;
    return Container(
      width: isActive ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(UIConstants.accentColor) 
            : const Color(UIConstants.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPlayerBar(PoemController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 播放进度条（仅在播放或暂停时显示）
            Obx(() {
              final state = controller.playbackState.value;
              if (state == PlaybackState.idle || state == PlaybackState.loading) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(controller.position.value),
                      style: const TextStyle(fontSize: 11, color: Color(UIConstants.textSecondaryColor)),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(Get.context!).copyWith(
                          activeTrackColor: const Color(UIConstants.accentColor),
                          inactiveTrackColor: const Color(UIConstants.dividerColor),
                          thumbColor: const Color(UIConstants.accentColor),
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: controller.position.value.inMilliseconds.toDouble(),
                          max: controller.duration.value.inMilliseconds.toDouble().clamp(1, double.infinity),
                          onChanged: (value) => controller.seekTo(Duration(milliseconds: value.toInt())),
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(controller.duration.value),
                      style: const TextStyle(fontSize: 11, color: Color(UIConstants.textSecondaryColor)),
                    ),
                  ],
                ),
              );
            }),

            // 加载进度条（仅在加载时显示）
            Obx(() {
              final state = controller.playbackState.value;
              final progress = controller.downloadProgress.value;
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
                        const Text(
                          '正在合成语音...',
                          style: TextStyle(fontSize: 12, color: Color(UIConstants.textSecondaryColor)),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, color: Color(UIConstants.accentColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: const Color(UIConstants.dividerColor),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(UIConstants.accentColor)),
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
                  final state = controller.playbackState.value;
                  if (state != PlaybackState.playing && state != PlaybackState.paused) {
                    return const SizedBox(width: 48);
                  }
                  return IconButton(
                    icon: const Icon(Icons.stop, color: Color(UIConstants.textSecondaryColor), size: 24),
                    onPressed: () => controller.stop(),
                  );
                }),
                
                const SizedBox(width: 24),
                
                // 播放/暂停按钮
                Obx(() {
                  final state = controller.playbackState.value;
                  final isLoading = state == PlaybackState.loading;
                  
                  return GestureDetector(
                    onTap: isLoading ? null : () => controller.togglePlay(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isLoading 
                            ? const Color(UIConstants.dividerColor) 
                            : const Color(UIConstants.accentColor),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(UIConstants.textSecondaryColor)),
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
                    color: const Color(UIConstants.accentColor),
                    onPressed: () => _showVoiceSelector(controller),
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
                style: const TextStyle(
                  fontSize: 12, 
                  color: Color(UIConstants.textSecondaryColor),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  void _showVoiceSelector(PoemController controller) {
    final settings = SettingsService.to;
    final poem = controller.currentPoem.value;
    if (poem == null) return;

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: const Color(UIConstants.cardColor),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(UIConstants.defaultRadius))),
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
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(UIConstants.dividerColor))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Color(UIConstants.accentColor), size: 20),
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
                    _buildVoiceSection('Doubao 1.0', TtsVoice1.voices, poem.id),
                    _buildVoiceSection('Doubao 2.0', TtsVoice2.voices, poem.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceSection(String title, List<TtsVoice> voices, int poemId) {
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
              color: const Color(UIConstants.textSecondaryColor),
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
                    color: isSelected ? const Color(UIConstants.backgroundColor) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? const Color(UIConstants.accentColor) : const Color(UIConstants.dividerColor),
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
                                color: const Color(UIConstants.textPrimaryColor),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${voice.gender} · ${voice.description}',
                              style: const TextStyle(fontSize: 12, color: Color(UIConstants.textSecondaryColor)),
                            ),
                          ],
                        ),
                      ),
                      if (isCached)
                        const Icon(Icons.offline_pin, color: Color(UIConstants.accentColor), size: 18),
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
                            color: voice is TtsVoice1 ? const Color(UIConstants.textSecondaryColor) : const Color(0xFF4CAF50),
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
