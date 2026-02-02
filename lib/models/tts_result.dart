import '../models/poem.dart';

/// TTS 音频参数
class AudioParams {
  /// 语速 [-50, 100]
  final int speechRate;
  
  /// 音量 [-50, 100]
  final int loudnessRate;

  const AudioParams({
    this.speechRate = 0,
    this.loudnessRate = 0,
  });

  /// 将 speechRate 转换为 API 使用的 speed_ratio
  double get speedRatio => (speechRate + 100) / 100;

  /// 将 loudnessRate 转换为 API 使用的 volume_ratio  
  double get volumeRatio => (loudnessRate + 100) / 100;

  @override
  String toString() => 'AudioParams(speechRate: $speechRate, loudnessRate: $loudnessRate)';
}

/// TTS 结果
class TtsResult {
  /// 是否成功
  final bool isSuccess;
  
  /// 音频文件路径（移动端）
  final String? audioPath;
  
  /// 音频字节数据（Web 端）
  final List<int>? audioBytes;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 是否来自缓存
  final bool isFromCache;

  TtsResult({
    required this.isSuccess,
    this.audioPath,
    this.audioBytes,
    this.errorMessage,
    this.isFromCache = false,
  });

  /// 成功结果（本地文件）
  factory TtsResult.success({
    required String audioPath,
    bool isFromCache = false,
  }) {
    return TtsResult(
      isSuccess: true,
      audioPath: audioPath,
      isFromCache: isFromCache,
    );
  }

  /// 成功结果（字节数据）
  factory TtsResult.successBytes({
    required List<int> audioBytes,
    bool isFromCache = false,
  }) {
    return TtsResult(
      isSuccess: true,
      audioBytes: audioBytes,
      isFromCache: isFromCache,
    );
  }

  /// 失败结果
  factory TtsResult.failure(String error) {
    return TtsResult(
      isSuccess: false,
      errorMessage: error,
    );
  }

  @override
  String toString() => 
      'TtsResult(isSuccess: $isSuccess, isFromCache: $isFromCache, path: $audioPath)';
}

/// TTS 缓存键
class TtsCacheKey {
  final int poemId;
  final String voiceType;
  final int speechRate;
  final int loudnessRate;

  TtsCacheKey({
    required this.poemId,
    required this.voiceType,
    this.speechRate = 0,
    this.loudnessRate = 0,
  });

  String get fileName => 'poem_${poemId}_${voiceType}_r${speechRate}_l${loudnessRate}.mp3';

  @override
  String toString() => 'TtsCacheKey(poemId: $poemId, voice: $voiceType, rate: $speechRate, loud: $loudnessRate)';
}
