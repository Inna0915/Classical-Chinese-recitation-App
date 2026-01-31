import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';

/// 诗词详情页
/// 
/// 展示诗词详细内容，包含精美的排版和带 Loading 状态的播放按钮
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(UIConstants.textPrimaryColor),
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          // 清除缓存按钮
          Obx(() {
            final poem = controller.currentPoem.value;
            if (poem?.localAudioPath == null) return const SizedBox.shrink();
            
            return IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(UIConstants.textSecondaryColor),
              ),
              tooltip: '清除缓存',
              onPressed: () => _showClearCacheDialog(context, controller),
            );
          }),
        ],
      ),
      body: Obx(() {
        final poem = controller.currentPoem.value;
        if (poem == null) {
          return const Center(
            child: Text('加载中...'),
          );
        }

        return Column(
          children: [
            // 诗词内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Column(
                  children: [
                    // 标题
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
                    
                    // 作者和朝代
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                    
                    // 诗词正文
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(UIConstants.cardColor),
                        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                        border: Border.all(
                          color: const Color(UIConstants.dividerColor),
                        ),
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
                    
                    // 错误信息提示
                    Obx(() {
                      if (controller.errorMessage.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            
            // 底部播放控制栏
            _buildPlayerBar(controller),
          ],
        );
      }),
    );
  }

  /// 构建播放控制栏
  Widget _buildPlayerBar(PoemController controller) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
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
            // 进度条（仅在播放或暂停时显示）
            Obx(() {
              if (controller.playbackState.value == PlaybackState.idle &&
                  controller.playbackState.value == PlaybackState.loading) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(controller.position.value),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(Get.context!).copyWith(
                          activeTrackColor: const Color(UIConstants.accentColor),
                          inactiveTrackColor: const Color(UIConstants.dividerColor),
                          thumbColor: const Color(UIConstants.accentColor),
                          overlayColor: const Color(UIConstants.accentColor).withOpacity(0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: controller.position.value.inMilliseconds.toDouble(),
                          max: controller.duration.value.inMilliseconds.toDouble().clamp(
                            1,
                            double.infinity,
                          ),
                          onChanged: (value) {
                            controller.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(controller.duration.value),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // 播放按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 停止按钮
                Obx(() {
                  final isPlaying = controller.playbackState.value == PlaybackState.playing ||
                      controller.playbackState.value == PlaybackState.paused;
                  
                  if (!isPlaying) return const SizedBox.shrink();
                  
                  return IconButton(
                    icon: const Icon(
                      Icons.stop,
                      color: Color(UIConstants.textSecondaryColor),
                    ),
                    onPressed: () => controller.stop(),
                  );
                }),
                
                const SizedBox(width: 16),
                
                // 主播放按钮
                Obx(() {
                  final state = controller.playbackState.value;
                  
                  return GestureDetector(
                    onTap: () => controller.togglePlay(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(UIConstants.accentColor),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(UIConstants.accentColor).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildPlayButtonIcon(state),
                    ),
                  );
                }),
                
                const SizedBox(width: 16),
                
                // 缓存状态指示
                Obx(() {
                  final poem = controller.currentPoem.value;
                  if (poem?.localAudioPath == null) {
                    return const Tooltip(
                      message: '首次播放需要下载音频',
                      child: Icon(
                        Icons.cloud_download_outlined,
                        color: Color(UIConstants.textSecondaryColor),
                        size: 20,
                      ),
                    );
                  }
                  
                  return const Tooltip(
                    message: '已缓存到本地',
                    child: Icon(
                      Icons.offline_pin,
                      color: Color(UIConstants.accentColor),
                      size: 20,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建播放按钮图标
  Widget _buildPlayButtonIcon(PlaybackState state) {
    switch (state) {
      case PlaybackState.loading:
        // 加载动画
        return Stack(
          alignment: Alignment.center,
          children: [
            // 圆形进度条
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: PoemController.to.downloadProgress.value,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                backgroundColor: Colors.white24,
              ),
            ),
            // 取消图标
            const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ],
        );
      
      case PlaybackState.playing:
        return const Icon(
          Icons.pause,
          color: Colors.white,
          size: 32,
        );
      
      case PlaybackState.paused:
        return const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 32,
        );
      
      case PlaybackState.error:
        return const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 28,
        );
      
      case PlaybackState.idle:
      default:
        return const Icon(
          Icons.headphones,
          color: Colors.white,
          size: 28,
        );
    }
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// 显示清除缓存确认对话框
  void _showClearCacheDialog(BuildContext context, PoemController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '清除缓存',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: const Text(
          '确定要清除这首诗词的音频缓存吗？',
          style: TextStyle(
            color: Color(UIConstants.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.clearCurrentCache();
              Navigator.of(context).pop();
            },
            child: const Text(
              '确定',
              style: TextStyle(
                color: Color(UIConstants.accentColor),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
