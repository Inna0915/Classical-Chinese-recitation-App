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

/// 字级别时间戳
class TimestampItem {
  final String char;
  final int startTime; // 毫秒
  final int endTime;   // 毫秒

  TimestampItem({
    required this.char,
    required this.startTime,
    required this.endTime,
  });

  factory TimestampItem.fromJson(Map<String, dynamic> json) {
    // 支持多种字段命名
    final char = json['char'] ?? json['word'] ?? json['text'] ?? '';
    var startMs = json['start_time'] ?? json['startTime'] ?? json['begin_time'] ?? 0;
    var endMs = json['end_time'] ?? json['endTime'] ?? json['end_time'] ?? 0;
    
    // 处理可能的String类型
    if (startMs is String) startMs = double.tryParse(startMs) ?? 0;
    if (endMs is String) endMs = double.tryParse(endMs) ?? 0;
    
    // 处理秒级转毫秒（如果数值小于1000，认为是秒）
    var startTime = startMs is int 
        ? startMs 
        : (startMs is double ? (startMs * 1000).toInt() : 0);
    var endTime = endMs is int 
        ? endMs 
        : (endMs is double ? (endMs * 1000).toInt() : 0);
    
    // 如果值小于1000，认为是秒，需要转换
    if (startTime < 1000 && startTime > 0) startTime *= 1000;
    if (endTime < 1000 && endTime > 0) endTime *= 1000;
    
    return TimestampItem(
      char: char,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'char': char,
    'start_time': startTime,
    'end_time': endTime,
  };
}

/// TTS 结果
class TtsResult {
  /// 是否成功
  final bool isSuccess;
  
  /// 音频文件路径（移动端）
  final String? audioPath;
  
  /// 音频字节数据（Web 端）
  final List<int>? audioBytes;
  
  /// 时间戳数据路径
  final String? timestampPath;
  
  /// 时间戳数据（内存中）
  final List<TimestampItem>? timestamps;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 是否来自缓存
  final bool isFromCache;

  TtsResult({
    required this.isSuccess,
    this.audioPath,
    this.audioBytes,
    this.timestampPath,
    this.timestamps,
    this.errorMessage,
    this.isFromCache = false,
  });

  /// 成功结果（本地文件）
  factory TtsResult.success({
    required String audioPath,
    String? timestampPath,
    List<TimestampItem>? timestamps,
    bool isFromCache = false,
  }) {
    return TtsResult(
      isSuccess: true,
      audioPath: audioPath,
      timestampPath: timestampPath,
      timestamps: timestamps,
      isFromCache: isFromCache,
    );
  }

  /// 成功结果（字节数据）
  factory TtsResult.successBytes({
    required List<int> audioBytes,
    List<TimestampItem>? timestamps,
    bool isFromCache = false,
  }) {
    return TtsResult(
      isSuccess: true,
      audioBytes: audioBytes,
      timestamps: timestamps,
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
      'TtsResult(isSuccess: $isSuccess, isFromCache: $isFromCache, path: $audioPath, timestampPath: $timestampPath)';
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
  
  String get timestampFileName => 'poem_${poemId}_${voiceType}_r${speechRate}_l${loudnessRate}.json';

  @override
  String toString() => 'TtsCacheKey(poemId: $poemId, voice: $voiceType, rate: $speechRate, loud: $loudnessRate)';
}
