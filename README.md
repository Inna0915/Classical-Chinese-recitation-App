# 古韵诵读 (GuYunReader)

一款利用云端 AI 语音合成技术朗读古诗词的 Flutter 应用。

## 功能特性

- 📜 **诗词展示**：新中式极简风格，米白色背景配衬线字体
- 🔊 **AI 朗读**：接入字节跳动/火山引擎 TTS API，支持 Doubao 1.0/2.0 双版本
- 🎙️ **多音色选择**：支持 12 种 Doubao 1.0 音色 + 12 种 Doubao 2.0 音色，支持自定义音色
- 🌊 **流式播放**：边合成边播放，无需等待完整音频生成
- 💾 **智能缓存**：多音色音频缓存机制，同一首诗不同音色独立缓存
- ⏯️ **播放控制**：支持播放、暂停、停止、进度拖动
- 🔍 **诗词搜索**：支持按标题、作者、内容搜索
- 📁 **诗词分组**：支持自定义分组管理诗词，支持拖拽排序，独立分组浏览界面
- ⭐ **收藏功能**：收藏喜欢的诗词便于快速访问
- 🔧 **调试工具**：内置 API 请求/响应日志查看器，便于排查问题
- 🎵 **分组顺序播放**：支持按分组连续播放所有诗词
- 📋 **列表布局**：书架页面支持列表形式展示，操作更便捷
- 🎤 **卡拉OK高亮**：朗读时文字逐字高亮，营造沉浸式朗读体验
- 📜 **双视图模式**：纯净版（适合朗读）和释义版（带逐句解释）
- 🔄 **自动更新**：支持从 GitHub Releases 检查并下载更新，国内镜像加速
- 🎨 **系统字体切换**：支持在古风宋体和系统默认字体（MiSans）之间切换
- 🤖 **多 AI 服务商**：支持 Kimi、DeepSeek、火山引擎、阿里百炼等多服务商独立配置

## 项目结构

```
lib/
├── constants/
│   ├── app_constants.dart      # 应用常量配置（API、UI、数据库等）
│   ├── tts_voices.dart         # TTS 音色定义（1.0/2.0 + 自定义）
│   ├── ai_models.dart          # AI 模型配置
│   └── changelog.dart          # 更新日志
├── controllers/
│   ├── poem_controller.dart    # GetX 控制器（诗词管理）
│   └── player_controller.dart  # 播放器控制器（播放列表管理）
├── models/
│   ├── config/
│   │   └── llm_config.dart     # LLM 多服务商配置数据模型
│   ├── poem.dart               # 诗词数据模型
│   ├── poem_group.dart         # 分组数据模型
│   ├── voice_cache.dart        # 语音缓存模型
│   ├── tts_result.dart         # TTS 结果模型
│   └── github_release.dart     # GitHub Release 数据模型
├── pages/
│   ├── main_page.dart          # 主页面（底部导航）
│   ├── poem_list_page.dart     # 诗词列表页（列表布局）
│   ├── groups_page.dart        # 分组浏览页
│   ├── poem_detail_page.dart   # 诗词详情页
│   ├── poem_edit_page.dart     # 诗词编辑页
│   ├── settings_page.dart      # 设置页面（Cherry Studio 风格）
│   └── settings/
│       ├── llm_config_page.dart       # AI 服务商列表页
│       ├── llm_provider_detail_page.dart  # AI 服务商详情配置
│       └── tts_config_page.dart       # TTS 详细配置页
├── services/
│   ├── database_helper.dart    # SQLite 数据库帮助类
│   ├── tts_service.dart        # TTS 服务（核心业务逻辑）
│   ├── settings_service.dart   # 设置管理服务
│   └── update_service.dart     # 自动更新服务
├── widgets/
│   ├── settings/               # 设置相关组件
│   │   ├── settings_section.dart   # 分组卡片组件
│   │   ├── settings_tile.dart      # 设置项组件
│   │   └── provider_logo.dart      # 服务商 Logo 组件
│   └── mini_player_widget.dart # 迷你播放控制条
├── utils/
│   └── audio_utils.dart        # 音频工具类
└── main.dart                   # 应用入口
```

