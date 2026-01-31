/// 大语言模型配置常量
/// 
/// 内置支持的主流大模型配置
class AIModels {
  /// 模型提供商配置
  static const Map<String, AIModelConfig> providers = {
    'kimi': AIModelConfig(
      name: 'Kimi',
      apiUrl: 'https://api.moonshot.cn/v1/chat/completions',
      defaultModel: 'kimi-k2-turbo-preview',
      models: ['kimi-k2-turbo-preview', 'moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
    ),
    'deepseek': AIModelConfig(
      name: 'DeepSeek',
      apiUrl: 'https://api.deepseek.com/v1/chat/completions',
      defaultModel: 'deepseek-chat',
      models: ['deepseek-chat', 'deepseek-coder'],
    ),
    'qwen': AIModelConfig(
      name: '通义千问',
      apiUrl: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation',
      defaultModel: 'qwen-turbo',
      models: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
    ),
    'gemini': AIModelConfig(
      name: 'Gemini',
      apiUrl: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
      defaultModel: 'gemini-pro',
      models: ['gemini-pro', 'gemini-pro-vision'],
    ),
    'openai': AIModelConfig(
      name: 'OpenAI',
      apiUrl: 'https://api.openai.com/v1/chat/completions',
      defaultModel: 'gpt-3.5-turbo',
      models: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
    ),
    'custom': AIModelConfig(
      name: '自定义',
      apiUrl: '',
      defaultModel: '',
      models: [],
    ),
  };
}

/// 模型配置类
class AIModelConfig {
  final String name;
  final String apiUrl;
  final String defaultModel;
  final List<String> models;

  const AIModelConfig({
    required this.name,
    required this.apiUrl,
    required this.defaultModel,
    required this.models,
  });
}

/// 提示词预设
class PromptPresets {
  /// 内置提示词预设
  static const Map<String, PromptPreset> presets = {
    'title': PromptPreset(
      name: '生成标题',
      description: '根据主题或内容生成诗词标题',
      systemPrompt: '你是一个专业的古诗词创作助手。请根据用户提供的主题或内容，生成一个恰当的诗词标题。标题要简洁、有意境，符合古诗词的风格。只返回标题，不要返回其他内容。',
      userPromptTemplate: '请为以下内容或主题生成一个诗词标题：\n\n{content}',
    ),
    'content': PromptPreset(
      name: '生成正文',
      description: '根据标题或主题生成诗词内容',
      systemPrompt: '你是一个专业的古诗词创作助手。请根据用户提供的标题或主题，创作一首优美的古诗词。注意格律、意境和用词。只返回诗词正文，不要返回解释或其他内容。',
      userPromptTemplate: '请根据以下内容或主题创作一首古诗词：\n\n{content}',
    ),
    'complete': PromptPreset(
      name: '完整创作',
      description: '根据主题生成完整的诗词（含标题）',
      systemPrompt: '你是一个专业的古诗词创作助手。请根据用户提供的主题，创作一首完整的古诗词，包含标题和正文。注意格律、意境和用词。请按以下格式返回：\n标题：XXX\n正文：XXX',
      userPromptTemplate: '请以"{content}"为主题，创作一首古诗词。',
    ),
    'polish': PromptPreset(
      name: '润色优化',
      description: '润色优化现有诗词',
      systemPrompt: '你是一个专业的古诗词润色专家。请对用户提供的诗词进行润色优化，保留原意但提升意境和用词。返回优化后的完整诗词。',
      userPromptTemplate: '请润色优化以下诗词：\n\n{content}',
    ),
    'explain': PromptPreset(
      name: '诗词赏析',
      description: '对诗词进行赏析解读',
      systemPrompt: '你是一个古诗词鉴赏专家。请对用户提供的诗词进行赏析解读，包括创作背景、意境分析、用词技巧等方面。',
      userPromptTemplate: '请对以下诗词进行赏析解读：\n\n{content}',
    ),
  };
}

/// 提示词预设类
class PromptPreset {
  final String name;
  final String description;
  final String systemPrompt;
  final String userPromptTemplate;

  const PromptPreset({
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.userPromptTemplate,
  });

  /// 渲染用户提示词
  String renderUserPrompt(String content) {
    return userPromptTemplate.replaceAll('{content}', content);
  }
}
