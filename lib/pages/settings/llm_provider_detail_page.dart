import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../models/config/llm_config.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/index.dart';

/// LLM 服务商详情页 - 单独配置每个服务商
/// 
/// 设计特点：
/// - Inset Grouped 风格
/// - 启用开关、API Key、Base URL、模型选择、系统提示词
class LlmProviderDetailPage extends StatefulWidget {
  final LlmProviderType providerType;

  const LlmProviderDetailPage({
    super.key,
    required this.providerType,
  });

  @override
  State<LlmProviderDetailPage> createState() => _LlmProviderDetailPageState();
}

class _LlmProviderDetailPageState extends State<LlmProviderDetailPage> {
  final SettingsService settingsService = SettingsService.to;
  late LlmProviderConfig _config;
  
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  
  bool _obscureApiKey = true;
  bool _isLoadingModels = false;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    _config = settingsService.llmConfig.value.getProviderConfig(widget.providerType);
    _apiKeyController.text = _config.apiKey;
    _baseUrlController.text = _config.baseUrl.isNotEmpty 
        ? _config.baseUrl 
        : widget.providerType.defaultBaseUrl;
    _customModelController.text = _config.currentModel;
    _promptController.text = _config.systemPrompt;
    _isEnabled = _config.isEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
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
        title: Text(
          widget.providerType.displayName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveConfig,
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
            // 头部 Logo 和名称
            _buildHeader(),
            
            // 启用开关
            _buildEnableSection(),
            
            // 鉴权信息
            _buildAuthSection(),
            
            // 模型配置
            _buildModelSection(),
            
            // 系统提示词
            _buildPromptSection(),
            
            // 设为默认按钮
            if (_isEnabled && settingsService.llmConfig.value.activeProvider != widget.providerType)
              _buildSetDefaultButton(),
          ],
        ),
      ),
    );
  }

  /// 头部区域
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          ProviderLogo(provider: widget.providerType, size: 64),
          const SizedBox(height: 12),
          Text(
            widget.providerType.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.providerType.defaultBaseUrl,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 启用开关
  Widget _buildEnableSection() {
    return SettingsSection(
      title: '服务状态',
      children: [
        SwitchListTile(
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
          title: const Text('启用此服务'),
          subtitle: Text(
            _isEnabled 
                ? '该服务可用于诗词 AI 功能' 
                : '开启后才能使用此服务',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          activeColor: const Color(UIConstants.accentColor),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ],
    );
  }

  /// 鉴权信息
  Widget _buildAuthSection() {
    return SettingsSection(
      title: '鉴权信息',
      children: [
        // API Key
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Key',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                enabled: _isEnabled,
                decoration: InputDecoration(
                  hintText: '请输入 API Key',
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
            ],
          ),
        ),
        
        const Divider(height: 1, indent: 16, endIndent: 16),
        
        // Base URL
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Host / Base URL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrlController,
                enabled: _isEnabled,
                decoration: InputDecoration(
                  hintText: widget.providerType.defaultBaseUrl,
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
              const SizedBox(height: 4),
              Text(
                '留空使用官方默认地址',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
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
                    child: Text(
                      '当前模型',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isEnabled && !_isLoadingModels ? _fetchModels : null,
                    icon: _isLoadingModels
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('获取列表'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(UIConstants.accentColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 模型输入框
              TextField(
                controller: _customModelController,
                enabled: _isEnabled,
                decoration: InputDecoration(
                  hintText: widget.providerType.defaultModel,
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
                  suffixIcon: _config.availableModels.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: _isEnabled ? _showModelSelector : null,
                        )
                      : null,
                ),
              ),
              
              // 可用模型列表
              if (_config.availableModels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _config.availableModels.map((model) {
                    final isSelected = _customModelController.text == model;
                    return ActionChip(
                      label: Text(
                        model,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      onPressed: _isEnabled
                          ? () {
                              setState(() {
                                _customModelController.text = model;
                              });
                            }
                          : null,
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

  /// 系统提示词
  Widget _buildPromptSection() {
    return SettingsSection(
      title: '系统提示词',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _promptController,
                enabled: _isEnabled,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '输入自定义 System Prompt...\n例如：你是一位古诗词专家，擅长赏析和翻译古典诗词。',
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
              const SizedBox(height: 8),
              Text(
                '自定义 AI 的角色和行为方式',
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

  /// 设为默认按钮
  Widget _buildSetDefaultButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ElevatedButton.icon(
        onPressed: _setAsDefault,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('设为默认服务商'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(UIConstants.accentColor),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 获取模型列表
  Future<void> _fetchModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    // 模拟获取模型列表
    await Future.delayed(const Duration(seconds: 1));

    final defaultModels = _getDefaultModelsForProvider(widget.providerType);
    
    setState(() {
      _config.availableModels = defaultModels;
      _isLoadingModels = false;
    });

    Get.snackbar(
      '获取成功',
      '已加载 ${defaultModels.length} 个可用模型',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 获取服务商默认模型列表
  List<String> _getDefaultModelsForProvider(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.kimi:
        return ['kimi-k2-turbo-preview', 'moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'];
      case LlmProviderType.deepseek:
        return ['deepseek-chat', 'deepseek-coder', 'deepseek-reasoner'];
      case LlmProviderType.volcengine:
        return ['doubao-lite-4k', 'doubao-pro-4k', 'doubao-pro-32k'];
      case LlmProviderType.alibaba:
        return ['qwen-turbo', 'qwen-plus', 'qwen-max'];
      case LlmProviderType.openai:
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case LlmProviderType.custom:
        return [];
    }
  }

  /// 显示模型选择器
  void _showModelSelector() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择模型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _config.availableModels.length,
                  itemBuilder: (context, index) {
                    final model = _config.availableModels[index];
                    final isSelected = _customModelController.text == model;
                    return ListTile(
                      title: Text(model),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(UIConstants.accentColor))
                          : null,
                      onTap: () {
                        setState(() {
                          _customModelController.text = model;
                        });
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 设为默认服务商
  void _setAsDefault() {
    settingsService.setActiveLlmProvider(widget.providerType);
    Get.snackbar(
      '设置成功',
      '${widget.providerType.displayName} 已设为默认服务商',
      snackPosition: SnackPosition.BOTTOM,
    );
    setState(() {});
  }

  /// 保存配置
  void _saveConfig() {
    final newConfig = LlmProviderConfig(
      apiKey: _apiKeyController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      currentModel: _customModelController.text.trim(),
      availableModels: _config.availableModels,
      isEnabled: _isEnabled,
      systemPrompt: _promptController.text.trim(),
    );

    settingsService.saveLlmProviderConfig(widget.providerType, newConfig);
    
    Get.snackbar(
      '保存成功',
      '${widget.providerType.displayName} 配置已更新',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    Get.back();
  }
}
