import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';

/// 诗词详情页
class PoemDetailPage extends StatelessWidget {
  const PoemDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Scaffold(
      backgroundColor: const Color(UIConstants.backgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        title: Obx(() => Text(
          controller.currentPoem.value?.title ?? '未选择诗词',
          style: const TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontSize: 18,
          ),
        )),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(UIConstants.textPrimaryColor),
          ),
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
                color: isFav 
                    ? const Color(UIConstants.accentColor) 
                    : const Color(UIConstants.textSecondaryColor),
              ),
              onPressed: () => controller.toggleFavorite(poem.id),
            );
          }),
        ],
      ),
      body: Obx(() {
        final poem = controller.currentPoem.value;
        if (poem == null) {
          return const Center(child: Text('加载中...'));
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Column(
                  children: [
                    Text(
                      poem.title,
                      style: const TextStyle(
                        color: Color(UIConstants.textPrimaryColor),
                        fontFamily: FontConstants.chineseSerif,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(UIConstants.accentColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${poem.dynasty != null ? '${poem.dynasty} · ' : ''}${poem.author}',
                        style: const TextStyle(
                          color: Color(UIConstants.accentColor),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(UIConstants.cardColor),
                        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                        border: Border.all(color: const Color(UIConstants.dividerColor)),
                      ),
                      child: Text(
                        poem.content,
                        style: const TextStyle(
                          color: Color(UIConstants.textPrimaryColor),
                          fontFamily: FontConstants.chineseSerif,
                          fontSize: FontConstants.bodySize,
                          height: 2.2,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildPlayerBar(controller),
          ],
        );
      }),
    );
  }

  Widget _buildPlayerBar(PoemController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.defaultPadding, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (controller.playbackState.value == PlaybackState.idle ||
                  controller.playbackState.value == PlaybackState.loading) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(controller.position.value),
                      style: const TextStyle(fontSize: 12, color: Color(UIConstants.textSecondaryColor)),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(Get.context!).copyWith(
                          activeTrackColor: const Color(UIConstants.accentColor),
                          inactiveTrackColor: const Color(UIConstants.dividerColor),
                          thumbColor: const Color(UIConstants.accentColor),
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
                      style: const TextStyle(fontSize: 12, color: Color(UIConstants.textSecondaryColor)),
                    ),
                  ],
                ),
              );
            }),
            Obx(() {
              final settings = SettingsService.to;
              final voice = TtsVoices.getAllVoices()
                  .firstWhereOrNull((v) => v.voiceType == settings.voiceType.value);
              return TextButton.icon(
                onPressed: () => _showVoiceSelector(controller),
                icon: const Icon(Icons.record_voice_over, size: 16),
                label: Text(voice?.displayName ?? settings.voiceType.value, style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(UIConstants.textSecondaryColor)),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  final isPlaying = controller.playbackState.value == PlaybackState.playing ||
                      controller.playbackState.value == PlaybackState.paused;
                  if (!isPlaying) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.stop, color: Color(UIConstants.textSecondaryColor)),
                    onPressed: () => controller.stop(),
                  );
                }),
                const SizedBox(width: 16),
                Obx(() {
                  final state = controller.playbackState.value;
                  return ElevatedButton(
                    onPressed: () => controller.togglePlay(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(UIConstants.accentColor),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      fixedSize: const Size(64, 64),
                    ),
                    child: Icon(
                      state == PlaybackState.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                }),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.record_voice_over),
                  onPressed: () => _showVoiceSelector(controller),
                  color: const Color(UIConstants.accentColor),
                ),
              ],
            ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  border: Border(bottom: BorderSide(color: const Color(UIConstants.dividerColor))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Color(UIConstants.accentColor)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('选择朗读音色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(poem.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ),
        ...voices.map((voice) => Obx(() {
          final isSelected = settings.voiceType.value == voice.voiceType;
          return FutureBuilder<bool>(
            future: ttsService.isVoiceCached(poemId, voice.voiceType),
            builder: (context, snapshot) {
              final isCached = snapshot.data ?? false;
              return ListTile(
                dense: true,
                title: Text(voice.displayName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(UIConstants.accentColor) : null)),
                subtitle: Text('${voice.gender} · ${voice.description}', style: const TextStyle(fontSize: 12)),
                leading: isSelected
                    ? const Icon(Icons.check_circle, color: Color(UIConstants.accentColor))
                    : const Icon(Icons.circle_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCached)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.offline_pin, color: Color(UIConstants.accentColor), size: 18),
                      ),
                    Chip(
                      label: Text(voice is TtsVoice1 ? '1.0' : '2.0', style: const TextStyle(fontSize: 10)),
                      backgroundColor: voice is TtsVoice1 ? Colors.blue.shade50 : Colors.green.shade50,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                onTap: () {
                  settings.saveVoiceType(voice.voiceType);
                  Navigator.pop(Get.context!);
                },
              );
            },
          );
        })),
      ],
    );
  }
}
