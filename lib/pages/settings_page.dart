import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/ai_models.dart';
import '../constants/app_constants.dart';
import '../constants/changelog.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/settings/index.dart';

/// 设置页面 - Cherry Studio / iOS 风格重构
/// 
/// 设计特点：
/// - 分组卡片式布局 (Inset Grouped)
/// - 极淡灰色背景
/// - 圆角白色卡片
/// - 精致的分割线和间距
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService settingsService = SettingsService.to;
  final PoemController poemController = PoemController.to;
  
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 极淡灰色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            // Group 1: AI & Intelligence
            _buildAISection(),
            
            // Group 2: Appearance
            _buildAppearanceSection(),
            
            // Group 3: Voice & Playback
            _buildVoiceSection(),
            
            // Group 4: About & Updates
            _buildAboutSection(),
            
            // 底部间距
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// AI & Intelligence 分组
  Widget _buildAISection() {
    return SettingsSection(
      title: 'AI 模型与服务',
      children: [
        SettingsTile(
          icon: Icons.smart_toy_outlined,
          iconBackgroundColor: const Color(0xFFE8F5E9), // 淡绿色背景
          iconColor: const Color(0xFF4CAF50),
          title: '模型服务商',
          subtitle: '配置 AI 翻译和讲解服务',
          trailing: SettingsTileTrailing.badge,
          badgeText: '已连接',
          badgeColor: const Color(0xFF4CAF50),
          onTap: () => _showAIProviderSelector(),
        ),
      ],
    );
  }

  /// Appearance 分组
  Widget _buildAppearanceSection() {
    return Obx(() => SettingsSection(
      title: '外观与显示',
      children: [
        SettingsTile(
          icon: Icons.text_format,
          iconBackgroundColor: const Color(0xFFFFF3E0), // 淡橙色背景
          iconColor: const Color(0xFFFF9800),
          title: '使用系统字体',
          subtitle: settingsService.useSystemFont.value 
              ? '当前使用系统默认字体 (如 MiSans)'
              : '当前使用古风宋体 (思源宋体)',
          trailing: SettingsTileTrailing.switch_,
          switchValue: settingsService.useSystemFont.value,
          onSwitchChanged: (value) {
            settingsService.saveUseSystemFont(value);
          },
        ),
      ],
    ));
  }

  /// Voice & Playback 分组
  Widget _buildVoiceSection() {
    return SettingsSection(
      title: '语音与播放',
      children: [
        SettingsTile(
          icon: Icons.record_voice_over_outlined,
          iconBackgroundColor: const Color(0xFFE3F2FD), // 淡蓝色背景
          iconColor: const Color(0xFF2196F3),
          title: 'TTS 服务配置',
          subtitle: '音色选择、语速调节',
          trailing: SettingsTileTrailing.arrow,
          onTap: () => _showTTSConfigDialog(),
        ),
      ],
    );
  }

  /// About & Updates 分组
  Widget _buildAboutSection() {
    return SettingsSection(
      title: '关于与更新',
      children: [
        SettingsTile(
          icon: Icons.info_outline,
          iconBackgroundColor: const Color(0xFFF3E5F5), // 淡紫色背景
          iconColor: const Color(0xFF9C27B0),
          title: '关于古韵诵读',
          trailing: SettingsTileTrailing.text,
          trailingText: 'v$_version',
          onTap: () => _showAboutDialog(),
        ),
      ],
    );
  }

  // ==================== AI 配置对话框 ====================

  void _showAIProviderSelector() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '选择 AI 服务商',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AIModels.providers.keys.length,
            itemBuilder: (context, index) {
              final providerKey = AIModels.providers.keys.elementAt(index);
              final provider = AIModels.providers[providerKey]!;
              final isSelected = settingsService.aiProvider.value == providerKey;
              
              return ListTile(
                title: Text(provider.name),
                subtitle: Text(provider.models.join(', ')),
                trailing: isSelected 
                    ? const Icon(Icons.check, color: Color(UIConstants.accentColor))
                    : null,
                onTap: () {
                  settingsService.saveAIProvider(providerKey);
                  Get.back();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // ==================== TTS 配置对话框 ====================

  void _showTTSConfigDialog() {
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'TTS 服务配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showResetConfirmDialog(),
                      child: const Text(
                        '重置',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // 音色选择
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('当前音色'),
                subtitle: Obx(() => Text(
                  TtsVoices.getDisplayName(settingsService.voiceType.value),
                )),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showVoiceSelector(),
              ),
              
              const Divider(height: 1, indent: 56),
              
              // 语速调节
              Obx(() => ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('语速'),
                subtitle: Slider(
                  value: settingsService.speechRate.value.toDouble(),
                  min: -50,
                  max: 100,
                  divisions: 30,
                  label: settingsService.speechRate.value.toString(),
                  onChanged: (value) {
                    settingsService.saveSpeechRate(value.round());
                  },
                ),
              )),
              
              const Divider(height: 1, indent: 56),
              
              // 音量调节
              Obx(() => ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('音量'),
                subtitle: Slider(
                  value: settingsService.loudnessRate.value.toDouble(),
                  min: -50,
                  max: 100,
                  divisions: 30,
                  label: settingsService.loudnessRate.value.toString(),
                  onChanged: (value) {
                    settingsService.saveLoudnessRate(value.round());
                  },
                ),
              )),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showVoiceSelector() {
    final voices = TtsVoices.getAllVoices();
    
    Get.to(() => Scaffold(
      appBar: AppBar(
        title: const Text('选择音色'),
        backgroundColor: const Color(UIConstants.backgroundColor),
      ),
      body: ListView.builder(
        itemCount: voices.length,
        itemBuilder: (context, index) {
          final voice = voices[index];
          final isSelected = settingsService.voiceType.value == voice.voiceType;
          
          return ListTile(
            title: Text(voice.displayName),
            subtitle: Text(voice.description),
            trailing: isSelected 
                ? const Icon(Icons.check, color: Color(UIConstants.accentColor))
                : null,
            onTap: () {
              settingsService.saveVoiceType(voice.voiceType);
              Get.back();
            },
          );
        },
      ),
    ));
  }

  void _showResetConfirmDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('重置 TTS 配置'),
        content: const Text('确定要将所有 TTS 设置恢复为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsService.resetTtsConfig();
              Get.back();
              Get.back();
              Get.snackbar(
                '重置成功',
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

  // ==================== 关于对话框 ====================

  void _showAboutDialog() {
    Get.to(() => Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用图标和名称
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(UIConstants.accentColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '古韵诵读',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本 v$_version',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 检查更新
          SettingsSection(
            children: [
              SettingsTile(
                icon: Icons.system_update,
                iconBackgroundColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF4CAF50),
                title: '检查更新',
                trailing: SettingsTileTrailing.arrow,
                onTap: () => UpdateService.to.checkUpdate(isManual: true),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 更新日志
          SettingsSection(
            title: '更新记录',
            children: [
              for (final version in Changelog.versions)
                SettingsTile(
                  title: '${version.version} (${version.date})',
                  subtitle: version.changes.take(2).join('\n'),
                  trailing: SettingsTileTrailing.none,
                  onTap: () => _showVersionDetail(version),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 作者信息
          SettingsSection(
            children: [
              const SettingsTile(
                icon: Icons.person_outline,
                iconBackgroundColor: Color(0xFFFCE4EC),
                iconColor: Color(0xFFE91E63),
                title: '作者',
                trailing: SettingsTileTrailing.text,
                trailingText: 'wong',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 版权信息
          Center(
            child: Text(
              '© 2025 古韵诵读 · 给宝贝儿子桐桐',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  void _showVersionDetail(VersionInfo version) {
    Get.dialog(
      AlertDialog(
        title: Text('${version.version} 更新内容'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: version.changes.map((change) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $change'),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
