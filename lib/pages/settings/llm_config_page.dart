import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/ai_models.dart';
import '../../constants/ai_prompts.dart';
import '../../constants/app_constants.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/index.dart';

/// LLM 配置页面 - AI 模型服务商详细配置
class LlmConfigPage extends StatefulWidget {
  const LlmConfigPage({super.key});

  @override
  State<LlmConfigPage> createState() => _LlmConfigPageState();
}

class _LlmConfigPageState extends State<LlmConfigPage> {
  final SettingsService settingsService = SettingsService.to;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  
  bool _obscureApiKey = true;
  bool _isLoadingModels = false;
  List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _apiKeyController.text = settingsService.aiApiKey.value;
    _urlController.text = settingsService.aiApiUrl.value;
    _modelController.text = settingsService.aiModel.value;
    _promptController.text = settingsService.customPrompt.value;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    _promptController.dispose();
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
          '模型服务商配置',
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
            // 供应商选择
            _buildProviderSection(),
            
            // API Key
            _buildApiKeySection(),
            
            // 模型配置
            _buildModelSection(),
            
            // 自定义 URL
            _buildUrlSection(),
            
            // 自定义提示词
            _buildPromptSection(),
            
            // 重置按钮
            const SizedBox(height: 24),
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

  /// 供应商选择
  Widget _buildProviderSection() {
    return SettingsSection(
      title: '选择服务商',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AIModels.providers.entries.map((entry) {
              final key = entry.key;
              final config = entry.value;
              final isSelected = settingsService.aiProvider.value == key;
              
              return ChoiceChip(
                label: Text(config.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _changeProvider(key);
                  }
                },
                selectedColor: const Color(UIConstants.accentColor),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            }).toList(),
          )),
        ),
      ],
    );
  }

  /// API Key 配置
  Widget _buildApiKeySection() {
    return SettingsSection(
      title: 'API 密钥',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              hintText: '请输入 API Key',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 模型配置
  Widget _buildModelSection() {
    return SettingsSection(
      title: '模型配置',
      children: [
        // 当前模型
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: '当前模型 ID',
                        labelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(UIConstants.accentColor)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoadingModels ? null : _fetchModels,
                    icon: _isLoadingModels
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('获取列表'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(UIConstants.accentColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              
              // 可用模型列表
              if (_availableModels.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '可用模型：',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableModels.map((model) {
                    final isSelected = _modelController.text == model;
                    return ActionChip(
                      label: Text(
                        model,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _modelController.text = model;
                        });
                      },
                      backgroundColor: isSelected 
                          ? const Color(UIConstants.accentColor) 
                          : Colors.grey[100],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 自定义 URL
  Widget _buildUrlSection() {
    return SettingsSection(
      title: '自定义配置',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Base URL（可选）',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  hintText: '留空使用默认地址',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(UIConstants.accentColor)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '如需使用自定义代理或本地服务，可修改 Base URL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 自定义提示词
  Widget _buildPromptSection() {
    return SettingsSection(
      title: '自定义提示词',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _promptController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '输入自定义 System Prompt...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(UIConstants.accentColor)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              // 快速选择预设
              Text(
                '快速选择预设：',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PromptPresets.presets.entries.map((entry) {
                  return ActionChip(
                    label: Text(entry.value.name),
                    onPressed: () {
                      setState(() {
                        _promptController.text = entry.value.systemPrompt;
                      });
                    },
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 切换供应商
  void _changeProvider(String provider) {
    settingsService.saveAIProvider(provider);
    
    // 自动填充默认值
    final config = AIModels.providers[provider]!;
    setState(() {
      _urlController.text = config.apiUrl;
      _modelController.text = config.defaultModel;
    });
    
    Get.snackbar(
      '已切换',
      '当前服务商：${config.name}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 获取模型列表
  Future<void> _fetchModels() async {
    setState(() {
      _isLoadingModels = true;
      _availableModels = [];
    });

    try {
      // 临时保存当前配置
      await settingsService.saveAIApiKey(_apiKeyController.text);
      
      final models = await fetchModels();
      
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });

      if (models.isEmpty) {
        Get.snackbar(
          '提示',
          '未获取到可用模型列表',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingModels = false;
      });
      Get.snackbar(
        '获取失败',
        '无法获取模型列表: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    await settingsService.saveAIApiKey(_apiKeyController.text);
    await settingsService.saveAIModel(_modelController.text);
    await settingsService.saveAICustomUrl(_urlController.text);
    await settingsService.saveCustomPrompt(_promptController.text);

    Get.snackbar(
      '保存成功',
      'AI 配置已更新',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    Get.back();
  }

  /// 显示重置确认
  void _showResetConfirm() {
    Get.dialog(
      AlertDialog(
        title: const Text('恢复默认配置'),
        content: const Text('确定要恢复默认的 AI 配置吗？这将清除您自定义的 API Key 和模型设置。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsService.resetAIConfig();
              _loadSettings();
              Get.back();
              Get.snackbar(
                '已重置',
                'AI 配置已恢复为默认值',
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

/// 获取可用模型列表
Future<List<String>> fetchModels() async {
  // 这里应该调用实际的 API 获取模型列表
  // 暂时返回预设的模型列表
  final provider = SettingsService.to.aiProvider.value;
  final config = AIModels.providers[provider];
  return config?.models ?? [];
}
