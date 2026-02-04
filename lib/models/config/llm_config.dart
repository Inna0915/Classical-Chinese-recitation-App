/// LLM 服务商类型枚举
enum LlmProviderType {
  kimi,
  deepseek,
  volcengine,
  alibaba,
  openai,
  custom,
}

/// 扩展枚举方法
extension LlmProviderTypeExtension on LlmProviderType {
  String get displayName {
    switch (this) {
      case LlmProviderType.kimi:
        return 'Kimi';
      case LlmProviderType.deepseek:
        return 'DeepSeek';
      case LlmProviderType.volcengine:
        return '火山引擎';
      case LlmProviderType.alibaba:
        return '阿里百炼';
      case LlmProviderType.openai:
        return 'OpenAI';
      case LlmProviderType.custom:
        return '自定义';
    }
  }

  String get logoAsset {
    // Logo 文件路径，放在 assets/logos/ 目录下
    switch (this) {
      case LlmProviderType.kimi:
        return 'assets/logos/kimi.png';
      case LlmProviderType.deepseek:
        return 'assets/logos/deepseek.png';
      case LlmProviderType.volcengine:
        return 'assets/logos/volcengine.png';
      case LlmProviderType.alibaba:
        return 'assets/logos/alibaba.png';
      case LlmProviderType.openai:
        return 'assets/logos/openai.png';
      case LlmProviderType.custom:
        return 'assets/logos/custom.png';
    }
  }

  /// Logo 缩写（用于默认显示）
  String get logoInitial {
    switch (this) {
      case LlmProviderType.kimi:
        return 'Ki';
      case LlmProviderType.deepseek:
        return 'De';
      case LlmProviderType.volcengine:
        return 'Vo';
      case LlmProviderType.alibaba:
        return 'Al';
      case LlmProviderType.openai:
        return 'OA';
      case LlmProviderType.custom:
        return 'Cu';
    }
  }

  /// Logo 背景色
  int get brandColor {
    switch (this) {
      case LlmProviderType.kimi:
        return 0xFF4CAF50; // 绿色
      case LlmProviderType.deepseek:
        return 0xFF2196F3; // 蓝色
      case LlmProviderType.volcengine:
        return 0xFF9C27B0; // 紫色
      case LlmProviderType.alibaba:
        return 0xFFFF9800; // 橙色
      case LlmProviderType.openai:
        return 0xFF10A37F; // OpenAI 绿
      case LlmProviderType.custom:
        return 0xFF607D8B; // 蓝灰
    }
  }

  /// 默认 Base URL
  String get defaultBaseUrl {
    switch (this) {
      case LlmProviderType.kimi:
        return 'https://api.moonshot.cn/v1';
      case LlmProviderType.deepseek:
        return 'https://api.deepseek.com/v1';
      case LlmProviderType.volcengine:
        return 'https://ark.cn-beijing.volces.com/api/v3';
      case LlmProviderType.alibaba:
        return 'https://dashscope.aliyuncs.com/api/v1';
      case LlmProviderType.openai:
        return 'https://api.openai.com/v1';
      case LlmProviderType.custom:
        return '';
    }
  }

  /// 默认模型
  String get defaultModel {
    switch (this) {
      case LlmProviderType.kimi:
        return 'kimi-k2-turbo-preview';
      case LlmProviderType.deepseek:
        return 'deepseek-chat';
      case LlmProviderType.volcengine:
        return 'ep-xxxxxxxxx'; // 需要用户填写 Endpoint ID
      case LlmProviderType.alibaba:
        return 'qwen-turbo';
      case LlmProviderType.openai:
        return 'gpt-4o';
      case LlmProviderType.custom:
        return '';
    }
  }
}

/// 单个服务商配置
class LlmProviderConfig {
  String apiKey;
  String baseUrl;
  String currentModel;
  List<String> availableModels;
  bool isEnabled;
  String systemPrompt;
  String customName; // 自定义名称（用于 custom 类型）

  LlmProviderConfig({
    this.apiKey = '',
    this.baseUrl = '',
    this.currentModel = '',
    this.availableModels = const [],
    this.isEnabled = false,
    this.systemPrompt = '',
    this.customName = '',
  });

