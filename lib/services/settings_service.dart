import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ai_models.dart';
import '../constants/app_constants.dart';
import '../constants/tts_voices.dart';

/// 设置服务 - 管理应用配置
class SettingsService extends GetxService {
  static SettingsService get to => Get.find();
  
  late SharedPreferences _prefs;
  
  // ==================== TTS 配置 Keys ====================
  static const String _keyVoiceType = 'tts_voice_type';
  
  // ==================== AI 模型配置 Keys ====================
  static const String _keyAIProvider = 'ai_provider';
  static const String _keyAIApiKey = 'ai_api_key';
  static const String _keyAIApiUrl = 'ai_api_url';
  static const String _keyAIModel = 'ai_model';
  static const String _keyCustomPrompt = 'custom_prompt';
  
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

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    return this;
  }

  /// 加载设置
  void _loadSettings() {
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
