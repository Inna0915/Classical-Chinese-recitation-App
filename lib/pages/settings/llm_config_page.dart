import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/config/llm_config.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings/index.dart';
import 'llm_provider_detail_page.dart';

/// LLM 配置主页面 - 服务商列表（Cherry Studio 风格）
/// 
/// 设计特点：
/// - 极淡灰色背景
/// - 白色圆角卡片列表
/// - 每个卡片显示 Logo、名称、状态
/// - 点击进入详情页
class LlmConfigPage extends StatelessWidget {
  const LlmConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '模型服务商',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 说明文字
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                '选择并配置 AI 服务商，用于诗词翻译和讲解',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            // 服务商列表
            ...LlmProviderType.values.map((type) {
              return _buildProviderCard(type, settingsService);
            }),
            
            // 底部间距
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建服务商卡片
  Widget _buildProviderCard(LlmProviderType type, SettingsService service) {
    return Obx(() {
      final config = service.llmConfig.value.getProviderConfig(type);
      final isActive = service.llmConfig.value.activeProvider == type;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(() => LlmProviderDetailPage(providerType: type)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Logo
                  ProviderLogo(provider: type, size: 44),
                  const SizedBox(width: 16),
                  
                  // 名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getProviderDescription(type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 状态徽章
                  if (config.isEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isActive ? '使用中' : '已开启',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '未配置',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // 箭头
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 获取服务商描述
  String _getProviderDescription(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.kimi:
        return 'Moonshot Kimi 长文本大模型';
      case LlmProviderType.deepseek:
        return 'DeepSeek 深度求索大模型';
      case LlmProviderType.volcengine:
        return '字节跳动火山引擎';
      case LlmProviderType.alibaba:
        return '阿里云通义千问';
      case LlmProviderType.openai:
        return 'OpenAI GPT 系列';
      case LlmProviderType.custom:
        return '自定义 OpenAI 兼容服务';
    }
  }
}