## 开发环境

| 技术项 | 版本 |
|--------|------|
| Flutter SDK | 3.24.0 |
| Dart SDK | >=3.0.0 <4.0.0 |
| Android SDK | API 21+ (Android 5.0+) |

## 技术栈与依赖版本

### 核心框架
| 依赖包 | 版本 | 用途 |
|--------|------|------|
| **get** | ^4.6.6 | 状态管理、路由管理、依赖注入 |
| **dio** | ^5.4.0 | HTTP 网络请求 |
| **sqflite** | ^2.3.0 | SQLite 数据库操作 |
| **audioplayers** | ^5.2.1 | 本地音频播放 |

### 平台适配
| 依赖包 | 版本 | 用途 |
|--------|------|------|
| **path_provider** | ^2.1.2 | 获取平台文件路径 |
| **path** | ^1.8.3 | 路径处理工具 |
| **shared_preferences** | ^2.2.2 | 本地轻量数据存储 |

### Web 支持
| 依赖包 | 版本 | 用途 |
|--------|------|------|
| **sqflite_common_ffi_web** | ^0.4.2+3 | Web 平台 SQLite 支持 |

### UI 组件
| 依赖包 | 版本 | 用途 |
|--------|------|------|
| **flutter_markdown** | ^0.6.18 | Markdown 渲染 |

## 快速开始

### 1. 环境要求

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK API 21+

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置 TTS API（可选）

应用已内置火山引擎 TTS 凭证，如需自定义，在设置页面修改：

设置 → TTS 配置 → 修改 APP ID 和 Access Key

### 4. 添加字体

将 Noto Serif SC（思源宋体）字体文件放入 `assets/fonts/` 目录：
- `NotoSerifSC-Regular.ttf`
- `NotoSerifSC-Bold.ttf`

字体下载：https://fonts.google.com/noto/specimen/Noto+Serif+SC

### 5. 配置 Android 权限

修改 `android/app/src/main/AndroidManifest.xml`，添加网络和存储权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 6. 运行应用

```bash
# 调试运行
flutter run

# 构建 Release APK（输出名称: app-yymmdd-hhmm.apk）
flutter build apk --release

# 构建 App Bundle
flutter build appbundle
```

## TTS 技术说明

### 支持的音色

#### Doubao 1.0 (seed-tts-1.0) - 12 种
| 音色标识 | 名称 | 性别 |
|----------|------|------|
| BV001_streaming | 清新女声 | 女 |
| BV002_streaming | 温柔女声 | 女 |
| BV003_streaming | 活泼女声 | 女 |
| BV004_streaming | 知性女声 | 女 |
| BV005_streaming | 清朗男声 | 男 |
| BV006_streaming | 沉稳男声 | 男 |
| zh_female_shuangkuaisisi_moon_bigtts | 爽快女声 | 女 |
| zh_female_wanwanxiaohe_moon_bigtts | 婉转女声 | 女 |
| zh_female_qingxinnainai_moon_bigtts | 清新奶奶 | 女 |
| zh_female_qingxinjiejie_moon_bigtts | 清新姐姐 | 女 |
| zh_male_jingqiangjiedu_moon_bigtts | 京腔男声 | 男 |
| zh_male_pengpaixiaoshu_moon_bigtts | 澎湃男声 | 男 |

