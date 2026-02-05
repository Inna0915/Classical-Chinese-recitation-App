import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/ai_models.dart';
import '../constants/ai_prompts.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../services/ai_service.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import '../widgets/dialogs/app_dialog.dart';

/// 添加作品页面
class AddPoemPage extends StatefulWidget {
  const AddPoemPage({super.key});

  @override
  State<AddPoemPage> createState() => _AddPoemPageState();
}

class _AddPoemPageState extends State<AddPoemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _cleanContentController = TextEditingController();
  final _annotatedContentController = TextEditingController();
  final _aiInputController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAIGenerating = false;
  bool _showManualForm = false; // 控制是否显示手动录入表单，默认收起
  String? _errorMessage;
  String? _aiRawResponse; // AI 原始返回内容


  
  final AIService _aiService = AIService();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    _cleanContentController.dispose();
    _annotatedContentController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }

  /// 解析作者信息（朝代信息包含在作者字段中）
  void _parseAuthorAndDynasty(String authorStr) {
    // 直接将完整的作者信息填入作者字段，不再单独解析朝代
    _authorController.text = authorStr.trim();
  }

  /// 保存作品
  Future<void> _savePoem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = DateTime.now().millisecondsSinceEpoch;
      
      // 如果没有 cleanContent，使用 content 作为 fallback
      final cleanContent = _cleanContentController.text.trim().isNotEmpty
          ? _cleanContentController.text.trim()
          : _contentController.text.trim();
      
      final poem = Poem(
        id: id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        cleanContent: cleanContent,
        annotatedContent: _annotatedContentController.text.trim().isNotEmpty
            ? _annotatedContentController.text.trim()
            : cleanContent,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insertPoem(poem, tagNames: []);
      
      if (mounted) {
        // 先关闭页面，避免卡顿
        Get.back();
        // 后台刷新数据
        Future.microtask(() => PoemController.to.loadPoems());
        
        AppDialog.success(
          title: '录入成功',
          message: '《${poem.title}》已录入书架',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 使用 AI 查询作品
  Future<void> _queryPoemWithAI() async {
    final input = _aiInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = '请先输入作品名称';
      });
      return;
    }

    setState(() {
      _isAIGenerating = true;
      _errorMessage = null;
      _aiRawResponse = null;
    });

    final result = await _aiService.queryPoem(input);

    if (mounted) {
      setState(() {
        _isAIGenerating = false;
      });
    }

    if (!result.isSuccess) {
      setState(() {
        _errorMessage = result.errorMessage;
      });
      return;
    }

    final poemData = result.poemData ?? {};
    
    setState(() {
      _showManualForm = true;
      if (poemData['title']?.isNotEmpty == true) {
        _titleController.text = poemData['title']!;
      }
      if (poemData['author']?.isNotEmpty == true) {
        _parseAuthorAndDynasty(poemData['author']!);
      }
      if (poemData['content']?.isNotEmpty == true) {
        _contentController.text = poemData['content']!;
      }
      if (poemData['cleanContent']?.isNotEmpty == true) {
        _cleanContentController.text = poemData['cleanContent']!;
      }
      if (poemData['annotatedContent']?.isNotEmpty == true) {
        _annotatedContentController.text = poemData['annotatedContent']!;
      }
      _aiRawResponse = result.content;
    });

    AppDialog.success(
      title: '查询成功',
      message: '已获取《${_titleController.text}》的内容',
    );
  }

  /// 显示 AI 配置对话框（同时支持切换供应商和模型）
  void _showAIConfigDialog() {
    final settings = SettingsService.to;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Text(
          'AI 配置',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 供应商选择
                Text(
                  '选择供应商',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Column(
                  children: AIModels.providers.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value.name),
                      subtitle: entry.key == 'kimi' 
                        ? const Text('已预设 API Key', style: TextStyle(fontSize: 11, color: Colors.green))
                        : null,
                      value: entry.key,
                      groupValue: settings.aiProvider.value,
                      activeColor: context.primaryColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (value) {
                        if (value != null) {
                          settings.saveAIProvider(value);
                        }
                      },
                    );
                  }).toList(),
                )),
                
                const Divider(height: 24),
                
                // 模型选择
                Text(
                  '选择模型',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final providerKey = settings.aiProvider.value;
                  final provider = AIModels.providers[providerKey];
                  List<String> models = [];
                  if (provider != null && provider.models.isNotEmpty) {
                    models = List.from(provider.models);
                  }
                  if (settings.aiModel.value.isNotEmpty && !models.contains(settings.aiModel.value)) {
                    models.add(settings.aiModel.value);
                  }
                  
                  return Column(
                    children: [
                      ...models.map((model) {
                        return RadioListTile<String>(
                          title: Text(model, style: const TextStyle(fontSize: 14)),
                          value: model,
                          groupValue: settings.aiModel.value,
                          activeColor: context.primaryColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          onChanged: (value) {
                            if (value != null) {
                              settings.saveAIModel(value);
                              Get.back();
                              AppDialog.success(
                                title: '切换成功',
                                message: '已切换到模型: $value',
                              );
                            }
                          },
                        );
                      }).toList(),
                      
                      // 手动输入模型
                      ListTile(
                        leading: const Icon(Icons.edit, size: 18),
                        title: const Text('手动输入模型', style: TextStyle(fontSize: 13)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onTap: () {
                          Get.back();
                          _showManualModelInput(settings);
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示编辑提示词对话框
  void _showEditPromptDialog() {
    final settings = SettingsService.to;
    final controller = TextEditingController(
      text: settings.customPrompt.value.isEmpty 
        ? AIPrompts.poemQuerySystemPrompt 
        : settings.customPrompt.value
    );
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '编辑提示词',
                style: TextStyle(
                  color: context.textPrimaryColor,
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
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '输入自定义提示词...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
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
              settings.saveCustomPrompt(controller.text.trim());
              Get.back();
              AppDialog.success(
                title: '保存成功',
                message: '提示词已更新',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 手动输入模型
  void _showManualModelInput(SettingsService settings) {
    final controller = TextEditingController(text: settings.aiModel.value);
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Text(
          '手动输入模型',
          style: TextStyle(
            color: context.textPrimaryColor,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入模型名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final model = controller.text.trim();
              if (model.isNotEmpty) {
                settings.saveAIModel(model);
                Get.back();
                AppDialog.success(
                  title: '切换成功',
                  message: '已切换到模型: $model',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.textPrimaryColor,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '添加作品',
          style: TextStyle(
            fontSize: FontConstants.titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  settings.hasAIConfig.value 
                    ? _buildAIQueryCard(context) 
                    : _buildAINotConfigCard(context),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
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
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (_aiRawResponse != null) ...[
                    const SizedBox(height: 16),
                    _buildAIResultPreview(context),
                  ],
                  
                  if (_showManualForm) ...[
                    const SizedBox(height: 24),
                    _buildManualForm(context),
                  ],
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          if (_showManualForm)
            Container(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePoem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '保存到书架',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// AI 查询卡片
  Widget _buildAIQueryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: context.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '文章查询',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
              // AI 配置按钮
              InkWell(
                onTap: () => _showAIConfigDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Text(
                        '${SettingsService.to.aiProvider.value.toUpperCase()} | ${SettingsService.to.aiModel.value.length > 10 ? '${SettingsService.to.aiModel.value.substring(0, 10)}...' : SettingsService.to.aiModel.value}',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.settings,
                        size: 14,
                        color: context.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '输入作品名称，AI 将为您查询原文、释义和生僻字注音',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _aiInputController,
            decoration: InputDecoration(
              hintText: '输入作品名称，如：静夜思、水调歌头...',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.primaryColor,
                ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              suffixIcon: _isAIGenerating
                  ? Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _aiInputController.clear(),
                    ),
            ),
          ),
          
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showEditPromptDialog(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 16,
                    color: context.primaryColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '编辑提示词',
                    style: TextStyle(
                      color: context.primaryColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isAIGenerating 
                ? null 
                : _queryPoemWithAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isAIGenerating 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search, size: 18),
              label: Text(
                _isAIGenerating ? '查询中...' : '查询作品',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          if (!_showManualForm)
            TextButton(
              onPressed: () {
                setState(() {
                  _showManualForm = true;
                });
              },
              child: const Text('展开手动录入'),
            ),
        ],
      ),
    );
  }

  /// AI 结果预览
  Widget _buildAIResultPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: context.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: context.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 查询结果',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _aiRawResponse = null;
                  });
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('关闭', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _aiRawResponse!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 手动录入表单
  Widget _buildManualForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '手动录入',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showManualForm = false;
                  });
                },
                icon: const Icon(Icons.expand_less, size: 18),
                label: const Text('收起', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            context: context,
            controller: _titleController,
            label: '作品标题',
            hint: '如：静夜思',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入作品标题';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            context: context,
            controller: _authorController,
            label: '作者',
            hint: '如：李白、杜甫（朝代信息选填）',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入作者姓名';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildContentField(context),
        ],
      ),
    );
  }

  /// AI 未配置提示卡片
  Widget _buildAINotConfigCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy_outlined,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 助手未配置',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '前往设置页面配置 AI 模型，即可使用智能查询功能',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed('/settings'),
            child: const Text('去配置'),
          ),
        ],
      ),
    );
  }

  /// 文本输入框
  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              icon,
              color: context.textSecondaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.primaryColor,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            filled: true,
          ),
        ),
      ],
    );
  }

  /// 内容输入框
  Widget _buildContentField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '作品内容',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _titleController.text = '示例作品';
                _authorController.text = '示例作者';
                _contentController.text = '这是第一句，\n这是第二句，\n这是第三句，\n这是第四句。';
              },
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('示例填充'),
              style: TextButton.styleFrom(
                foregroundColor: context.primaryColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contentController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入作品内容';
            }
            return null;
          },
          maxLines: 8,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 16,
            height: 1.8,
          ),
          decoration: InputDecoration(
            hintText: '输入作品内容，建议每句后换行...',
            hintStyle: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: context.primaryColor,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            filled: true,
          ),
        ),
      ],
    );
  }
}
