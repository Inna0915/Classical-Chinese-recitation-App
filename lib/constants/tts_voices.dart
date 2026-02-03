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
      voiceType: 'zh_female_qingxinnvsheng_mars_bigtts',
      displayName: '清新女声',
      gender: 'female',
      description: '清新自然的女声，适合古诗朗读',
    ),
    TtsVoice1(
      voiceType: 'ICL_zh_female_wenrounvshen_239eff5e8ffa_tob',
      displayName: '温柔女声',
      gender: 'female',
      description: '温柔婉约的女声',
    ),
    TtsVoice1(
      voiceType: 'zh_male_lengkugege_emo_v2_mars_bigtts',
      displayName: '冷酷哥哥',
      gender: 'male',
      description: '清朗阳光的男声，适合古诗朗读',
    ),
    TtsVoice1(
      voiceType: 'zh_female_shuangkuaisisi_emo_v2_mars_bigtts',
      displayName: '爽快思思',
      gender: 'male',
      description: '沉稳有力的男声',
    ),
    // 扩展音色
    TtsVoice1(
      voiceType: 'zh_female_shuangkuaisisi_moon_bigtts',
      displayName: '爽快思思',
      gender: 'female',
      description: '活泼爽快',
    ),
    TtsVoice1(
      voiceType: 'zh_female_qingxin',
      displayName: '清新',
      gender: 'female',
      description: '温柔标准',
    ),
    TtsVoice1(
      voiceType: 'zh_female_tianmei_moon_bigtts',
      displayName: '甜美',
      gender: 'female',
      description: '甜美可爱',
    ),
    TtsVoice1(
      voiceType: 'zh_male_silang_moon_bigtts',
      displayName: '四郎',
      gender: 'male',
      description: '成熟磁性',
    ),
    TtsVoice1(
      voiceType: 'zh_male_jieshuo_moon_bigtts',
      displayName: '解说',
      gender: 'male',
      description: '新闻播报腔',
    ),
    TtsVoice1(
      voiceType: 'zh_female_wanwan',
      displayName: '弯弯',
      gender: 'female',
      description: '台湾腔',
    ),
    TtsVoice1(
      voiceType: 'zh_female_yueyu',
      displayName: '粤语',
      gender: 'female',
      description: '粤语发音',
    ),
    TtsVoice1(
      voiceType: 'zh_male_ningxiang',
      displayName: '宁响',
      gender: 'male',
      description: '四川方言',
    ),
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
      description: '自然温暖的女声，表现力更强',
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
    TtsVoice2(
      voiceType: 'zh_female_cancan_mars_bigtts',
      displayName: '灿灿',
      gender: 'female',
      description: '活泼亲切，带情感',
    ),
    TtsVoice2(
      voiceType: 'zh_female_qingxin_mars_bigtts',
      displayName: '清新',
      gender: 'female',
      description: '温柔清晰',
    ),
    TtsVoice2(
      voiceType: 'zh_female_tianmei_mars_bigtts',
      displayName: '甜美',
      gender: 'female',
      description: '甜美自然',
    ),
    TtsVoice2(
      voiceType: 'zh_female_shaonian_mars_bigtts',
      displayName: '少年',
      gender: 'female',
      description: '中性少年音',
    ),
    TtsVoice2(
      voiceType: 'zh_male_chenqu_mars_bigtts',
      displayName: '陈趣',
      gender: 'male',
      description: '沉稳纪录片风格',
    ),
    TtsVoice2(
      voiceType: 'zh_male_silang_mars_bigtts',
      displayName: '四郎',
      gender: 'male',
      description: '成熟大叔',
    ),
    TtsVoice2(
      voiceType: 'zh_male_jieshuo_mars_bigtts',
      displayName: '解说',
      gender: 'male',
      description: '标准播音',
    ),
    TtsVoice2(
      voiceType: 'zh_male_wenhao_mars_bigtts',
      displayName: '文浩',
      gender: 'male',
      description: '年轻男声',
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
  static const String defaultVoice = 'BV001_streaming';
  static const String _customVoicesKey = 'custom_tts_voices';
  
  static List<CustomVoice> _customVoices = [];
  static bool _initialized = false;

  /// 初始化，加载自定义音色
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

  /// 获取所有可用音色（包括自定义）
  static List<TtsVoice> getAllVoices() {
    final voices = <TtsVoice>[
      ...TtsVoice1.voices,
      ...TtsVoice2.voices,
      ..._customVoices,
    ];
    return voices;
  }

  /// 获取所有预设音色
  static List<TtsVoice> getPresetVoices() {
    return [...TtsVoice1.voices, ...TtsVoice2.voices];
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

  /// 重置为默认音色列表（清空自定义）
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
