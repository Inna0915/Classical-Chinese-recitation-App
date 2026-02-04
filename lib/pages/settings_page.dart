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
import 'settings/llm_config_page.dart';
import 'settings/tts_config_page.dart';

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
        Obx(() => SettingsTile(
          icon: Icons.smart_toy_outlined,
          iconBackgroundColor: const Color(0xFFE8F5E9), // 淡绿色背景
          iconColor: const Color(0xFF4CAF50),
          title: '模型服务商',
          subtitle: settingsService.hasAIConfig.value 
              ? '当前: ${AIModels.providers[settingsService.aiProvider.value]?.name ?? settingsService.aiProvider.value}'
              : '配置 AI 翻译和讲解服务',
          trailing: SettingsTileTrailing.badge,
          badgeText: settingsService.hasAIConfig.value ? '已配置' : '未配置',
          badgeColor: settingsService.hasAIConfig.value 
              ? const Color(0xFF4CAF50) 
              : Colors.orange,
          onTap: () => Get.to(() => const LlmConfigPage()),
        )),
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
        Obx(() => SettingsTile(
          icon: Icons.record_voice_over_outlined,
          iconBackgroundColor: const Color(0xFFE3F2FD), // 淡蓝色背景
          iconColor: const Color(0xFF2196F3),
          title: 'TTS 服务配置',
          subtitle: '当前音色: ${TtsVoices.getDisplayName(settingsService.voiceType.value)}',
          trailing: SettingsTileTrailing.arrow,
          onTap: () => Get.to(() => const TtsConfigPage()),
        )),
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