#### Doubao 2.0 (seed-tts-2.0) - 12 种
| 音色标识 | 名称 | 性别 |
|----------|------|------|
| BV001_V2_streaming | 清新女声 V2 | 女 |
| BV002_V2_streaming | 温柔女声 V2 | 女 |
| BV003_V2_streaming | 活泼女声 V2 | 女 |
| BV004_V2_streaming | 知性女声 V2 | 女 |
| BV005_V2_streaming | 清朗男声 V2 | 男 |
| BV006_V2_streaming | 沉稳男声 V2 | 男 |
| zh_female_wanqu_lily_mars_bigtts | 婉转女声 Lily | 女 |
| zh_female_sajiao_sida_mars_bigtts | 撒娇女声 Sida | 女 |
| zh_female_cancan_yuni_mars_bigtts | 灿烂女声 Yuni | 女 |
| zh_male_yuanboxiaoshu_tob_mars_bigtts | 渊博男声 | 男 |
| zh_female_wenrou_yanyu_mars_bigtts | 温柔女声 Yanyu | 女 |
| zh_female_shuangkuaicancan_mars_bigtts | 爽快女声 Cancan | 女 |

#### 自定义音色
支持在设置中添加自定义音色 ID，自动保存到本地存储。

### API 格式

#### 请求

```http
POST https://openspeech.bytedance.com/api/v3/tts/unidirectional
Content-Type: application/json
X-Api-App-Id: {app_id}
X-Api-Access-Key: {access_key}
X-Api-Resource-Id: seed-tts-1.0 | seed-tts-2.0

{
  "user": {
    "uid": "388808087185088"
  },
  "req_params": {
    "text": "需要合成的文本",
    "speaker": "BV001_streaming",
    "audio_params": {
      "format": "mp3",
      "sample_rate": 24000
    },
    // Doubao 1.0 需要 model 字段
    "model": "seed-tts-1.1"
  }
}
```

**版本差异：**
- Doubao 1.0 (`seed-tts-1.0`): 需要 `model: "seed-tts-1.1"`
- Doubao 2.0 (`seed-tts-2.0`): **不需要** `model` 字段

#### 响应格式 (NDJSON)

流式响应，每行一个 JSON 对象：

```jsonl
{"code":0,"data":"base64_audio_chunk"}
{"code":0,"sentence":{"text":"第一句","words":[{"text":"第","start_time":0,"end_time":80},{"text":"一","start_time":80,"end_time":160}]}}
{"code":20000000,"message":"success"}
```

**事件类型：**
| 字段 | 说明 |
|------|------|
| `code: 0 + data` | 音频数据（Base64 编码） |
| `code: 0 + sentence` | 字幕信息（文本 + 时间戳） |
| `code: 20000000` | 流结束标记 |

### 流式播放架构

```
┌─────────────────────────────────────────────────────────────┐
│  TTS API (火山引擎)                                          │
│  POST /api/v3/tts/unidirectional                            │
│  Content-Type: application/json (NDJSON stream)             │
└─────────────────────────────┬───────────────────────────────┘
                              │ ResponseBody.stream
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  TtsService.streamAudioV2()                                 │
│  - NDJSON 解析                                               │
│  - 音频 Base64 解码 → Stream<TtsStreamEvent.audio>          │
│  - 字幕提取 → Stream<TtsStreamEvent.subtitle>               │
└─────────────────────────────┬───────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐       ┌───────────────────────────┐
│ 流式播放 (详情页)        │       │ 文件缓存 (列表页)          │
│ TtsStreamPlayer         │       │ TtsService.streamToFile() │
│ - BytesSource 实时播放   │       │ - 完整合成后保存 MP3       │
│ - 字幕同步高亮           │       │ - 多音色独立缓存           │
└─────────────────────────┘       └───────────────────────────┘
```

### 调试日志

应用内置调试日志系统，记录所有 TTS 请求和响应：

**日志内容：**
- ✅ 请求参数（URL、Headers、Body）
- ✅ 响应数据（状态码、数据长度）
- ❌ 错误信息（异常堆栈）

**查看方式：**
设置 → TTS 配置 → 查看日志

## 更新记录

