import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 音色定义
/// Doubao 1.0 和 Doubao 2.0 使用不同的音色标识

/// Doubao 1.0 音色 (seed-tts-1.0)
class TtsVoice1 implements TtsVoice {
  @override
  final String voiceType;
  @override
  final String displayName;
  @override
  final String gender;
  @override
  final String description;
  @override
  String get version => '1.0';

  const TtsVoice1({
    required this.voiceType,
    required this.displayName,
    required this.gender,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'voiceType': voiceType,
    'displayName': displayName,
    'gender': gender,
    'description': description,
    'version': '1.0',
  };

  factory TtsVoice1.fromJson(Map<String, dynamic> json) => TtsVoice1(
    voiceType: json['voiceType'] as String,
    displayName: json['displayName'] as String,
    gender: json['gender'] as String,
    description: json['description'] as String,
  );

  /// Doubao 1.0 音色列表
  static const List<TtsVoice1> voices = [
    // 默认音色
    TtsVoice1(
      voiceType: 'ICL_zh_male_neiliancaijun_e991be511569_tob',
      displayName: '内敛才俊',
      gender: 'male',
      description: '内敛才俊男声(指令遵循)',
    ),
    TtsVoice1(
      voiceType: 'ICL_zh_male_yangyang_v1_tob',
      displayName: '温暖少年',
      gender: 'male',
      description: 'StoryAi温暖少年',
    ),
    TtsVoice1(
      voiceType: 'ICL_zh_male_flc_v1_tob',
      displayName: '儒雅公子',
      gender: 'male',
      description: 'StoryAi儒雅公子',
    ),
    TtsVoice1(
      voiceType: 'zh_male_changtianyi_mars_bigtts',
      displayName: '悬疑解说',
      gender: 'male',
      description: '悬疑解说风格适用于剪映C端、抖音、豆包',
    ),
    TtsVoice1(
      voiceType: 'zh_male_ruyaqingnian_mars_bigtts',
      displayName: '儒雅青年',
      gender: 'male',
      description: '儒雅青年男声,适用于番茄小说、豆包、剪映(指令遵循)',
    ),
    TtsVoice1(
      voiceType: 'zh_male_baqiqingshu_mars_bigtts',
      displayName: '霸气青叔',
      gender: 'male',
      description: '霸气青叔声线,适用于番茄小说、豆包、剪映、剪映-Dreamina',
    ),
    TtsVoice1(
      voiceType: 'zh_male_qingcang_mars_bigtts',
      displayName: '擎苍',
      gender: 'male',
      description: '擎苍男声,适用于番茄小说、剪映、豆包、抖音(指令遵循)',
    ),
    TtsVoice1(
      voiceType: 'zh_male_yangguangqingnian_mars_bigtts',
      displayName: '活力小哥',
      gender: 'male',
      description: '活力小哥阳光青年(指令遵循)',
    ),
    TtsVoice1(
      voiceType: 'zh_female_gufengshaoyu_mars_bigtts',
      displayName: '古风少御',
      gender: 'female',
      description: '古风少御女声(指令遵循)',
    ),
    TtsVoice1(
      voiceType: 'zh_female_wenroushunv_mars_bigtts',
      displayName: '温柔淑女',
      gender: 'female',
      description: '温柔淑女声线,适用于番茄小说、豆包、剪映、剪映-Dreamina',
    ),
    TtsVoice1(
      voiceType: 'zh_male_fanjuanqingnian_mars_bigtts',
      displayName: '反卷青年',
      gender: 'male',
      description: '反卷青年男声(指令遵循)',
    )
  ];
}

/// Doubao 2.0 音色 (seed-tts-2.0)
class TtsVoice2 implements TtsVoice {
  @override
  final String voiceType;
  @override
  final String displayName;
  @override
  final String gender;
  @override
  final String description;
  @override
  String get version => '2.0';

