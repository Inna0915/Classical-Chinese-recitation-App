import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ai_models.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';
import '../core/theme/app_theme.dart';
import '../models/config/llm_config.dart';

/// 设置服务 - 管理应用配置
class SettingsService extends GetxService {
  static SettingsService get to => Get.find();
  
  late SharedPreferences _prefs;
  
  // ==================== 外观配置 Keys ====================
  static const String _keyUseSystemFont = 'use_system_font';
  static const String _keyPrimaryColor = 'primary_color';
  static const String _keyThemeMode = 'theme_mode';
  
  // ==================== TTS 配置 Keys ====================
  static const String _keyVoiceType = 'tts_voice_type';
  
  // ==================== AI 模型配置 Keys ====================
  static const String _keyAIProvider = 'ai_provider';
  static const String _keyAIApiKey = 'ai_api_key';
  static const String _keyAIApiUrl = 'ai_api_url';
  static const String _keyAIModel = 'ai_model';
  static const String _keyCustomPrompt = 'custom_prompt';
  static const String _keyLlmConfig = 'llm_config'; // 新的多服务商配置
  
  // ==================== 外观 Observable 配置项 ====================
  /// 是否使用系统字体
  final RxBool useSystemFont = true.obs;
  
  /// 当前主题色
  final Rx<Color> primaryColor = TraditionalChineseColors.cinnabar.obs;
  
  /// 当前主题模式
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  // ==================== TTS Observable 配置项 ====================
  /// 当前选择的音色
  final RxString voiceType = TtsVoices.defaultVoice.obs;
  /// 语速 [-50, 100]
  final RxInt speechRate = 0.obs;
  /// 音量 [-50, 100]
  final RxInt loudnessRate = 0.obs;
  /// 是否有配置（已内置，始终为 true）
  final RxBool hasConfig = true.obs;

  // ==================== AI Observable 配置项 ====================
  final RxString aiProvider = 'kimi'.obs;
  final RxString aiApiKey = ''.obs;
  final RxString aiApiUrl = ''.obs;
  final RxString aiModel = ''.obs;
  final RxString customPrompt = ''.obs;
  final RxBool hasAIConfig = false.obs;
  
  // ==================== 新的多服务商 LLM 配置 ====================
  /// 全局 LLM 配置（多服务商）
  final Rx<GlobalLlmConfig> llmConfig = GlobalLlmConfig().obs;
  
