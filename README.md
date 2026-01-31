# 古韵诵读 (GuYunReader)

一款利用云端 AI 语音合成技术朗读古诗词的 Flutter 应用。

## 功能特性

- 📜 **诗词展示**：新中式极简风格，米白色背景配衬线字体
- 🔊 **AI 朗读**：接入字节跳动/火山引擎 TTS API
- 💾 **智能缓存**：云端+本地双轨机制，二次播放无需联网
- ⏯️ **播放控制**：支持播放、暂停、停止、进度拖动
- 🔍 **诗词搜索**：支持按标题、作者、内容搜索

## 项目结构

```
lib/
├── constants/
│   └── app_constants.dart      # 应用常量配置（API、UI、数据库等）
├── controllers/
│   └── poem_controller.dart    # GetX 控制器（状态管理）
├── models/
│   └── poem.dart               # 诗词数据模型
├── pages/
│   ├── poem_list_page.dart     # 诗词列表页
│   └── poem_detail_page.dart   # 诗词详情页
├── services/
│   ├── database_helper.dart    # SQLite 数据库帮助类
│   └── tts_service.dart        # TTS 服务（核心业务逻辑）
├── utils/
│   └── audio_utils.dart        # 音频工具类
├── widgets/                    # 可复用组件（预留）
└── main.dart                   # 应用入口
```

## 技术栈

- **状态管理**：GetX
- **数据库**：sqflite
- **网络请求**：dio
- **音频播放**：audioplayers
- **本地存储**：path_provider

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 配置 API Key

在 `lib/constants/app_constants.dart` 中配置您的火山引擎 API Key：

```dart
static const String apiKey = 'YOUR_VOLCENGINE_API_KEY_HERE';
```

### 3. 添加字体

将 Noto Serif SC（思源宋体）字体文件放入 `assets/fonts/` 目录：
- `NotoSerifSC-Regular.ttf`
- `NotoSerifSC-Bold.ttf`

字体下载：https://fonts.google.com/noto/specimen/Noto+Serif+SC

### 4. 配置 Android 权限

修改 `android/app/src/main/AndroidManifest.xml`，添加网络和存储权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 5. 运行应用

```bash
flutter run
```

## 核心业务逻辑

### 云端+本地双轨机制

```
用户点击"朗读"
        │
        ▼
查询数据库 local_audio_path
        │
    ┌───┴───┐
    ▼       ▼
  存在     不存在
    │       │
    ▼       ▼
检查文件   调用 TTS API
是否存在   下载音频
    │       │
    ▼       ▼
  有效     保存到本地
    │     更新数据库
    ▼       │
播放本地   ▼
  音频    播放音频
```

## 预置诗词

应用预置了以下经典古诗：

1. 《静夜思》 - 李白
2. 《春晓》 - 孟浩然
3. 《登鹳雀楼》 - 王之涣
4. 《江雪》 - 柳宗元
5. 《水调歌头》 - 苏轼

## 许可证

MIT License