  const TtsVoice2({
    required this.voiceType,
    required this.displayName,
    required this.gender,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'voiceType': voiceType,
    'displayName': displayName,
    'gender': gender,
    'description': description,
    'version': '2.0',
  };

  factory TtsVoice2.fromJson(Map<String, dynamic> json) => TtsVoice2(
    voiceType: json['voiceType'] as String,
    displayName: json['displayName'] as String,
    gender: json['gender'] as String,
    description: json['description'] as String,
  );

  /// Doubao 2.0 音色列表
  static const List<TtsVoice2> voices = [
    // 默认音色
    TtsVoice2(
      voiceType: 'zh_female_vv_uranus_bigtts',
      displayName: 'Vivi 2.0',
      gender: 'female',
      description: '自然温暖的女声,表现力更强',
    ),
    TtsVoice2(
      voiceType: 'zh_female_xiaohe_uranus_bigtts',
      displayName: '小何 2.0',
      gender: 'female',
      description: '知性优雅的女声',
    ),
    TtsVoice2(
      voiceType: 'zh_male_m191_uranus_bigtts',
      displayName: '云舟 2.0',
      gender: 'male',
      description: '磁性浑厚的男声',
    ),
    TtsVoice2(
      voiceType: 'zh_male_taocheng_uranus_bigtts',
      displayName: '小天 2.0',
      gender: 'male',
      description: '阳光活力的男声',
    ),
    // 扩展音色
    // 有声阅读 - 儿童绘本
    TtsVoice2(
      voiceType: 'zh_female_xueayi_saturn_bigtts',
      displayName: '儿童绘本',
      gender: 'female',
      description: '有声阅读,适用于儿童绘本(指令遵循)',
    ),

    // 视频配音 - 大壹
    TtsVoice2(
      voiceType: 'zh_male_dayi_saturn_bigtts',
      displayName: '大壹',
      gender: 'male',
      description: '剪映视频配音,沉稳男声(指令遵循)',
    ),

    // 视频配音 - 黑猫侦探社咪
    TtsVoice2(
      voiceType: 'zh_female_mizai_saturn_bigtts',
      displayName: '黑猫侦探社咪',
      gender: 'female',
      description: '剪映视频配音,侦探社风格女声(指令遵循)',
    ),

    // 视频配音 - 鸡汤女
    TtsVoice2(
      voiceType: 'zh_female_jitangnv_saturn_bigtts',
      displayName: '鸡汤女',
      gender: 'female',
      description: '剪映视频配音,情感女声(指令遵循)',
    ),

    // 视频配音 - 魅力女友
    TtsVoice2(
      voiceType: 'zh_female_meilinvyou_saturn_bigtts',
      displayName: '魅力女友',
      gender: 'female',
      description: '剪映视频配音,魅力女友声线(指令遵循)',
    ),

    // 视频配音 - 流畅女声
    TtsVoice2(
      voiceType: 'zh_female_santongyongns_saturn_bigtts',
      displayName: '流畅女声',
      gender: 'female',
      description: '剪映视频配音,流畅通用女声(指令遵循)',
    ),

    // 角色扮演 - 儒雅逸辰
    TtsVoice2(
      voiceType: 'zh_male_ruyayichen_saturn_bigtts',
      displayName: '儒雅逸辰',
      gender: 'male',
      description: '角色扮演,儒雅男声(指令遵循)',
    ),

    // 角色扮演 - 可爱女生
    TtsVoice2(
      voiceType: 'saturn_zh_female_keainvsheng_tob',
      displayName: '可爱女生',
      gender: 'female',
      description: '角色扮演,可爱女生(指令遵循、COT/QA功能)',
    ),

    // 角色扮演 - 调皮公主
    TtsVoice2(
      voiceType: 'saturn_zh_female_tiaopigongzhu_tob',
      displayName: '调皮公主',
      gender: 'female',
      description: '角色扮演,调皮公主(指令遵循、COT/QA功能)',
    ),

    // 角色扮演 - 爽朗少年
    TtsVoice2(
      voiceType: 'saturn_zh_male_shuanglangshaonian_tob',
      displayName: '爽朗少年',
      gender: 'male',
      description: '角色扮演,爽朗少年(指令遵循、COT/QA功能)',
    ),

    // 角色扮演 - 天才同桌
    TtsVoice2(
      voiceType: 'saturn_zh_male_tiancaitongzhuo_tob',
      displayName: '天才同桌',
      gender: 'male',
      description: '角色扮演,天才同桌(指令遵循、COT/QA功能)',
    ),

    // 角色扮演 - 知性灿灿
    TtsVoice2(
      voiceType: 'saturn_zh_female_cancan_tob',
      displayName: '知性灿灿',
      gender: 'female',
      description: '角色扮演,知性女声(指令遵循、COT/QA功能)',
    ),
  ];
}

/// 统一音色接口
abstract class TtsVoice {
  String get voiceType;
  String get displayName;
  String get gender;
  String get description;
  String get version;
  
  Map<String, dynamic> toJson();
}

/// 自定义音色
class CustomVoice implements TtsVoice {
  @override
  final String voiceType;
  @override
  final String displayName;
  @override
  final String gender;
  @override
  final String description;
  @override
  final String version;

