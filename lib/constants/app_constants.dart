/// 应用常量配置

/// TTS API 配置（火山引擎/豆包语音合成）
class TtsConstants {
  // ==================== API 认证信息 ====================
  /// APP ID - 从火山引擎控制台获取
  static const String appId = '3792227411';
  
  /// Access Token - 从火山引擎控制台获取
  static const String accessToken = 'FFboPOKdi8mb56VAkczjrp_bdMCKPv_5';
  
  /// Secret Key - 用于某些认证场景
  static const String secretKey = 'NVRXsBvOEsNS6OWyC2MKtMVCDkLRn11d';
  
  // ==================== API 配置 ====================
  /// 火山引擎 TTS API v3 端点
  /// 文档：https://www.volcengine.com/docs/6561/196768
  static const String apiUrl = 'https://openspeech.bytedance.com/api/v3/tts/unidirectional';
  
  /// 资源信息 ID - 豆包语音合成模型 2.0（字符版）
  static const String resourceId = 'seed-tts-2.0';
  
  /// 模型版本 - 使用 1.1 版本音质更好、延时更优
  static const String model = 'seed-tts-1.1';
  
  // ==================== 音频配置 ====================
  /// 默认音色 - Vivi 2.0
  static const String defaultVoiceType = 'zh_female_vv_uranus_bigtts';
  
  /// 默认音频格式: mp3/ogg_opus/pcm
  static const String audioFormat = 'mp3';
  
  /// 默认音频采样率 [8000,16000,22050,24000,32000,44100,48000]
  static const int sampleRate = 24000;
  
  /// 默认音频比特率（仅 MP3 有效）
  static const int bitRate = 128000;
  
  // ==================== 语音参数配置 ====================
  /// 默认语速 [-50, 100]，100代表2.0倍速，-50代表0.5倍速
  static const int defaultSpeechRate = 0;
  
  /// 默认音量 [-50, 100]，100代表2.0倍音量，-50代表0.5倍音量
  static const int defaultLoudnessRate = 0;
  
  /// 默认情感强度 [1, 5]
  static const int defaultEmotionScale = 4;
  
  // ==================== 网络配置 ====================
  /// 连接超时时间（秒）
  static const int connectTimeout = 30;
  
  /// 接收超时时间（秒）- 流式合成需要较长时间
  static const int receiveTimeout = 120;
}

/// 数据库配置
class DatabaseConstants {
  /// 数据库名称
  static const String dbName = 'guyun_reader.db';
  
  /// 数据库版本
  static const int dbVersion = 3;
  
  /// 诗词表名
  static const String poemsTable = 'poems';
  
  /// 分组表名
  static const String groupsTable = 'poem_groups';
  
  /// 语音缓存表名 - 支持多音色缓存
  static const String voiceCacheTable = 'voice_cache';
  
  /// 音频缓存目录名
  static const String audioCacheDir = 'audio_cache';
}

/// UI 常量
class UIConstants {
  /// 主题色 - 墨黑
  static const int primaryColor = 0xFF2C2C2C;
  
  /// 背景色 - 米白
  static const int backgroundColor = 0xFFF7F5F0;
  
  /// 卡片背景色 - 宣纸白
  static const int cardColor = 0xFFFAF8F3;
  
  /// 文字主色 - 玄黑
  static const int textPrimaryColor = 0xFF1A1A1A;
  
  /// 文字次色 - 灰黑
  static const int textSecondaryColor = 0xFF666666;
  
  /// 强调色 - 朱砂红
  static const int accentColor = 0xFFC45C48;
  
  /// 分割线颜色
  static const int dividerColor = 0xFFE8E4DC;
  
  /// 默认内边距
  static const double defaultPadding = 24.0;
  
  /// 默认圆角
  static const double defaultRadius = 12.0;
}

/// 字体配置
class FontConstants {
  /// 中文衬线字体（宋体风格）
  static const String chineseSerif = 'NotoSerifSC';
  
  /// 标题字号
  static const double titleSize = 28.0;
  
  /// 正文字号
  static const double bodySize = 18.0;
  
  /// 小字字号
  static const double smallSize = 14.0;
}
