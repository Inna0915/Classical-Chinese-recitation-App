/// 火山引擎 TTS 音色列表 - 豆包语音合成模型 2.0
/// 文档: https://www.volcengine.com/docs/6561/1257544

<<<<<<< HEAD
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

=======
>>>>>>> ffe1c78b74edfd90ad6a3dce3049b871fef80d2a
/// 音色信息模型
class TtsVoice {
  final String name;
  final String voiceType;
  final String language;
  final String category;
  final List<String> abilities;
  final String? description;

  const TtsVoice({
    required this.name,
    required this.voiceType,
    required this.language,
    required this.category,
    required this.abilities,
    this.description,
  });
}

/// 音色分类
class TtsVoiceCategories {
  static const String general = '通用场景';
  static const String audiobook = '有声阅读';
  static const String video = '视频配音';
  static const String roleplay = '角色扮演';
}

/// 豆包语音合成模型 2.0 音色列表
class TtsVoices {
  // ==================== 通用场景 ====================
  static const TtsVoice vivi2 = TtsVoice(
    name: 'Vivi 2.0',
    voiceType: 'zh_female_vv_uranus_bigtts',
    language: '中文、英语',
    category: TtsVoiceCategories.general,
    abilities: ['情感变化', '指令遵循', 'ASMR'],
    description: '温柔女声，适合通用场景',
  );

  static const TtsVoice xiaohe2 = TtsVoice(
    name: '小何 2.0',
    voiceType: 'zh_female_xiaohe_uranus_bigtts',
    language: '中文',
    category: TtsVoiceCategories.general,
    abilities: ['情感变化', '指令遵循', 'ASMR'],
    description: '知性女声',
  );

  static const TtsVoice yunzhou2 = TtsVoice(
    name: '云舟 2.0',
    voiceType: 'zh_male_m191_uranus_bigtts',
    language: '中文',
    category: TtsVoiceCategories.general,
    abilities: ['情感变化', '指令遵循', 'ASMR'],
    description: '磁性男声',
  );

  static const TtsVoice xiaotian2 = TtsVoice(
    name: '小天 2.0',
    voiceType: 'zh_male_taocheng_uranus_bigtts',
    language: '中文',
    category: TtsVoiceCategories.general,
    abilities: ['情感变化', '指令遵循', 'ASMR'],
    description: '阳光男声',
  );

  // ==================== 有声阅读 ====================
  static const TtsVoice childrenBook = TtsVoice(
    name: '儿童绘本',
    voiceType: 'zh_female_xueayi_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.audiobook,
    abilities: ['指令遵循'],
    description: '适合儿童故事、绘本朗读',
  );

  // ==================== 视频配音 ====================
  static const TtsVoice dayi = TtsVoice(
    name: '大壹',
    voiceType: 'zh_male_dayi_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '解说男声',
  );

  static const TtsVoice heimaomis = TtsVoice(
    name: '黑猫侦探社咪',
    voiceType: 'zh_female_mizai_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '神秘女声',
  );

  static const TtsVoice jitangnv = TtsVoice(
    name: '鸡汤女',
    voiceType: 'zh_female_jitangnv_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '治愈女声',
  );

  static const TtsVoice meilinvyou = TtsVoice(
    name: '魅力女友',
    voiceType: 'zh_female_meilinvyou_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '甜美女声',
  );

  static const TtsVoice liuchangnv = TtsVoice(
    name: '流畅女声',
    voiceType: 'zh_female_santongyongns_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '标准女声',
  );

  static const TtsVoice ruyayichen = TtsVoice(
    name: '儒雅逸辰',
    voiceType: 'zh_male_ruyayichen_saturn_bigtts',
    language: '中文',
    category: TtsVoiceCategories.video,
    abilities: ['指令遵循'],
    description: '儒雅男声',
  );

  // ==================== 角色扮演 ====================
  static const TtsVoice keainvsheng = TtsVoice(
    name: '可爱女生',
    voiceType: 'saturn_zh_female_keainvsheng_tob',
    language: '中文',
    category: TtsVoiceCategories.roleplay,
    abilities: ['指令遵循', 'COT/QA功能'],
    description: '可爱萝莉音',
  );

  static const TtsVoice tiaopigongzhu = TtsVoice(
    name: '调皮公主',
    voiceType: 'saturn_zh_female_tiaopigongzhu_tob',
    language: '中文',
    category: TtsVoiceCategories.roleplay,
    abilities: ['指令遵循', 'COT/QA功能'],
    description: '活泼公主音',
  );

