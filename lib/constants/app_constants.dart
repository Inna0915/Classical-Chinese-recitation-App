/// 应用常量配置

/// TTS API 配置（字节跳动/火山引擎）
class TtsConstants {
  /// ⚠️ 请替换为您的实际 API Key
  /// 建议从环境变量或安全存储中获取
  static const String apiKey = 'YOUR_VOLCENGINE_API_KEY_HERE';
  
  /// 火山引擎语音合成 API 端点
  /// 文档：https://www.volcengine.com/docs/6561/79817
  static const String apiUrl = 'https://openspeech.bytedance.com/api/v1/tts';
  
  /// 默认语音类型（中文情感女声）
  static const String defaultVoiceType = 'zh_female_qingxin';
  
  /// 音频格式：mp3
  static const String audioFormat = 'mp3';
  
  /// 音频采样率
  static const int sampleRate = 24000;
  
  /// 连接超时时间（秒）
  static const int connectTimeout = 30;
  
  /// 接收超时时间（秒）
  static const int receiveTimeout = 60;
}

/// 数据库配置
class DatabaseConstants {
  /// 数据库名称
  static const String dbName = 'guyun_reader.db';
  
  /// 数据库版本
  static const int dbVersion = 1;
  
  /// 诗词表名
  static const String poemsTable = 'poems';
  
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