  const CustomVoice({
    required this.voiceType,
    required this.displayName,
    required this.gender,
    required this.description,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
    'voiceType': voiceType,
    'displayName': displayName,
    'gender': gender,
    'description': description,
    'version': version,
    'isCustom': true,
  };

  factory CustomVoice.fromJson(Map<String, dynamic> json) => CustomVoice(
    voiceType: json['voiceType'] as String,
    displayName: json['displayName'] as String,
    gender: json['gender'] as String,
    description: json['description'] as String,
    version: json['version'] as String,
  );
}

/// 音色工具类
class TtsVoices {
  /// 默认音色 - Vivi 2.0
  static const String defaultVoice = 'zh_female_vv_uranus_bigtts';
  static const String _customVoicesKey = 'custom_tts_voices';
  
  static List<CustomVoice> _customVoices = [];
  static bool _initialized = false;

  /// 初始化,加载自定义音色
  static Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final customVoicesJson = prefs.getStringList(_customVoicesKey);
    
    if (customVoicesJson != null) {
      _customVoices = customVoicesJson.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CustomVoice.fromJson(map);
      }).toList();
    }
    
    _initialized = true;
  }

  /// 获取所有可用音色(包括自定义) - 2.0音色在前
  static List<TtsVoice> getAllVoices() {
    final voices = <TtsVoice>[
      ...TtsVoice2.voices,
      ...TtsVoice1.voices,
      ..._customVoices,
    ];
    return voices;
  }

  /// 获取所有预设音色 - 2.0音色在前
  static List<TtsVoice> getPresetVoices() {
    return [...TtsVoice2.voices, ...TtsVoice1.voices];
  }

  /// 获取自定义音色列表
  static List<CustomVoice> getCustomVoices() {
    return List.unmodifiable(_customVoices);
  }

  /// 添加自定义音色
  static Future<void> addCustomVoice(CustomVoice voice) async {
    // 检查是否已存在
    final existingIndex = _customVoices.indexWhere((v) => v.voiceType == voice.voiceType);
    if (existingIndex >= 0) {
      _customVoices[existingIndex] = voice;
    } else {
      _customVoices.add(voice);
    }
    await _saveCustomVoices();
  }

  /// 删除自定义音色
  static Future<void> removeCustomVoice(String voiceType) async {
    _customVoices.removeWhere((v) => v.voiceType == voiceType);
    await _saveCustomVoices();
  }

  /// 保存自定义音色到本地
  static Future<void> _saveCustomVoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customVoices.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_customVoicesKey, jsonList);
  }

  /// 重置为默认音色列表(清空自定义)
  static Future<void> resetToDefault() async {
    _customVoices.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customVoicesKey);
  }

  static String getDisplayName(String voiceType) {
    // 尝试 1.0 音色
    try {
      return TtsVoice1.voices.firstWhere((v) => v.voiceType == voiceType).displayName;
    } catch (_) {}
    
    // 尝试 2.0 音色
    try {
      return TtsVoice2.voices.firstWhere((v) => v.voiceType == voiceType).displayName;
    } catch (_) {}
    
    // 尝试自定义音色
    try {
      return _customVoices.firstWhere((v) => v.voiceType == voiceType).displayName;
    } catch (_) {}
    
    return voiceType;
  }

  static String getDescription(String voiceType) {
    try {
      return TtsVoice1.voices.firstWhere((v) => v.voiceType == voiceType).description;
    } catch (_) {}
    
    try {
      return TtsVoice2.voices.firstWhere((v) => v.voiceType == voiceType).description;
    } catch (_) {}
    
    try {
      return _customVoices.firstWhere((v) => v.voiceType == voiceType).description;
    } catch (_) {}
    
    return '';
  }

  /// 判断音色是否属于 2.0
  static bool isVoice2(String voiceType) {
    // 检查是否是 2.0 预设音色
    if (TtsVoice2.voices.any((v) => v.voiceType == voiceType)) {
      return true;
    }
    
    // 检查自定义音色
    try {
      final custom = _customVoices.firstWhere((v) => v.voiceType == voiceType);
      return custom.version == '2.0';
    } catch (_) {}
    
    // 通过音色ID特征判断
    return voiceType.contains('_V2_') ||
        voiceType.contains('_mars_bigtts') ||
        voiceType.contains('_saturn') ||
        voiceType.contains('_tob');
  }

  /// 判断音色是否需要 2.0 API
  static bool needs2Api(String voiceType) {
    return isVoice2(voiceType);
  }

  /// 获取音色版本
  static String getVoiceVersion(String voiceType) {
    if (isVoice2(voiceType)) return '2.0';
    
    // 检查是否是 1.0 音色
    if (TtsVoice1.voices.any((v) => v.voiceType == voiceType)) return '1.0';
    
    // 检查自定义音色
    try {
      return _customVoices.firstWhere((v) => v.voiceType == voiceType).version;
    } catch (_) {}
    
    return '1.0';
  }
}
