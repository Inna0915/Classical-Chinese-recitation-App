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
    final ttsService = TtsService();

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
          
          // TTS API 配置区域
          _buildSectionTitle('语音合成配置（用于朗读）'),
          const SizedBox(height: 12),
          _buildApiConfigCard(settings),
          
          const SizedBox(height: 24),
          
          // 缓存管理
          _buildSectionTitle('缓存管理'),
          const SizedBox(height: 12),
          _buildCacheCard(ttsService),
          
          const SizedBox(height: 24),
          
          // 关于应用
          _buildSectionTitle('关于'),
          const SizedBox(height: 12),
          _buildAboutCard(),
        ],
      ),
    );
  }

  /// 章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(UIConstants.textSecondaryColor),
        fontSize: 13,
        fontWeight: FontWeight.w500,
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
          // 配置状态
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
                      : Icons.smart_toy_outlined,
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
                        settings.hasAIConfig.value
                            ? 'AI 模型已配置'
                            : 'AI 模型未配置',
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
                            ? '可以在录入诗词时使用 AI 生成'
                            : '配置后可使用 AI 自动生成诗词内容',
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
          
          // 提供商选择
          ListTile(
            leading: const Icon(
              Icons.account_balance_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('模型提供商'),
            subtitle: Obx(() => Text(
              AIModels.providers[settings.aiProvider.value]?.name ?? '自定义',
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAIProviderDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // API Key 设置
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
          
          // 模型选择
          Obx(() {
            final provider = AIModels.providers[settings.aiProvider.value];
            if (provider == null || provider.models.isEmpty) {
              return const SizedBox.shrink();
            }
            return ListTile(
              leading: const Icon(
                Icons.model_training_outlined,
                color: Color(UIConstants.textSecondaryColor),
              ),
              title: const Text('模型'),
              subtitle: Text(
                settings.aiModel.value,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAIModelDialog(settings),
            );
          }),
          
          // 提示词设置
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(
              Icons.text_snippet_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('提示词设置'),
            subtitle: const Text(
              '查看和修改 AI 查询提示词',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPromptEditor(settings),
          ),
          
          // 自定义模型输入（当选择自定义时）
          Obx(() {
            if (settings.aiProvider.value != 'custom') {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.link_outlined,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                  title: const Text('自定义 API 地址'),
                  subtitle: Text(
                    settings.aiApiUrl.value.isEmpty ? '未设置' : settings.aiApiUrl.value,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAIApiUrlDialog(settings),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                  title: const Text('自定义模型名称'),
                  subtitle: Text(
                    settings.aiModel.value.isEmpty ? '未设置' : settings.aiModel.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCustomModelDialog(settings),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// API 配置卡片
  Widget _buildApiConfigCard(SettingsService settings) {
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
              color: settings.hasConfig.value
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
                  settings.hasConfig.value
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: settings.hasConfig.value
                      ? Colors.green
                      : const Color(UIConstants.accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.hasConfig.value ? 'TTS 已配置' : 'TTS 未配置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: settings.hasConfig.value
                              ? Colors.green
                              : const Color(UIConstants.accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.hasConfig.value
                            ? '语音合成功能已就绪'
                            : '请配置 API Key 以使用朗读功能',
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
          
          // APP ID
          ListTile(
            leading: const Icon(
              Icons.app_registration,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('APP ID'),
            subtitle: Obx(() => Text(
              settings.appId.value.isEmpty ? '未设置' : settings.appId.value,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.appId.value));
                    Get.snackbar('已复制', 'APP ID 已复制到剪贴板', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showEditConfigDialog('APP ID', settings.appId.value, (v) => settings.saveAppId(v)),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Access Token
          ListTile(
            leading: const Icon(
              Icons.key,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('Access Token'),
            subtitle: Obx(() => Text(
              settings.apiKey.value.isEmpty ? '未设置' : settings.apiKey.value,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.apiKey.value));
                    Get.snackbar('已复制', 'Access Token 已复制到剪贴板', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showEditConfigDialog('Access Token', settings.apiKey.value, (v) => settings.saveAccessToken(v), isSecret: true),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Secret Key
          ListTile(
            leading: const Icon(
              Icons.lock_outline,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('Secret Key'),
            subtitle: Obx(() => Text(
              settings.secretKey.value.isEmpty ? '未设置' : settings.secretKey.value,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.secretKey.value));
                    Get.snackbar('已复制', 'Secret Key 已复制到剪贴板', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showEditConfigDialog('Secret Key', settings.secretKey.value, (v) => settings.saveSecretKey(v), isSecret: true),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Resource ID
          ListTile(
            leading: const Icon(
              Icons.folder_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('Resource ID'),
            subtitle: Obx(() => Text(
              settings.resourceId.value,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.resourceId.value));
                    Get.snackbar('已复制', 'Resource ID 已复制到剪贴板', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showEditConfigDialog('Resource ID', settings.resourceId.value, (v) => settings.saveResourceId(v)),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // TTS 连接测试按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
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
          ),
          
          // 查看调试日志按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: TextButton.icon(
                onPressed: () => _showTtsDebugLogs(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(UIConstants.textSecondaryColor),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.article_outlined, size: 16),
                label: const Text(
                  '查看调试日志',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(
              Icons.record_voice_over_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('朗读音色'),
            subtitle: Obx(() => Text(
              _getVoiceTypeName(settings.voiceType.value),
              style: const TextStyle(fontSize: 12),
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVoiceTypeDialog(settings),
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // 恢复默认配置按钮
          ListTile(
            leading: const Icon(
              Icons.restore,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: const Text('恢复默认配置'),
            subtitle: const Text(
              '重置为内置凭证',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showResetTtsConfigConfirm(settings),
          ),
        ],
      ),
    );
  }

  /// 缓存管理卡片
  Widget _buildCacheCard(TtsService ttsService) {
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
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          Obx(() {
            final controller = PoemController.to;
            final cachedCount = controller.poems
                .where((p) => p.localAudioPath != null)
                .length;
            
            return ListTile(
              leading: const Icon(
                Icons.headphones_outlined,
                color: Color(UIConstants.textSecondaryColor),
              ),
              title: const Text('已缓存音频'),
              subtitle: Text(
                '$cachedCount 首诗词',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: cachedCount > 0
                  ? TextButton(
                      onPressed: () => _showClearAllCacheConfirm(ttsService, controller),
                      child: const Text('全部清除'),
                    )
                  : null,
            );
          }),
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
              Icons.book_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: Text('应用版本'),
            subtitle: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const ListTile(
            leading: Icon(
              Icons.code_outlined,
              color: Color(UIConstants.textSecondaryColor),
            ),
            title: Text('技术栈'),
            subtitle: Text(
              'Flutter + GetX + SQLite + AI',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== AI 配置对话框 ====================

  void _showAIProviderDialog(SettingsService settings) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '选择模型提供商',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AIModels.providers.entries.map((entry) {
            return Obx(() => RadioListTile<String>(
              title: Text(entry.value.name),
              subtitle: Text(
                entry.value.apiUrl.isEmpty ? '自定义配置' : entry.value.apiUrl,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: entry.key,
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
          '配置 AI API Key',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前提供商: ${AIModels.providers[settings.aiProvider.value]?.name ?? "自定义"}',
              style: const TextStyle(
                color: Color(UIConstants.textSecondaryColor),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '输入 API Key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(UIConstants.accentColor),
                  ),
                ),
              ),
            ),
          ],
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
            onPressed: () {
              settings.saveAIApiKey(controller.text.trim());
              Get.back();
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
    final providerKey = settings.aiProvider.value;
    final availableModels = _dynamicModels[providerKey] ?? [];
    final searchController = TextEditingController();
    final customController = TextEditingController(text: 
      availableModels.contains(settings.aiModel.value) == true 
        ? '' 
        : settings.aiModel.value
    );

    // 过滤后的模型列表
    final filteredModels = availableModels.obs;

    void filterModels(String query) {
      if (query.isEmpty) {
        filteredModels.value = availableModels;
      } else {
        filteredModels.value = availableModels
          .where((model) => model.toLowerCase().contains(query.toLowerCase()))
          .toList();
      }
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                '选择模型',
                style: TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  color: Color(UIConstants.textPrimaryColor),
                ),
              ),
            ),
            // 刷新按钮
            if (settings.aiProvider.value != 'custom')
              TextButton.icon(
                onPressed: () => _syncModelsFromProvider(settings),
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('同步', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(UIConstants.accentColor),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索框
              if (availableModels.isNotEmpty) ...[
                TextField(
                  controller: searchController,
                  onChanged: filterModels,
                  decoration: InputDecoration(
                    hintText: '搜索模型...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        filterModels('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // 模型列表
              Flexible(
                child: Obx(() {
                  if (filteredModels.isEmpty && availableModels.isNotEmpty) {
                    return const Center(
                      child: Text('无匹配模型'),
                    );
                  }
                  if (availableModels.isEmpty) {
                    return const Center(
                      child: Text('暂无可用模型，请同步或手动输入'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredModels.length,
                    itemBuilder: (context, index) {
                      final model = filteredModels[index];
                      return Obx(() => RadioListTile<String>(
                        title: Text(model, style: const TextStyle(fontSize: 14)),
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
                    },
                  );
                }),
              ),
              
              // 手动输入区域
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '手动指定模型',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            decoration: InputDecoration(
                              hintText: '输入模型名称，如 gpt-4-turbo',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: const Color(UIConstants.textSecondaryColor).withOpacity(0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final model = customController.text.trim();
                            if (model.isNotEmpty) {
                              settings.saveAIModel(model);
                              Get.back();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(UIConstants.accentColor),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('使用'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIApiUrlDialog(SettingsService settings) {
    final controller = TextEditingController(text: settings.aiApiUrl.value);
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '配置 API 地址',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入 API URL',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.accentColor),
              ),
            ),
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
            onPressed: () {
              settings.saveAIApiUrl(controller.text.trim());
              Get.back();
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

  void _showCustomModelDialog(SettingsService settings) {
    final controller = TextEditingController(text: settings.aiModel.value);
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: const Text(
          '配置模型名称',
          style: TextStyle(
            fontFamily: FontConstants.chineseSerif,
            color: Color(UIConstants.textPrimaryColor),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '如: gpt-4, claude-3 等',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(UIConstants.accentColor),
              ),
            ),
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
            onPressed: () {
              settings.saveAIModel(controller.text.trim());
              Get.back();
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

  // ==================== 提示词编辑器 ====================
  
  void _showPromptEditor(SettingsService settings) {
    final controller = TextEditingController(
      text: settings.customPrompt.value.isEmpty 
        ? AIPrompts.poemQuerySystemPrompt 
        : settings.customPrompt.value
    );
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                '提示词设置',
                style: TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  color: Color(UIConstants.textPrimaryColor),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.text = AIPrompts.poemQuerySystemPrompt;
              },
              child: const Text('恢复默认', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自定义 AI 查询提示词：',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(UIConstants.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '输入自定义提示词...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(UIConstants.accentColor),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '提示：留空则使用默认提示词',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(UIConstants.textSecondaryColor),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
            onPressed: () {
              settings.saveCustomPrompt(controller.text.trim());
              Get.back();
              Get.snackbar(
                '保存成功',
                '提示词已更新',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
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

  // ==================== TTS 配置对话框 ====================

  /// 测试 TTS 连接
  void _testTTSConnection() async {
    final ttsService = TtsService();
    
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
              onPressed: () => Get.back(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  void _showVoiceTypeDialog(SettingsService settings) {
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
              label: const Text('添加', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: TtsVoices.allVoices.length,
            itemBuilder: (context, index) {
              final voice = TtsVoices.allVoices[index];
              final isCustom = TtsVoices.isCustomVoice(voice.voiceType);
              return Obx(() => RadioListTile<String>(
                title: Row(
                  children: [
                    Expanded(child: Text(voice.name)),
                    if (isCustom)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => _showDeleteCustomVoiceConfirm(voice, settings),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${voice.language} · ${voice.abilities.join('、')}',
                  style: const TextStyle(fontSize: 12),
                ),
                value: voice.voiceType,
                groupValue: settings.voiceType.value,
                activeColor: const Color(UIConstants.accentColor),
                onChanged: (value) {
                  if (value != null) {
                    settings.saveVoiceType(value);
                    Get.back();
                  }
                },
              ));
            },
          ),
        ),
      ),
    );
  }
  
  /// 显示添加自定义音色对话框
  void _showAddCustomVoiceDialog(SettingsService settings) {
    final nameController = TextEditingController();
    final voiceTypeController = TextEditingController();
    final languageController = TextEditingController(text: '中文');
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('添加自定义音色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '音色名称',
                  hintText: '如：我的自定义音色',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: voiceTypeController,
                decoration: const InputDecoration(
                  labelText: 'Voice Type',
                  hintText: '如：zh_female_xxx_bigtts',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: languageController,
                decoration: const InputDecoration(
                  labelText: '语言',
                  hintText: '如：中文',
                ),
              ),
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
              if (nameController.text.isEmpty || voiceTypeController.text.isEmpty) {
                Get.snackbar('错误', '请填写完整信息');
                return;
              }
              
              final voice = TtsVoice(
                name: nameController.text.trim(),
                voiceType: voiceTypeController.text.trim(),
                language: languageController.text.trim(),
                category: '自定义',
                abilities: ['指令遵循'],
              );
              
              try {
                await TtsVoices.addCustomVoice(voice);
                Get.back();
                Get.back(); // 关闭音色选择对话框
                _showVoiceTypeDialog(settings); // 重新打开刷新列表
                Get.snackbar('成功', '自定义音色已添加');
              } catch (e) {
                Get.snackbar('错误', e.toString());
              }
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
  
  /// 显示删除自定义音色确认
  void _showDeleteCustomVoiceConfirm(TtsVoice voice, SettingsService settings) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('删除自定义音色'),
        content: Text('确定要删除 "${voice.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TtsVoices.removeCustomVoice(voice.voiceType);
              // 如果当前选中的音色被删除，恢复为默认
              if (settings.voiceType.value == voice.voiceType) {
                settings.saveVoiceType(TtsConstants.defaultVoiceType);
              }
              Get.back();
              Get.back(); // 关闭音色选择对话框
              _showVoiceTypeDialog(settings); // 重新打开刷新列表
              Get.snackbar('成功', '自定义音色已删除');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ==================== 缓存管理对话框 ====================

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

  void _showClearAllCacheConfirm(TtsService ttsService, PoemController controller) {
    _showClearCacheConfirm(ttsService);
  }

  /// 从提供商同步最新模型列表
  void _syncModelsFromProvider(SettingsService settings) {
    // 各平台的最新模型列表（实际项目中应该从 API 获取）
    final Map<String, List<String>> latestModels = {
      'kimi': [
        'kimi-k2-turbo-preview',
        'moonshot-v1-8k',
        'moonshot-v1-32k',
        'moonshot-v1-128k',
        'moonshot-v1-auto',
      ],
      'deepseek': [
        'deepseek-chat',
        'deepseek-coder',
        'deepseek-reasoner',
      ],
      'qwen': [
        'qwen-turbo',
        'qwen-plus',
        'qwen-max',
        'qwen-max-longcontext',
        'qwen-coder-plus',
      ],
      'gemini': [
        'gemini-1.5-flash',
        'gemini-1.5-flash-latest',
        'gemini-1.5-pro',
        'gemini-1.5-pro-latest',
      ],
      'openai': [
        'gpt-3.5-turbo',
        'gpt-3.5-turbo-16k',
        'gpt-4',
        'gpt-4-turbo',
        'gpt-4o',
        'gpt-4o-mini',
      ],
    };

    final provider = settings.aiProvider.value;
    final models = latestModels[provider];
    
    if (models != null) {
      // 更新动态模型列表
      setState(() {
        _dynamicModels[provider] = models;
      });
      
      // 检查当前模型是否在新列表中
      if (!models.contains(settings.aiModel.value)) {
        // 如果不在，切换到第一个可用模型
        settings.saveAIModel(models.first);
      }
      
      Get.back(); // 先关闭当前对话框
      
      Get.snackbar(
        '同步成功',
        '已获取 ${AIModels.providers[provider]?.name} 最新 ${models.length} 个模型',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // 重新打开模型选择对话框显示更新后的列表
      Future.delayed(const Duration(milliseconds: 300), () {
        _showAIModelDialog(settings);
      });
    } else {
      Get.snackbar(
        '同步失败',
        '暂不支持同步该提供商的模型列表',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  String _getVoiceTypeName(String voiceType) {
    final voice = TtsVoices.getVoiceByType(voiceType);
    return voice?.name ?? voiceType;
  }


  void _showEditConfigDialog(
    String label,
    String currentValue,
    Function(String) onSave, {
    bool isSecret = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: Text('修改 $label'),
        content: TextField(
          controller: controller,
          obscureText: isSecret,
          decoration: InputDecoration(
            hintText: '输入 $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: isSecret ? 1 : 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Get.back();
              Get.snackbar(
                '已保存',
                '$label 已更新',
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

  void _showResetTtsConfigConfirm(SettingsService settings) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('恢复默认配置'),
        content: const Text('确定要恢复 TTS 默认配置吗？这将覆盖您自定义的设置。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetTtsConfig();
              Get.back();
              Get.snackbar(
                '已恢复',
                'TTS 配置已恢复为默认值',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }
  
  /// 显示 TTS 调试日志
  void _showTtsDebugLogs() {
    final ttsService = TtsService();
    final logs = ttsService.getLogList();
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: const BoxDecoration(
          color: Color(UIConstants.cardColor),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIConstants.defaultRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(UIConstants.dividerColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TTS 调试日志',
                    style: TextStyle(
                      fontFamily: FontConstants.chineseSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 复制按钮
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          final allLogs = ttsService.getLogs();
                          Clipboard.setData(ClipboardData(text: allLogs));
                          Get.snackbar(
                            '已复制',
                            '日志已复制到剪贴板',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        tooltip: '复制全部日志',
                      ),
                      // 清空按钮
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          ttsService.clearLogs();
                          Get.back();
                          Get.snackbar(
                            '已清空',
                            '日志已清空',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        tooltip: '清空日志',
                      ),
                      // 关闭按钮
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 日志内容
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无日志\n请先点击"测试 TTS 连接"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(UIConstants.textSecondaryColor),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // 深色背景模拟终端
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            // 根据日志内容设置颜色
                            Color logColor = const Color(0xFFD4D4D4); // 默认灰色
                            if (log.contains('失败') || log.contains('错误') || log.contains('异常')) {
                              logColor = const Color(0xFFF44336); // 红色
                            } else if (log.contains('成功')) {
                              logColor = const Color(0xFF4CAF50); // 绿色
                            } else if (log.contains('请求') || log.contains('Headers')) {
                              logColor = const Color(0xFF64B5F6); // 蓝色
                            } else if (log.contains('响应') || log.contains('Status')) {
                              logColor = const Color(0xFFFFB74D); // 橙色
                            }
                            
                            return SelectableText(
                              log,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: logColor,
                                height: 1.4,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // 提示文字
              if (logs.isNotEmpty)
                const Text(
                  '提示：日志会在每次测试时自动清空并重新记录',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(UIConstants.textSecondaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 显示 TTS 高级配置对话框
  void _showTtsAdvancedConfig(SettingsService settings) {
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(UIConstants.dividerColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TTS 高级配置',
                style: TextStyle(
                  fontFamily: FontConstants.chineseSerif,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '修改以下配置将影响语音合成功能',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(UIConstants.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildConfigItem(
                      'APP ID',
                      settings.appId.value,
                      Icons.app_registration,
                      (value) => settings.saveAppId(value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildConfigItem(
                      'Access Token',
                      settings.apiKey.value,
                      Icons.key,
                      (value) => settings.saveAccessToken(value),
                      isSecret: true,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildConfigItem(
                      'Secret Key',
                      settings.secretKey.value,
                      Icons.lock_outline,
                      (value) => settings.saveSecretKey(value),
                      isSecret: true,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildConfigItem(
                      'API URL',
                      settings.apiUrl.value,
                      Icons.link,
                      (value) => settings.saveApiUrl(value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildConfigItem(
                      'Resource ID',
                      settings.resourceId.value,
                      Icons.folder_outlined,
                      (value) => settings.saveResourceId(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        _showResetTtsConfigConfirm(settings);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('恢复默认'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(UIConstants.accentColor),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('完成'),
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

  Widget _buildConfigItem(
    String label,
    String value,
    IconData icon,
    Function(String) onSave, {
    bool isSecret = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(UIConstants.textSecondaryColor)),
      title: Text(label),
      subtitle: Text(
        isSecret ? '\${value.substring(0, value.length > 8 ? 8 : value.length)}****' : value,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar(
                '已复制',
                '\$label 已复制到剪贴板',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showEditConfigDialog(label, value, onSave, isSecret: isSecret),
    );
  }

  void _showEditConfigDialog(
    String label,
    String currentValue,
    Function(String) onSave, {
    bool isSecret = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: Text('修改 \$label'),
        content: TextField(
          controller: controller,
          obscureText: isSecret,
          decoration: InputDecoration(
            hintText: '输入 \$label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: isSecret ? 1 : 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Get.back();
              Get.snackbar(
                '已保存',
                '\$label 已更新',
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

  void _showResetTtsConfigConfirm(SettingsService settings) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        title: const Text('恢复默认配置'),
        content: const Text('确定要恢复 TTS 默认配置吗？这将覆盖您自定义的设置。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetTtsConfig();
              Get.back();
              Get.snackbar(
                '已恢复',
                'TTS 配置已恢复为默认值',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }
}
