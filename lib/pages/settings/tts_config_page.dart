import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../constants/tts_voices.dart';
import '../../models/tts_result.dart';
import '../../services/settings_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/settings/index.dart';

/// TTS 配置页面 - 火山引擎语音合成详细配置
class TtsConfigPage extends StatefulWidget {
  const TtsConfigPage({super.key});

  @override
  State<TtsConfigPage> createState() => _TtsConfigPageState();
}

class _TtsConfigPageState extends State<TtsConfigPage> {
  final SettingsService settingsService = SettingsService.to;
  final TtsService ttsService = TtsService();
  
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _clusterController = TextEditingController();
  
  bool _obscureToken = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // 加载 TTS 配置（如果 TtsService 有提供获取配置的方法）
    // 这里使用默认配置或从 SettingsService 加载
    _appIdController.text = '1557076786'; // 默认 AppID
    _tokenController.text = 'y_I-ra6xiDjJW1V8CBVOBjsPZMB9FEtm'; // 默认 Token
    _clusterController.text = 'volcano_tts'; // 默认 Cluster
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _tokenController.dispose();
    _clusterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TTS 服务配置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Color(UIConstants.accentColor),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            // 鉴权信息
            _buildAuthSection(),
            
            // 音色选择
            _buildVoiceSection(),
            
            // 参数调节
            _buildParamsSection(),
            
            // 测试连接
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testTts,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isTesting ? '测试中...' : '测试语音合成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(UIConstants.accentColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // 重置按钮
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _showResetConfirm,
                child: const Text(
                  '恢复默认配置',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 鉴权信息
  Widget _buildAuthSection() {
    return SettingsSection(
      title: '火山引擎鉴权信息',
      children: [
        // AppID
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _appIdController,
            decoration: InputDecoration(
              labelText: 'App ID',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              hintText: '请输入火山引擎 App ID',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        
        const Divider(height: 1, indent: 16, endIndent: 16),
        
        // Access Token
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _tokenController,
            obscureText: _obscureToken,
            decoration: InputDecoration(
              labelText: 'Access Token',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              hintText: '请输入 Access Token',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureToken = !_obscureToken;
                  });
                },
              ),
            ),
          ),
        ),
        
        const Divider(height: 1, indent: 16, endIndent: 16),
        
        // Cluster
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _clusterController,
            decoration: InputDecoration(
              labelText: 'Cluster',
              labelStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              hintText: 'volcano_tts',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 音色选择
  Widget _buildVoiceSection() {
    return Obx(() => SettingsSection(
      title: '音色选择',
      children: [
        SettingsTile(
          icon: Icons.record_voice_over,
          iconBackgroundColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF2196F3),
          title: '当前音色',
          subtitle: TtsVoices.getDisplayName(settingsService.voiceType.value),
          trailing: SettingsTileTrailing.arrow,
          onTap: () => _showVoiceSelector(),
        ),
      ],
    ));
  }

  /// 参数调节
  Widget _buildParamsSection() {
    return Obx(() => SettingsSection(
      title: '参数调节',
      children: [
        // 语速
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '语速',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${(settingsService.speechRate.value / 50 + 1).toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(UIConstants.accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: settingsService.speechRate.value.toDouble(),
                min: -50,
                max: 100,
                divisions: 30,
                label: settingsService.speechRate.value.toString(),
                activeColor: const Color(UIConstants.accentColor),
                onChanged: (value) {
                  settingsService.saveSpeechRate(value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('慢', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('标准', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('快', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, indent: 16, endIndent: 16),
        
        // 音量
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '音量增强',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    settingsService.loudnessRate.value > 0 
                        ? '+${settingsService.loudnessRate.value}' 
                        : '${settingsService.loudnessRate.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(UIConstants.accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: settingsService.loudnessRate.value.toDouble(),
                min: -50,
                max: 100,
                divisions: 30,
                label: settingsService.loudnessRate.value.toString(),
                activeColor: const Color(UIConstants.accentColor),
                onChanged: (value) {
                  settingsService.saveLoudnessRate(value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('轻', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('标准', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('响', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
      ],
    ));
  }

  /// 显示音色选择器
  void _showVoiceSelector() {
    // 分类音色
    final voice2List = TtsVoice2.voices;
    final voice1List = TtsVoice1.voices;
    
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(top: Radius.circular(UIConstants.defaultRadius)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示条
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 标题
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择音色',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const Divider(height: 1),
              
              // 音色列表
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Doubao 2.0 音色
                    _buildVoiceCategory('Doubao 2.0 (推荐)', voice2List),
                    
                    const Divider(height: 1),
                    
                    // Doubao 1.0 音色
                    _buildVoiceCategory('Doubao 1.0', voice1List),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 构建音色分类
  Widget _buildVoiceCategory(String title, List<TtsVoice> voices) {
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
              color: Colors.grey[600],
            ),
          ),
        ),
        ...voices.map((voice) => _buildVoiceTile(voice)),
      ],
    );
  }

  /// 构建音色项
  Widget _buildVoiceTile(TtsVoice voice) {
    final isSelected = settingsService.voiceType.value == voice.voiceType;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(UIConstants.accentColor).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            voice.gender == 'male' ? Icons.male : Icons.female,
            color: isSelected 
                ? const Color(UIConstants.accentColor)
                : Colors.grey[600],
          ),
        ),
      ),
      title: Text(
        voice.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        voice.description,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Color(UIConstants.accentColor))
          : null,
      onTap: () {
        settingsService.saveVoiceType(voice.voiceType);
        Get.back();
      },
    );
  }

  /// 测试 TTS
  Future<void> _testTts() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // 保存当前配置
      await _saveSettings();
      
      // 使用 synthesizeText 测试语音合成
      final result = await ttsService.synthesizeText(
        text: '你好，这是古韵诵读的语音测试。声音清晰自然，适合朗读古诗词。',
        voiceType: settingsService.voiceType.value,
        audioParams: AudioParams(
          speechRate: settingsService.speechRate.value,
          loudnessRate: settingsService.loudnessRate.value,
        ),
        poemId: 0, // 测试用 ID
        onProgress: (progress) {
          // 可以在这里显示进度
        },
      );
      
      if (result.isSuccess) {
        Get.snackbar(
          '测试成功',
          '语音合成正常，文件保存在: ${result.audioPath}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          '测试失败',
          result.errorMessage ?? '语音合成失败',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        '测试失败',
        '语音合成出错: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // 同步到 TtsService
    ttsService.setVoiceType(settingsService.voiceType.value);
    
    Get.snackbar(
      '保存成功',
      'TTS 配置已更新',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 显示重置确认
  void _showResetConfirm() {
    Get.dialog(
      AlertDialog(
        title: const Text('恢复默认配置'),
        content: const Text('确定要恢复默认的 TTS 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsService.resetTtsConfig();
              _loadSettings();
              Get.back();
              Get.snackbar(
                '已重置',
                'TTS 配置已恢复为默认值',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
