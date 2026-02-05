import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/ai_models.dart';

import '../constants/changelog.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/dialogs/app_dialog.dart';
import '../widgets/settings/index.dart';
import 'settings/llm_config_page.dart';
import 'settings/theme_color_page.dart';
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
      appBar: AppBar(
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
        // 主题颜色选择
        SettingsTile(
          icon: Icons.palette_outlined,
          iconBackgroundColor: const Color(0xFFFCE4EC), // 淡粉色背景
          iconColor: const Color(0xFFE91E63),
          title: '主题颜色',
          subtitle: TraditionalChineseColors.getColorName(settingsService.primaryColor.value),
          trailing: SettingsTileTrailing.custom,
          customTrailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: settingsService.primaryColor.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
          ),
          onTap: () => Get.to(() => const ThemeColorPage()),
        ),
        
        // 深色模式选择
        SettingsTile(
          icon: Icons.dark_mode_outlined,
          iconBackgroundColor: const Color(0xFFE8EAF6), // 淡靛蓝色背景
          iconColor: const Color(0xFF3F51B5),
          title: '深色模式',
          subtitle: _getThemeModeText(settingsService.themeMode.value),
          trailing: SettingsTileTrailing.arrow,
          onTap: () => _showThemeModePicker(),
        ),
        
        // 系统字体切换
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
  
  /// 获取主题模式显示文本
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }
  
  /// 显示颜色选择器（重构版：每行2个，左侧长方形+色号+中文名）
  void _showColorPicker() {
    final colors = TraditionalChineseColors.allColors;
    final names = ['朱砂', '竹青', '黛蓝', '栀子', '暮山紫', '玄青', '靛蓝', '橘橙', '翠绿', '紫罗兰'];
    
    // 颜色值转十六进制字符串
    String colorToHex(Color color) {
      return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    }
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动条
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '选择主题颜色',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // 颜色选项 - 每行2个
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate((colors.length / 2).ceil(), (rowIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // 第一个颜色
                          Expanded(
                            child: _buildColorItem(
                              colors[rowIndex * 2],
                              names[rowIndex * 2],
                              colorToHex(colors[rowIndex * 2]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 第二个颜色（如果存在）
                          Expanded(
                            child: (rowIndex * 2 + 1) < colors.length
                                ? _buildColorItem(
                                    colors[rowIndex * 2 + 1],
                                    names[rowIndex * 2 + 1],
                                    colorToHex(colors[rowIndex * 2 + 1]),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建颜色选项项（左侧长方形+色号+中文名）
  Widget _buildColorItem(Color color, String name, String hexCode) {
    final isSelected = settingsService.primaryColor.value == color;
    
    return GestureDetector(
      onTap: () {
        settingsService.savePrimaryColor(color);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            // 左侧长方形颜色块
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // 中间色号
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hexCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: context.textSecondaryColor,
                    ),
                  ),
                  // 右侧中文名
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // 选中标记
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
  
  /// 显示深色模式选择器
  void _showThemeModePicker() {
    final modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final names = ['跟随系统', '浅色模式', '深色模式'];
    final icons = [Icons.brightness_auto, Icons.brightness_high, Icons.brightness_2];
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动条
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '深色模式',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // 模式选项
              ...List.generate(modes.length, (index) {
                final mode = modes[index];
                final isSelected = settingsService.themeMode.value == mode;
                
                return ListTile(
                  leading: Icon(
                    icons[index],
                    color: isSelected ? context.primaryColor : context.textSecondaryColor,
                  ),
                  title: Text(
                    names[index],
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: context.primaryColor)
                      : null,
                  onTap: () {
                    settingsService.saveThemeMode(mode);
                    Get.back();
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
      appBar: AppBar(
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
                    color: context.primaryColor,
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
                  '阅读',
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
                    color: context.textSecondaryColor,
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
          const SettingsSection(
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                iconBackgroundColor: Color(0xFFFCE4EC),
                iconColor: Color(0xFFE91E63),
                title: '作者',
                trailing: SettingsTileTrailing.text,
                trailingText: 'Wong',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 版权信息
          Center(
            child: Text(
              '© 2026 阅读 @Wong · 给宝贝儿子桐桐',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  void _showVersionDetail(VersionInfo version) {
    AppDialog.show(
      title: '${version.version} 更新内容',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: version.changes.map((change) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('• $change', textAlign: TextAlign.center),
          )).toList(),
        ),
      ),
      confirmText: '关闭',
      showCancel: false,
    );
  }
}