  /// 获取当前字体
  String? get currentFontFamily => useSystemFont.value ? null : FontConstants.chineseSerif;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    return this;
  }

  /// 加载设置
  void _loadSettings() {
    // 外观配置
    useSystemFont.value = _prefs.getBool(_keyUseSystemFont) ?? true;
    
    // 主题颜色
    final colorValue = _prefs.getInt(_keyPrimaryColor);
    if (colorValue != null) {
      primaryColor.value = Color(colorValue);
    }
    
    // 主题模式
    final modeIndex = _prefs.getInt(_keyThemeMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      themeMode.value = ThemeMode.values[modeIndex];
    }
    
    // TTS 配置 - 只加载音色和语音参数
    voiceType.value = _prefs.getString(_keyVoiceType) ?? TtsVoices.defaultVoice;
    speechRate.value = _prefs.getInt('tts_speech_rate') ?? 0;
    loudnessRate.value = _prefs.getInt('tts_loudness_rate') ?? 0;
    hasConfig.value = true; // 已内置配置
    
    // AI 配置 - 只在 provider 是 kimi 时预设 API Key
    aiProvider.value = _prefs.getString(_keyAIProvider) ?? 'kimi';
    
    // 根据 provider 决定是否预设 API Key
    final savedProvider = aiProvider.value;
    if (savedProvider == 'kimi') {
      // Kimi 预设
      aiApiKey.value = _prefs.getString(_keyAIApiKey) ?? 'sk-ChamvmW4vYwSPXwuXOa1ViZuU4TgHMFOJxNRkFfvXm5aJ2F2';
      aiApiUrl.value = _prefs.getString(_keyAIApiUrl) ?? 'https://api.moonshot.cn/v1/chat/completions';
      aiModel.value = _prefs.getString(_keyAIModel) ?? 'kimi-k2-turbo-preview';
    } else {
      // 其他模型不预设，从配置读取或留空
      aiApiKey.value = _prefs.getString(_keyAIApiKey) ?? '';
      aiApiUrl.value = _prefs.getString(_keyAIApiUrl) ?? '';
      aiModel.value = _prefs.getString(_keyAIModel) ?? '';
    }
    
    customPrompt.value = _prefs.getString(_keyCustomPrompt) ?? '';
    hasAIConfig.value = aiApiKey.value.isNotEmpty;
    
    // 如果没有设置模型，使用默认模型
    if (aiModel.value.isEmpty) {
      final provider = AIModels.providers[aiProvider.value];
      if (provider != null) {
        aiModel.value = provider.defaultModel;
        aiApiUrl.value = provider.apiUrl;
      }
    }
    
    // 如果 URL 为空，使用默认
    if (aiApiUrl.value.isEmpty) {
      final provider = AIModels.providers[aiProvider.value];
      if (provider != null) {
        aiApiUrl.value = provider.apiUrl;
      }
    }
    
    // 加载新的多服务商 LLM 配置
    _loadLlmConfig();
  }
  
  /// 加载多服务商 LLM 配置
  void _loadLlmConfig() {
    final configJson = _prefs.getString(_keyLlmConfig);
    if (configJson != null) {
      try {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        llmConfig.value = GlobalLlmConfig.fromJson(configMap);
      } catch (e) {
        debugPrint('加载 LLM 配置失败: $e');
        _initDefaultLlmConfig();
      }
    } else {
      // 从旧配置迁移
      _initDefaultLlmConfig();
    }
  }
  
  /// 初始化默认 LLM 配置（迁移旧配置）
  void _initDefaultLlmConfig() {
    final config = GlobalLlmConfig(
      activeProvider: LlmProviderType.kimi,
    );
    
    // 迁移 Kimi 配置
    final kimiConfig = config.getProviderConfig(LlmProviderType.kimi);
    kimiConfig.apiKey = 'sk-ChamvmW4vYwSPXwuXOa1ViZuU4TgHMFOJxNRkFfvXm5aJ2F2';
    kimiConfig.baseUrl = 'https://api.moonshot.cn/v1';
    kimiConfig.currentModel = 'kimi-k2-turbo-preview';
    kimiConfig.isEnabled = true;
    
    llmConfig.value = config;
    _saveLlmConfig();
  }
  
  /// 保存 LLM 配置到本地
  Future<void> _saveLlmConfig() async {
    final configJson = jsonEncode(llmConfig.value.toJson());
    await _prefs.setString(_keyLlmConfig, configJson);
  }

  // ==================== 外观配置方法 ====================
  
  /// 保存是否使用系统字体
  Future<void> saveUseSystemFont(bool use) async {
    await _prefs.setBool(_keyUseSystemFont, use);
    useSystemFont.value = use;
  }
  
  /// 保存主题颜色
  Future<void> savePrimaryColor(Color color) async {
    await _prefs.setInt(_keyPrimaryColor, color.value);
    primaryColor.value = color;
  }
  
  /// 保存主题模式
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, mode.index);
    themeMode.value = mode;
  }
  
  /// 获取当前是否为深色模式（考虑系统设置）
  bool get isDarkMode {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    // 跟随系统
    return Get.isPlatformDarkMode;
  }

  // ==================== TTS 配置方法 ====================
  
  /// 保存音色类型
  Future<void> saveVoiceType(String voice) async {
    await _prefs.setString(_keyVoiceType, voice);
    voiceType.value = voice;
  }
  
  /// 保存语速
  Future<void> saveSpeechRate(int rate) async {
    await _prefs.setInt('tts_speech_rate', rate);
    speechRate.value = rate;
  }
  
  /// 保存音量
  Future<void> saveLoudnessRate(int rate) async {
    await _prefs.setInt('tts_loudness_rate', rate);
    loudnessRate.value = rate;
  }
  
  /// 重置 TTS 配置为默认值 - 只重置音色和语音参数
  Future<void> resetTtsConfig() async {
    await _prefs.remove(_keyVoiceType);
    await _prefs.remove('tts_speech_rate');
    await _prefs.remove('tts_loudness_rate');
    
    voiceType.value = TtsVoices.defaultVoice;
    speechRate.value = 0;
    loudnessRate.value = 0;
  }

  // ==================== AI 配置方法 ====================
  
  /// 保存 AI 提供商
  Future<void> saveAIProvider(String provider) async {
    await _prefs.setString(_keyAIProvider, provider);
    aiProvider.value = provider;
    
    // 切换提供商时，自动更新默认模型和 URL
    final config = AIModels.providers[provider];
    if (config != null) {
      if (aiModel.value.isEmpty || !config.models.contains(aiModel.value)) {
        aiModel.value = config.defaultModel;
        await _prefs.setString(_keyAIModel, config.defaultModel);
      }
      aiApiUrl.value = config.apiUrl;
      await _prefs.setString(_keyAIApiUrl, config.apiUrl);
    }
    
    // 切换供应商时的 API Key 处理
    if (provider == 'kimi') {
      // 切换回 Kimi 时，恢复预设 API Key（如果当前没有设置或为空）
      if (aiApiKey.value.isEmpty) {
        aiApiKey.value = 'sk-ChamvmW4vYwSPXwuXOa1ViZuU4TgHMFOJxNRkFfvXm5aJ2F2';
        await _prefs.setString(_keyAIApiKey, aiApiKey.value);
        hasAIConfig.value = true;
      }
    } else {
      // 切换到非 Kimi 供应商时，如果当前是 Kimi 预设 key，则清空
      if (aiApiKey.value == 'sk-ChamvmW4vYwSPXwuXOa1ViZuU4TgHMFOJxNRkFfvXm5aJ2F2') {
        aiApiKey.value = '';
        await _prefs.setString(_keyAIApiKey, '');
        hasAIConfig.value = false;
      }
    }
  }

  /// 保存 AI API Key
  Future<void> saveAIApiKey(String key) async {
    await _prefs.setString(_keyAIApiKey, key);
    aiApiKey.value = key;
    hasAIConfig.value = key.isNotEmpty;
  }

  /// 保存 AI API URL
  Future<void> saveAIApiUrl(String url) async {
    await _prefs.setString(_keyAIApiUrl, url);
    aiApiUrl.value = url;
  }

  /// 保存 AI 模型
  Future<void> saveAIModel(String model) async {
    await _prefs.setString(_keyAIModel, model);
    aiModel.value = model;
  }

  /// 保存自定义提示词
  Future<void> saveCustomPrompt(String prompt) async {
    await _prefs.setString(_keyCustomPrompt, prompt);
    customPrompt.value = prompt;
  }
  
  /// 保存自定义 URL（兼容方法）
  Future<void> saveAICustomUrl(String url) async {
    if (url.isNotEmpty) {
      await _prefs.setString(_keyAIApiUrl, url);
      aiApiUrl.value = url;
    }
  }
  
  /// 重置 AI 配置
  Future<void> resetAIConfig() async {
    await _prefs.remove(_keyAIProvider);
    await _prefs.remove(_keyAIApiKey);
    await _prefs.remove(_keyAIApiUrl);
    await _prefs.remove(_keyAIModel);
    await _prefs.remove(_keyCustomPrompt);
    
    aiProvider.value = 'kimi';
    aiApiKey.value = 'sk-ChamvmW4vYwSPXwuXOa1ViZuU4TgHMFOJxNRkFfvXm5aJ2F2';
    aiApiUrl.value = 'https://api.moonshot.cn/v1/chat/completions';
    aiModel.value = 'kimi-k2-turbo-preview';
    customPrompt.value = '';
    hasAIConfig.value = true;
    
    // 保存默认值
    await _prefs.setString(_keyAIProvider, 'kimi');
    await _prefs.setString(_keyAIApiKey, aiApiKey.value);
    await _prefs.setString(_keyAIApiUrl, aiApiUrl.value);
    await _prefs.setString(_keyAIModel, aiModel.value);
  }

  // ==================== 新的多服务商 LLM 配置方法 ====================
  
  /// 获取指定服务商的配置
  LlmProviderConfig getLlmProviderConfig(LlmProviderType type) {
    return llmConfig.value.getProviderConfig(type);
  }
  
  /// 保存服务商配置
  Future<void> saveLlmProviderConfig(LlmProviderType type, LlmProviderConfig config) async {
    llmConfig.value.setProviderConfig(type, config);
    await _saveLlmConfig();
  }
  
  /// 设置当前活跃的服务商
  Future<void> setActiveLlmProvider(LlmProviderType type) async {
    llmConfig.value.activeProvider = type;
    await _saveLlmConfig();
    
    // 同步更新旧配置（兼容）
    aiProvider.value = type.name;
    final config = llmConfig.value.getProviderConfig(type);
    aiApiKey.value = config.apiKey;
    aiApiUrl.value = config.baseUrl;
    aiModel.value = config.currentModel;
    customPrompt.value = config.systemPrompt;
    hasAIConfig.value = config.isEnabled && config.apiKey.isNotEmpty;
  }

  // ==================== 清除配置 ====================
  
  /// 清除所有设置
  Future<void> clearSettings() async {
    await _prefs.clear();
    
    // 重置 TTS
    voiceType.value = TtsVoices.defaultVoice;
    speechRate.value = 0;
    loudnessRate.value = 0;
    hasConfig.value = true;
    
    // 重置 AI
    aiProvider.value = 'kimi';
    aiApiKey.value = '';
    aiApiUrl.value = '';
    aiModel.value = '';
    customPrompt.value = '';
    hasAIConfig.value = false;
  }
}
