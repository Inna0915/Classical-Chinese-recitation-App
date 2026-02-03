import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/ai_models.dart';
import '../constants/ai_prompts.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../controllers/poem_controller.dart';
import '../services/settings_service.dart';
import '../services/tts_service.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 动态模型列表（用于同步后更新）
  final RxMap<String, List<String>> _dynamicModels = <String, List<String>>{}.obs;

  @override
  void initState() {
    super.initState();
    // 初始化动态模型列表为预设值
    _resetDynamicModels();
  }

  void _resetDynamicModels() {
    _dynamicModels.value = {
      'kimi': ['kimi-k2-turbo-preview', 'moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
      'deepseek': ['deepseek-chat', 'deepseek-coder'],
      'qwen': ['qwen-turbo', 'qwen-plus', 'qwen-max'],
      'gemini': ['gemini-pro', 'gemini-pro-vision'],
      'openai': ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
      'custom': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

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
        title: const Text(
          '设置',
          style: TextStyle(
            color: Color(UIConstants.textPrimaryColor),
            fontFamily: FontConstants.chineseSerif,
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // AI 模型配置区域
          _buildSectionTitle('AI 模型配置（用于自动生成诗词）'),
          const SizedBox(height: 12),
          _buildAIConfigCard(settings),
          
          const SizedBox(height: 24),
          
          // TTS 配置区域 - 简化版
          _buildSectionTitle('语音合成配置（用于朗读）'),
          const SizedBox(height: 12),
          _buildTtsConfigCard(settings),
          
          const SizedBox(height: 24),
          
          // 缓存管理
          _buildSectionTitle('缓存管理'),
          const SizedBox(height: 12),
          _buildCacheCard(),
          
          const SizedBox(height: 24),
          
          // 关于应用
          _buildSectionTitle('关于'),
          const SizedBox(height: 12),
          _buildAboutCard(),
        ],
      ),
    );
  }

  // ==================== UI 构建方法 ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: FontConstants.chineseSerif,
        fontSize: FontConstants.bodySize,
        fontWeight: FontWeight.bold,
        color: Color(UIConstants.textPrimaryColor),
      ),
    );
  }

  /// TTS 配置卡片 - 简化版
  Widget _buildTtsConfigCard(SettingsService settings) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 状态指示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(UIConstants.defaultRadius),
                topRight: Radius.circular(UIConstants.defaultRadius),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TTS 已配置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '使用内置火山引擎凭证，无需额外配置',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(UIConstants.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 朗读音色选择
          ListTile(
            leading: const Icon(
              Icons.record_voice_over_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('朗读音色'),
            subtitle: Obx(() => Text(
              TtsVoices.getDisplayName(settings.voiceType.value),
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVoiceTypeDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // 内置配置查看/修改
          ListTile(
            leading: const Icon(
              Icons.key_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('内置配置'),
            subtitle: const Text(
              '查看/修改火山引擎 API 配置',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTtsConfigDialog(),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // TTS 连接测试按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testTTSConnection(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(UIConstants.accentColor).withOpacity(0.1),
                      foregroundColor: const Color(UIConstants.accentColor),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(UIConstants.accentColor).withOpacity(0.3),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.network_check, size: 18),
                    label: const Text(
                      '测试 TTS 连接',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showDebugLogs(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(UIConstants.textSecondaryColor),
                    side: const BorderSide(color: Color(UIConstants.dividerColor)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.bug_report_outlined, size: 18),
                  label: const Text('日志'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// AI 配置卡片
  Widget _buildAIConfigCard(SettingsService settings) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settings.hasAIConfig.value
                  ? Colors.green.withOpacity(0.1)
                  : const Color(UIConstants.accentColor).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(UIConstants.defaultRadius),
                topRight: Radius.circular(UIConstants.defaultRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  settings.hasAIConfig.value
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: settings.hasAIConfig.value
                      ? Colors.green
                      : const Color(UIConstants.accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.hasAIConfig.value ? 'AI 已配置' : 'AI 未配置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: settings.hasAIConfig.value
                              ? Colors.green
                              : const Color(UIConstants.accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.hasAIConfig.value
                            ? '可以使用 AI 自动生成诗词功能'
                            : '配置 API Key 以使用 AI 功能',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(UIConstants.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          
          ListTile(
            leading: const Icon(
              Icons.computer_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('AI 提供商'),
            subtitle: Obx(() => Text(
              _getProviderDisplayName(settings.aiProvider.value),
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAIProviderDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(
              Icons.key_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('API Key'),
            subtitle: Obx(() => Text(
              settings.aiApiKey.value.isEmpty
                  ? '未设置'
                  : '${settings.aiApiKey.value.substring(0, settings.aiApiKey.value.length > 8 ? 8 : settings.aiApiKey.value.length)}****',
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAIApiKeyDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(
              Icons.model_training_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('模型'),
            subtitle: Obx(() => Text(
              settings.aiModel.value.isEmpty ? '未选择' : settings.aiModel.value,
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAIModelDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('自定义提示词'),
            subtitle: Obx(() => Text(
              settings.customPrompt.value.isEmpty ? '使用默认提示词' : '已自定义',
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCustomPromptDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(
              Icons.tune_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('高级配置'),
            subtitle: const Text(
              '查看和修改 API 地址等配置',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAIAdvancedConfig(settings),
          ),
        ],
      ),
    );
  }

  /// 缓存管理卡片
  Widget _buildCacheCard() {
    final ttsService = TtsService();
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Column(
        children: [
          FutureBuilder<double>(
            future: ttsService.getCacheSize(),
            builder: (context, snapshot) {
              final size = snapshot.data ?? 0.0;
              return ListTile(
                leading: const Icon(
                  Icons.storage_outlined,
                  color: Color(UIConstants.textSecondaryColor),
                ),
                title: const Text('音频缓存'),
                subtitle: Text(
                  '已占用 ${size.toStringAsFixed(2)} MB',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: size > 0
                    ? TextButton(
                        onPressed: () => _showClearCacheConfirm(ttsService),
                        child: const Text('清除'),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 关于卡片
  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(UIConstants.cardColor),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: const Color(UIConstants.dividerColor),
        ),
      ),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: Text('应用版本'),
            subtitle: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('开源协议'),
            subtitle: const Text(
              'MIT License',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenseDialog(),
          ),
        ],
      ),
    );
  }

  // ==================== 对话框方法 ====================

  /// 显示音色选择对话框 - 使用正确的音色列表
  void _showVoiceTypeDialog(SettingsService settings) {
    final allVoices = TtsVoices.getAllVoices();
    final customVoices = TtsVoices.getCustomVoices();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '选择朗读音色',
              style: TextStyle(
                fontFamily: FontConstants.chineseSerif,
                color: Color(UIConstants.textPrimaryColor),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomVoiceDialog(settings),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('自定义'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(Get.context!).size.height * 0.5,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 预设音色
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '预设音色',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                ),
              ),
              ...TtsVoice1.voices.map((voice) => _buildVoiceTile(voice, settings, '1.0')),
              ...TtsVoice2.voices.map((voice) => _buildVoiceTile(voice, settings, '2.0')),
              
              // 自定义音色
              if (customVoices.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '自定义音色',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(UIConstants.textSecondaryColor),
                    ),
                  ),
                ),
                ...customVoices.map((voice) => _buildCustomVoiceTile(voice, settings)),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVoiceTile(dynamic voice, SettingsService settings, String version) {
    final isV2 = version == '2.0';
    
    return Obx(() => RadioListTile<String>(
      title: Row(
        children: [
          Text(voice.displayName),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isV2 
                  ? const Color(UIConstants.accentColor).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Doubao $version',
              style: TextStyle(
                fontSize: 10,
                color: isV2 
                    ? const Color(UIConstants.accentColor)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        voice.description,
        style: const TextStyle(fontSize: 11),
      ),
      value: voice.voiceType,
      groupValue: settings.voiceType.value,
      activeColor: const Color(UIConstants.accentColor),
      onChanged: (value) {
        if (value != null) {
          settings.saveVoiceType(value);
          // 同步更新 TtsService 中的音色
          TtsService().setVoiceType(value);
          Get.back();
        }
      },
    ));
  }
  
  Widget _buildCustomVoiceTile(CustomVoice voice, SettingsService settings) {
    return Obx(() => RadioListTile<String>(
      title: Row(
        children: [
          Text(voice.displayName),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '自定义',
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        voice.description,
        style: const TextStyle(fontSize: 11),
      ),
      value: voice.voiceType,
      groupValue: settings.voiceType.value,
      activeColor: const Color(UIConstants.accentColor),
      secondary: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
        onPressed: () async {
          await TtsVoices.removeCustomVoice(voice.voiceType);
          Get.back();
          _showVoiceTypeDialog(settings);
          Get.snackbar(
            '已删除',
            '自定义音色已删除',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
      onChanged: (value) {
        if (value != null) {
          settings.saveVoiceType(value);
          // 同步更新 TtsService 中的音色
          TtsService().setVoiceType(value);
          Get.back();
        }
      },
    ));
  }
  
  void _showAddCustomVoiceDialog(SettingsService settings) {
    final voiceTypeController = TextEditingController();
    final displayNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedVersion = '1.0'.obs;
    final selectedGender = 'female'.obs;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '添加自定义音色',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: voiceTypeController,
                decoration: InputDecoration(
                  labelText: '音色ID',
                  hintText: '如: BV001_streaming',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: '显示名称',
                  hintText: '如: 我的音色',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '描述',
                  hintText: '音色描述...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedVersion.value,
                decoration: InputDecoration(
                  labelText: 'API 版本',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: '1.0', child: Text('Doubao 1.0')),
                  DropdownMenuItem(value: '2.0', child: Text('Doubao 2.0')),
                ],
                onChanged: (value) => selectedVersion.value = value!,
              )),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedGender.value,
                decoration: InputDecoration(
                  labelText: '性别',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('女声')),
                  DropdownMenuItem(value: 'male', child: Text('男声')),
                ],
                onChanged: (value) => selectedGender.value = value!,
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (voiceTypeController.text.isEmpty || 
                  displayNameController.text.isEmpty) {
                Get.snackbar(
                  '错误',
                  '请填写音色ID和显示名称',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              final voice = CustomVoice(
                voiceType: voiceTypeController.text.trim(),
                displayName: displayNameController.text.trim(),
                gender: selectedGender.value,
                description: descriptionController.text.trim(),
                version: selectedVersion.value,
              );
              
              await TtsVoices.addCustomVoice(voice);
              Get.back();
              Get.back();
              _showVoiceTypeDialog(settings);
              
              Get.snackbar(
                '已添加',
                '自定义音色已保存',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 测试 TTS 连接
  void _testTTSConnection() async {
    final ttsService = TtsService();
    final settings = SettingsService.to;
    
    // 确保音色设置已同步
    ttsService.setVoiceType(settings.voiceType.value);
    
    Get.dialog(
      const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('正在测试连接...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    
    final result = await ttsService.testConnection();
    
    Get.back(); // 关闭加载对话框
    
    if (result.isSuccess) {
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(UIConstants.cardColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('连接成功'),
            ],
          ),
          content: const Text(
            'TTS 服务连接正常，可以正常使用朗读功能。',
            style: TextStyle(color: Color(UIConstants.textSecondaryColor)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                // 延迟打开日志，避免动画冲突
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showDebugLogs();
                });
              },
              child: const Text('查看日志'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(UIConstants.cardColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: result.statusCode == 401 ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                result.statusCode == 401 ? '认证失败' : '连接失败',
                style: TextStyle(
                  color: result.statusCode == 401 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            result.errorMessage ?? '未知错误',
            style: const TextStyle(color: Color(UIConstants.textSecondaryColor)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Future.delayed(const Duration(milliseconds: 200), () {
                  _showDebugLogs();
                });
              },
              child: const Text('查看日志'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  /// 显示调试日志
  void _showDebugLogs() {
    final ttsService = TtsService();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TTS 调试日志',
                    style: TextStyle(
                      fontFamily: FontConstants.chineseSerif,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ttsService.clearDebugLogs();
                      Get.back();
                      Get.snackbar(
                        '已清除',
                        '调试日志已清空',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final logs = ttsService.debugLogs;
                  return logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(
                              color: Color(UIConstants.textSecondaryColor),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[logs.length - 1 - index];
                            Color logColor;
                            IconData logIcon;
                            
                            switch (log.type) {
                              case 'request':
                                logColor = Colors.blue;
                                logIcon = Icons.send;
                                break;
                              case 'response':
                                logColor = Colors.green;
                                logIcon = Icons.check_circle;
                                break;
                              case 'error':
                                logColor = Colors.red;
                                logIcon = Icons.error;
                                break;
                              default:
                                logColor = Colors.grey;
                                logIcon = Icons.info;
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: Icon(logIcon, color: logColor, size: 20),
                                title: Text(
                                  log.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: logColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: '复制此日志',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: 
                                      '[${log.type.toUpperCase()}] ${log.title}\n'
                                      '时间: ${log.timestamp.toString()}\n'
                                      '\n${log.content}'
                                    ));
                                    Get.snackbar(
                                      '已复制',
                                      '日志内容已复制到剪贴板',
                                      snackPosition: SnackPosition.BOTTOM,
                                      duration: const Duration(seconds: 1),
                                    );
                                  },
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.grey.shade100,
                                    child: SelectableText(
                                      log.content,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(UIConstants.accentColor),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 显示 TTS 配置对话框
  void _showTtsConfigDialog() {
    final ttsService = TtsService();
    final appIdController = TextEditingController(text: ttsService.appId);
    final accessKeyController = TextEditingController(text: ttsService.accessToken);
    final isKeyVisible = false.obs;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          'TTS 内置配置',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '修改后将用于语音合成请求',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: appIdController,
                  decoration: InputDecoration(
                    labelText: 'APP ID',
                    hintText: '输入火山引擎 APP ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() => TextField(
                  controller: accessKeyController,
                  decoration: InputDecoration(
                    labelText: 'Access Key',
                    hintText: '输入火山引擎 Access Key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isKeyVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: const Color(UIConstants.textSecondaryColor),
                      ),
                      onPressed: () => isKeyVisible.toggle(),
                    ),
                  ),
                  obscureText: !isKeyVisible.value,
                )),
                const SizedBox(height: 8),
                const Text(
                  '注：默认使用内置配置，仅在需要更换时修改',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 恢复默认配置
              appIdController.text = TtsConstants.appId;
              accessKeyController.text = TtsConstants.accessToken;
            },
            child: const Text('恢复默认'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ttsService.setCredentials(
                appIdController.text.trim(),
                accessKeyController.text.trim(),
              );
              Get.back();
              Get.snackbar(
                '已保存',
                'TTS 配置已更新',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示清除缓存确认
  void _showClearCacheConfirm(TtsService ttsService) {
    Get.dialog(
      AlertDialog(
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
          '确定要清除所有音频缓存吗？此操作不可恢复。',
          style: TextStyle(
            color: Color(UIConstants.textSecondaryColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ttsService.clearAllAudioCache();
              PoemController.to.loadPoems();
              Get.back();
              Get.snackbar(
                '成功',
                '缓存已清除',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  // ==================== AI 配置对话框 ====================

  String _getProviderDisplayName(String provider) {
    final names = {
      'kimi': 'Kimi (Moonshot)',
      'deepseek': 'DeepSeek',
      'qwen': '通义千问',
      'gemini': 'Gemini',
      'openai': 'OpenAI',
      'custom': '自定义',
    };
    return names[provider] ?? provider;
  }

  void _showAIProviderDialog(SettingsService settings) {
    final providers = ['kimi', 'deepseek', 'qwen', 'gemini', 'openai', 'custom'];
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '选择 AI 提供商',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: providers.map((provider) {
            return Obx(() => RadioListTile<String>(
              title: Text(_getProviderDisplayName(provider)),
              value: provider,
              groupValue: settings.aiProvider.value,
              activeColor: const Color(UIConstants.accentColor),
              onChanged: (value) {
                if (value != null) {
                  settings.saveAIProvider(value);
                  Get.back();
                }
              },
            ));
          }).toList(),
        ),
      ),
    );
  }

  void _showAIApiKeyDialog(SettingsService settings) {
    final controller = TextEditingController(text: settings.aiApiKey.value);
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '设置 API Key',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '输入 API Key',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.saveAIApiKey(controller.text.trim());
              Get.back();
              Get.snackbar(
                '已保存',
                'API Key 已更新',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAIModelDialog(SettingsService settings) {
    final provider = settings.aiProvider.value;
    final config = AIModels.providers[provider];
    
    if (config == null) return;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '选择模型',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: config.models.map((model) {
            return Obx(() => RadioListTile<String>(
              title: Text(model),
              value: model,
              groupValue: settings.aiModel.value,
              activeColor: const Color(UIConstants.accentColor),
              onChanged: (value) {
                if (value != null) {
                  settings.saveAIModel(value);
                  Get.back();
                }
              },
            ));
          }).toList(),
        ),
      ),
    );
  }

  void _showCustomPromptDialog(SettingsService settings) {
    final controller = TextEditingController(text: settings.customPrompt.value);
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自定义提示词',
                style: TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '留空则使用默认提示词',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(UIConstants.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '输入自定义提示词...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        settings.saveCustomPrompt('');
                        Get.back();
                        Get.snackbar(
                          '已恢复',
                          '使用默认提示词',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text('恢复默认'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        settings.saveCustomPrompt(controller.text.trim());
                        Get.back();
                        Get.snackbar(
                          '已保存',
                          '自定义提示词已更新',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(UIConstants.accentColor),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAIAdvancedConfig(SettingsService settings) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI 高级配置',
                style: TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('API 地址'),
                subtitle: Obx(() => Text(
                  settings.aiApiUrl.value,
                  style: const TextStyle(fontSize: 12),
                )),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditAIUrlDialog(settings),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEditAIUrlDialog(SettingsService settings) {
    final controller = TextEditingController(text: settings.aiApiUrl.value);
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('修改 API 地址'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入 API 地址',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.saveAIApiUrl(controller.text.trim());
              Get.back();
              Get.snackbar(
                '已保存',
                'API 地址已更新',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '开源协议',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''MIT License

Copyright (c) 2024 GuYunReader

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''',
            style: TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