### v1.7.0 (2026-02-04)
- ✨ 新增全局主题系统，支持 6 种中国传统色（朱砂/竹青/黛蓝/栀子/暮山紫/玄青）
- ✨ 新增深色模式支持（跟随系统/浅色/深色三档切换）
- ✨ 书架页新增固定搜索栏，支持实时搜索（标题/作者/内容）
- ✨ 收藏页新增搜索功能，与书架页风格统一
- ✨ 新增通用弹窗组件 AppDialog，统一全应用弹窗风格
- 🔧 重构书架页和收藏页布局，视觉风格统一
- 🔧 诗词列表项组件化，复用性提升
- 🐛 修复添加作品界面朝代选择器报错
- 🐛 修复播放列表跳转错误问题
- 🐛 修复弹窗确定按钮无法点击问题

### v1.6.0 (2026-02-04)
- ✨ 重构设置页面为 Cherry Studio 风格（分组卡片式布局）
- ✨ 新增"使用系统字体"切换功能（MiSans/思源宋体）
- ✨ 重构 AI 模型配置为服务商列表模式
- ✨ 支持多服务商独立配置（Kimi/DeepSeek/火山/阿里/OpenAI）
- ✨ 新增服务商 Logo 显示（支持自定义品牌色回退）
- ✨ TTS 配置页面重构，支持火山引擎详细配置
- 🔧 优化设置页导航结构（主页→子页面模式）
- 🔧 字体切换实时生效，无需重启应用
- 🐛 修复 Android 13 存储权限兼容性问题

### v1.5.0 (2026-02-04)
- ✨ 新增自动更新功能，支持从 GitHub Releases 检查更新
- ✨ 设置页面新增"检查更新"入口
- ✨ 启动后自动静默检查更新
- ✨ 国内镜像加速下载支持 (mirror.ghproxy.com)
- 🔧 书架页面分组按钮样式优化，高度降低
- 🔧 书架页面收藏按钮移至右侧
- 🔧 修复分组内播放逻辑，正确触发 MiniPlayer
- 🔧 修复播放列表暂停后无法播放新文件的问题
- 🐛 修复分组页面重复"全部"按钮问题
- 🐛 修复分组内容实时刷新问题

### v1.4.0 (2026-02-04)
- ✨ 新增全局迷你播放控制条（参考QQ音乐设计）
- ✨ MiniPlayer支持旋转意境图标、播放进度环
- ✨ 播放列表管理BottomSheet
- ✨ 全局播放控制，切换Tab保持播放状态
- ✨ 书架/收藏/分组页面防MiniPlayer遮挡优化

### v1.3.0 (2026-02-04)
- ✨ 新增卡拉OK逐字高亮朗读功能
- ✨ AI配置API KEY支持明文/密文切换显示
- ✨ AI模型高级配置改为展开式，使用更便捷
- ✨ 关于页面支持查看完整更新记录
- ✨ 关于页面增加作者信息
- ✨ 关于页面增加GitHub仓库地址
- ✨ TTS日志系统优化，所有日志统一收集
- 🐛 修复数据库升级导致的诗词展示问题
- 🐛 修复默认诗词数据缺少clean_content字段

### v1.2.0 (2026-02-03)
- ✨ 新增独立分组浏览界面，支持查看各分组内容
- ✨ 新增分组顺序播放功能，支持连续播放分组内诗词
- ✨ 音色选择器显示缓存状态标识
- ✨ 书架页面改为列表布局，操作更便捷
- ✨ 播放内容包含标题和作者信息
- 🐛 修复数据库表创建问题
- 🐛 修复诗词排序问题

### v1.1.0 (2026-02-02)
- ✨ 新增流式播放功能，边合成边播放
- ✨ 支持 Doubao 1.0/2.0 双版本音色（各 12 种）
- ✨ 新增自定义音色支持
- ✨ 新增调试日志查看器
- ✨ 诗词列表支持网格布局
- ✨ 支持分组拖拽排序
- 🐛 修复多个已知问题

### v1.0.0
- 🎉 初始版本发布

## 许可证

MIT License