  static const TtsVoice shuanglangshaonian = TtsVoice(
    name: '爽朗少年',
    voiceType: 'saturn_zh_male_shuanglangshaonian_tob',
    language: '中文',
    category: TtsVoiceCategories.roleplay,
    abilities: ['指令遵循', 'COT/QA功能'],
    description: '爽朗少年音',
  );

  static const TtsVoice tiancaitongzhuo = TtsVoice(
    name: '天才同桌',
    voiceType: 'saturn_zh_male_tiancaitongzhuo_tob',
    language: '中文',
    category: TtsVoiceCategories.roleplay,
    abilities: ['指令遵循', 'COT/QA功能'],
    description: '聪明学霸音',
  );

  static const TtsVoice cancan = TtsVoice(
    name: '知性灿灿',
    voiceType: 'saturn_zh_female_cancan_tob',
    language: '中文',
    category: TtsVoiceCategories.roleplay,
    abilities: ['指令遵循', 'COT/QA功能'],
    description: '知性姐姐音',
  );

  // ==================== 自定义音色存储 ====================
  static final List<TtsVoice> _customVoices = [];
  static bool _initialized = false;
  
  /// 初始化自定义音色列表
  static Future<void> init() async {
    if (_initialized) return;
    await _loadCustomVoices();
    _initialized = true;
  }
  
  /// 加载自定义音色
  static Future<void> _loadCustomVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customVoicesJson = prefs.getString('tts_custom_voices');
      if (customVoicesJson != null) {
        final List<dynamic> decoded = jsonDecode(customVoicesJson);
        _customVoices.clear();
        for (final item in decoded) {
          _customVoices.add(TtsVoice(
            name: item['name'] ?? '自定义音色',
            voiceType: item['voiceType'] ?? '',
            language: item['language'] ?? '中文',
            category: item['category'] ?? '自定义',
            abilities: List<String>.from(item['abilities'] ?? []),
            description: item['description'],
          ));
        }
      }
    } catch (e) {
      debugPrint('加载自定义音色失败: $e');
    }
  }
  
  /// 保存自定义音色
  static Future<void> _saveCustomVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _customVoices.map((v) => {
        'name': v.name,
        'voiceType': v.voiceType,
        'language': v.language,
        'category': v.category,
        'abilities': v.abilities,
        'description': v.description,
      }).toList();
      await prefs.setString('tts_custom_voices', jsonEncode(encoded));
    } catch (e) {
      debugPrint('保存自定义音色失败: $e');
    }
  }
  
  /// 添加自定义音色
  static Future<void> addCustomVoice(TtsVoice voice) async {
    // 检查是否已存在
    if (_customVoices.any((v) => v.voiceType == voice.voiceType)) {
      throw Exception('该音色已存在');
    }
    _customVoices.add(voice);
    await _saveCustomVoices();
  }
  
  /// 删除自定义音色
  static Future<void> removeCustomVoice(String voiceType) async {
    _customVoices.removeWhere((v) => v.voiceType == voiceType);
    await _saveCustomVoices();
  }
  
  /// 获取所有自定义音色
  static List<TtsVoice> get customVoices => List.unmodifiable(_customVoices);
  
  /// 判断是否为自定义音色
  static bool isCustomVoice(String voiceType) {
    return _customVoices.any((v) => v.voiceType == voiceType);
  }

  // ==================== 所有音色列表 ====================
  static List<TtsVoice> get allVoices => [
    // 内置音色
    // 通用场景
    vivi2,
    xiaohe2,
    yunzhou2,
    xiaotian2,
    // 有声阅读
    childrenBook,
    // 视频配音
    dayi,
    heimaomis,
    jitangnv,
    meilinvyou,
    liuchangnv,
    ruyayichen,
    // 角色扮演
    keainvsheng,
    tiaopigongzhu,
    shuanglangshaonian,
    tiancaitongzhuo,
    cancan,
    // 自定义音色
    ..._customVoices,
  ];

  /// 默认音色 - Vivi 2.0
  static const String defaultVoiceType = 'zh_female_vv_uranus_bigtts';

  /// 根据 voice_type 获取音色信息
  static TtsVoice? getVoiceByType(String voiceType) {
    for (final voice in allVoices) {
      if (voice.voiceType == voiceType) {
        return voice;
      }
    }
    return null;
  }

  /// 按分类获取音色列表
  static List<TtsVoice> getVoicesByCategory(String category) {
    return allVoices.where((v) => v.category == category).toList();
  }

  /// 获取所有分类
  static List<String> get categories {
    return allVoices.map((v) => v.category).toSet().toList();
  }
}
