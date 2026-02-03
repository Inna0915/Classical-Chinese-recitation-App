/// 应用更新记录
class Changelog {
  static const String currentVersion = 'v1.3.0';
  static const String currentDate = '2025-02-04';
  
  static const List<VersionInfo> versions = [
    VersionInfo(
      version: 'v1.3.0',
      date: '2025-02-04',
      changes: [
        '✨ 新增卡拉OK逐字高亮朗读功能',
        '✨ AI配置API KEY支持明文/密文切换显示',
        '✨ AI模型高级配置改为展开式，使用更便捷',
        '✨ 关于页面支持查看完整更新记录',
        '✨ 关于页面增加作者信息和GitHub仓库地址',
        '✨ TTS日志系统优化，所有日志统一收集',
        '🐛 修复数据库升级导致的诗词展示问题',
        '🐛 修复默认诗词数据缺少clean_content字段',
      ],
    ),
    VersionInfo(
      version: 'v1.2.0',
      date: '2025-02-03',
      changes: [
        '✨ 新增独立分组浏览界面，支持查看各分组内容',
        '✨ 新增分组顺序播放功能，支持连续播放分组内诗词',
        '✨ 音色选择器显示缓存状态标识',
        '✨ 书架页面改为列表布局，操作更便捷',
        '✨ 播放内容包含标题和作者信息',
        '🐛 修复数据库表创建问题',
        '🐛 修复诗词排序问题',
      ],
    ),
    VersionInfo(
      version: 'v1.1.0',
      date: '2025-02-02',
      changes: [
        '✨ 新增流式播放功能，边合成边播放',
        '✨ 支持 Doubao 1.0/2.0 双版本音色（各 12 种）',
        '✨ 新增自定义音色支持',
        '✨ 新增调试日志查看器',
        '✨ 诗词列表支持网格布局',
        '✨ 支持分组拖拽排序',
        '🐛 修复多个已知问题',
      ],
    ),
    VersionInfo(
      version: 'v1.0.0',
      date: '2024',
      changes: [
        '🎉 初始版本发布',
      ],
    ),
  ];
  
  /// 获取当前版本的更新内容
  static List<String> get currentChanges {
    return versions.firstWhere(
      (v) => v.version == currentVersion,
      orElse: () => versions.first,
    ).changes;
  }
}

class VersionInfo {
  final String version;
  final String date;
  final List<String> changes;
  
  const VersionInfo({
    required this.version,
    required this.date,
    required this.changes,
  });
}
