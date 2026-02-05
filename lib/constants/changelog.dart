/// 应用更新记录
class Changelog {
  static const String currentVersion = 'v2.1.0';
  static const String currentDate = '2026-02-05';
  
  static const List<VersionInfo> versions = [
    VersionInfo(
      version: 'v2.1.0',
      date: '2026-02-05',
      changes: [
        '📝 品牌升级：App名称更新为"桐声古韵"',
        '🎨 新Logo：更换全新应用图标',
        '💾 语音缓存：支持按音色缓存下载的音频，下次播放无需重新合成',
        '📌 小集置顶：支持小集置顶，置顶后显示在列表顶部',
        '🖼️ 小集卡片改进：横向列表式布局，显示前3个诗词标题',
        '🚀 性能优化：修复添加作品和收藏按钮卡顿问题',
        '🔧 细节优化：缩小书架卡片按钮间距',
        '🎨 24节气色彩：新增传统8275色主题选择页面',
      ],
    ),
    VersionInfo(
      version: 'v2.0.0',
      date: '2026-02-04',
      changes: [
        '🏗️ 架构重构：从层级分组升级为标签+歌单模式',
        '✨ 新增标签系统：支持多维度分类（古诗/宋词/童话等）',
        '✨ 新增小集功能：歌单式管理，支持拖拽排序',
        '✨ 数据驱动初始化：从JSON加载内置诗词数据',
        '🔧 新增 BookshelfPage：Cherry Studio风格书架页',
        '🔧 新增 CollectionsPage：小集/歌单管理页面',
        '📊 新数据库架构：5张表（poems/tags/poem_tags/collections/collection_poems）',
        '🎯 播放上下文：支持标签/小集/收藏等多种播放模式',
      ],
    ),
    VersionInfo(
      version: 'v1.7.1',
      date: '2026-02-04',
      changes: [
        '✨ 新增 4 种主题色（靛蓝/橘橙/翠绿/紫罗兰），共 10 种中国传统色',
        '🔧 收藏按钮颜色统一跟随全局主题',
        '🔧 对话框按钮颜色统一跟随全局主题',
        '🔧 添加作品界面移除朝代字段（改为可选）',
        '🔧 搜索列表滑动时自动收起键盘',
        '🐛 修复搜索栏遮罩问题',
        '🐛 修复编译错误（isDarkMode 冲突、朝代选择器残留代码）',
      ],
    ),
    VersionInfo(
      version: 'v1.7.0',
      date: '2026-02-04',
      changes: [
        '✨ 新增全局主题系统，支持 6 种中国传统色（朱砂/竹青/黛蓝/栀子/暮山紫/玄青）',
        '✨ 新增深色模式支持（跟随系统/浅色/深色三档切换）',
        '✨ 书架页新增固定搜索栏，支持实时搜索（标题/作者/内容）',
        '✨ 收藏页新增搜索功能，与书架页风格统一',
        '✨ 新增通用弹窗组件 AppDialog，统一全应用弹窗风格',
        '🔧 重构书架页和收藏页布局，视觉风格统一',
        '🔧 诗词列表项组件化，复用性提升',
        '🐛 修复添加作品界面朝代选择器报错',
        '🐛 修复播放列表跳转错误问题',
        '🐛 修复弹窗确定按钮无法点击问题',
      ],
    ),
    VersionInfo(
      version: 'v1.6.0',
      date: '2026-02-04',
      changes: [
        '✨ 重构设置页面为 Cherry Studio 风格（分组卡片式布局）',
        '✨ 新增"使用系统字体"切换功能（MiSans/思源宋体）',
        '✨ 重构 AI 模型配置为服务商列表模式',
        '✨ 支持多服务商独立配置（Kimi/DeepSeek/火山/阿里/OpenAI）',
        '✨ 新增服务商 Logo 显示（支持自定义品牌色回退）',
        '✨ TTS 配置页面重构，支持火山引擎详细配置',
        '🔧 优化设置页导航结构（主页→子页面模式）',
        '🔧 字体切换实时生效，无需重启应用',
        '🐛 修复 Android 13 存储权限兼容性问题',
      ],
    ),
    VersionInfo(
      version: 'v1.5.0',
      date: '2026-02-04',
      changes: [
        '✨ 新增自动更新功能，支持从 GitHub Releases 检查更新',
        '✨ 设置页面新增"检查更新"入口',
        '✨ 启动后自动静默检查更新',
        '✨ 国内镜像加速下载支持',
        '🔧 书架页面分组按钮样式优化，高度降低',
        '🔧 书架页面收藏按钮移至右侧',
        '🔧 修复分组内播放逻辑，正确触发 MiniPlayer',
        '🔧 修复播放列表暂停后无法播放新文件的问题',
        '🐛 修复分组页面重复"全部"按钮问题',
        '🐛 修复分组内容实时刷新问题',
      ],
    ),
    VersionInfo(
      version: 'v1.4.0',
      date: '2026-02-04',
      changes: [
        '✨ 新增全局迷你播放控制条（MiniPlayer）',
        '✨ MiniPlayer支持旋转意境图标动画',
        '✨ MiniPlayer支持播放进度环显示',
        '✨ 播放列表BottomSheet（当前播放管理）',
        '✨ 全局播放控制，切换Tab保持播放状态',
        '🎨 参考QQ音乐设计风格，古风元素适配',
      ],
    ),
    VersionInfo(
      version: 'v1.3.0',
      date: '2026-02-04',
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
      date: '2026-02-03',
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
      date: '2026-02-02',
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
      date: '2026',
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
