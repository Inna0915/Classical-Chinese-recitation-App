/// 音色定义
/// Doubao 1.0 和 Doubao 2.0 使用不同的音色标识

/// Doubao 1.0 音色 (seed-tts-1.0)
class TtsVoice1 {
  final String voiceType;
  final String displayName;
  final String gender;
  final String description;

  const TtsVoice1({
    required this.voiceType,
    required this.displayName,
    required this.gender,
    required this.description,
  });

  /// Doubao 1.0 音色列表
  static const List<TtsVoice1> voices = [
    TtsVoice1(
      voiceType: 'BV001_streaming',
      displayName: '清新女声',
      gender: 'female',
      description: '清新自然的女声，适合古诗朗读',
    ),
    TtsVoice1(
      voiceType: 'BV002_streaming',
      displayName: '温柔女声',
      gender: 'female',
      description: '温柔婉约的女声',
    ),
    TtsVoice1(
      voiceType: 'BV005_streaming',
      displayName: '清朗男声',
      gender: 'male',
      description: '清朗阳光的男声，适合古诗朗读',
    ),
    TtsVoice1(
      voiceType: 'BV006_streaming',
      displayName: '沉稳男声',
      gender: 'male',
      description: '沉稳有力的男声',
    ),
  ];
}

/// Doubao 2.0 音色 (seed-tts-2.0)
class TtsVoice2 {
  final String voiceType;
  final String displayName;
  final String gender;
  final String description;

  const TtsVoice2({
    required this.voiceType,
    required this.displayName,
    required this.gender,
    required this.description,
  });

  /// Doubao 2.0 音色列表
  static const List<TtsVoice2> voices = [
    TtsVoice2(
      voiceType: 'BV001_V2_streaming',
      displayName: 'Vivi 2.0',
      gender: 'female',
      description: '自然温暖的女声，表现力更强',
    ),
    TtsVoice2(
      voiceType: 'BV002_V2_streaming',
      displayName: '小何 2.0',
      gender: 'female',
      description: '知性优雅的女声',
    ),
    TtsVoice2(
      voiceType: 'BV005_V2_streaming',
      displayName: '云舟 2.0',
      gender: 'male',
      description: '磁性浑厚的男声',
    ),
    TtsVoice2(
      voiceType: 'BV006_V2_streaming',
      displayName: '小天 2.0',
      gender: 'male',
      description: '阳光活力的男声',
    ),
  ];
}

/// 音色工具类
class TtsVoices {
  static const String defaultVoice = 'BV001_streaming';

  static String getDisplayName(String voiceType) {
    // 尝试 1.0 音色
    try {
      return TtsVoice1.voices.firstWhere((v) => v.voiceType == voiceType).displayName;
    } catch (_) {}
    
    // 尝试 2.0 音色
    try {
      return TtsVoice2.voices.firstWhere((v) => v.voiceType == voiceType).displayName;
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
    
    return '';
  }

  /// 获取所有可用音色
  static List<dynamic> getAllVoices() {
    return [...TtsVoice1.voices, ...TtsVoice2.voices];
  }

  /// 判断音色是否属于 2.0
  static bool isVoice2(String voiceType) {
    return voiceType.contains('_V2_') ||
        voiceType.contains('bigtts') ||
        voiceType.contains('saturn') ||
        voiceType.contains('tob');
  }

  /// 判断音色是否需要 2.0 API (目前 2.0 音色都需要 2.0 API)
  static bool needs2Api(String voiceType) {
    return isVoice2(voiceType);
  }
}