  factory LlmProviderConfig.fromJson(Map<String, dynamic> json) {
    return LlmProviderConfig(
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      currentModel: json['currentModel'] as String? ?? '',
      availableModels: (json['availableModels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isEnabled: json['isEnabled'] as bool? ?? false,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      customName: json['customName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'currentModel': currentModel,
        'availableModels': availableModels,
        'isEnabled': isEnabled,
        'systemPrompt': systemPrompt,
        'customName': customName,
      };

  /// 获取实际使用的 Base URL
  String get effectiveBaseUrl => baseUrl.isNotEmpty ? baseUrl : '';

  /// 获取实际使用的模型
  String get effectiveModel => currentModel.isNotEmpty ? currentModel : '';

  /// 检查配置是否完整
  bool get isConfigured => apiKey.isNotEmpty && effectiveBaseUrl.isNotEmpty;
}

/// 全局 LLM 配置
class GlobalLlmConfig {
  /// 当前活跃的服务商（用于诗词 AI 功能）
  LlmProviderType activeProvider;

  /// 所有服务商的配置映射
  Map<LlmProviderType, LlmProviderConfig> providerConfigs;

  GlobalLlmConfig({
    this.activeProvider = LlmProviderType.kimi,
    Map<LlmProviderType, LlmProviderConfig>? providerConfigs,
  }) : providerConfigs = providerConfigs ?? {};

  /// 获取指定服务商的配置（如果不存在则创建默认）
  LlmProviderConfig getProviderConfig(LlmProviderType type) {
    return providerConfigs.putIfAbsent(
      type,
      () => LlmProviderConfig(
        baseUrl: type.defaultBaseUrl,
        currentModel: type.defaultModel,
      ),
    );
  }

  /// 设置服务商配置
  void setProviderConfig(LlmProviderType type, LlmProviderConfig config) {
    providerConfigs[type] = config;
  }

  /// 获取当前活跃服务商的配置
  LlmProviderConfig get activeConfig => getProviderConfig(activeProvider);

  /// 获取所有已启用的服务商
  List<LlmProviderType> get enabledProviders {
    return providerConfigs.entries
        .where((e) => e.value.isEnabled)
        .map((e) => e.key)
        .toList();
  }

  factory GlobalLlmConfig.fromJson(Map<String, dynamic> json) {
    final activeStr = json['activeProvider'] as String? ?? 'kimi';
    final configsJson = json['providerConfigs'] as Map<String, dynamic>? ?? {};

    final configs = <LlmProviderType, LlmProviderConfig>{};
    for (final entry in configsJson.entries) {
      final type = _parseProviderType(entry.key);
      if (type != null) {
        configs[type] = LlmProviderConfig.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    return GlobalLlmConfig(
      activeProvider: _parseProviderType(activeStr) ?? LlmProviderType.kimi,
      providerConfigs: configs,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeProvider': activeProvider.name,
        'providerConfigs': providerConfigs.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
      };

  static LlmProviderType? _parseProviderType(String name) {
    try {
      return LlmProviderType.values.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }
}

/// 需要准备的 Logo 文件清单（放在 assets/logos/ 目录下）：
/// 
/// 必需文件：
/// - assets/logos/kimi.png        (Kimi Logo)
/// - assets/logos/deepseek.png    (DeepSeek Logo)
/// - assets/logos/volcengine.png  (火山引擎 Logo)
/// - assets/logos/alibaba.png     (阿里百炼 Logo)
/// - assets/logos/openai.png      (OpenAI Logo)
/// - assets/logos/custom.png      (自定义服务 Logo)
/// 
/// 如果图片文件不存在，组件会显示带背景色的缩写文字作为备用
/// 
/// pubspec.yaml 配置示例：
/// flutter:
///   assets:
///     - assets/logos/kimi.png
///     - assets/logos/deepseek.png
///     - assets/logos/volcengine.png
///     - assets/logos/alibaba.png
///     - assets/logos/openai.png
///     - assets/logos/custom.png
