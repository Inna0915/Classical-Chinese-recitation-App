# 古韵诵读 - 新架构设计文档 (v2.0)

## 架构概览

从"层级分组"模式转变为**"标签 + 歌单（小集）"**模式，实现**数据驱动的初始化**。

```
旧架构: Poem → Group (层级关系)
新架构: Poem ↔ Tag (多对多) + Poem → Collection (歌单)
```

## 数据库 Schema

### 表结构

#### 1. `poems` - 诗词表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| title | TEXT | 标题 |
| author | TEXT | 作者 [朝代] 格式 |
| clean_content | TEXT | 纯净版内容 |
| annotated_content | TEXT | 带释义版内容 |
| local_audio_path | TEXT | 本地音频路径 |
| is_favorite | INTEGER | 是否收藏 (0/1) |
| created_at | TEXT | 创建时间 |

#### 2. `tags` - 标签表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT UNIQUE | 标签名（唯一） |

#### 3. `poem_tags` - 诗词-标签关联表
| 字段 | 类型 | 说明 |
|------|------|------|
| poem_id | INTEGER FK | 诗词ID |
| tag_id | INTEGER FK | 标签ID |
| **PK** | (poem_id, tag_id) | 联合主键 |

#### 4. `collections` - 小集/歌单表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 小集名称 |
| description | TEXT | 描述 |
| cover_image | TEXT | 封面图路径 |
| created_at | TEXT | 创建时间 |

#### 5. `collection_poems` - 小集内容表
| 字段 | 类型 | 说明 |
|------|------|------|
| collection_id | INTEGER FK | 小集ID |
| poem_id | INTEGER FK | 诗词ID |
| sort_order | INTEGER | 排序顺序 |
| **PK** | (collection_id, poem_id) | 联合主键 |

## 数据初始化

### JSON 数据结构 (`assets/data/builtin_poems.json`)

```json
[
  {
    "title": "静夜思",
    "author": "李白 [唐]",
    "clean_content": "床前明月光...",
    "annotated_content": "床前明月光...\n【释义】...",
    "tags": ["古诗", "唐诗", "李白", "必背", "思乡"]
  }
]
```

### 初始化流程

1. App 启动时检查 `poems` 表是否为空
2. 若为空，读取 `assets/data/builtin_poems.json`
3. 遍历 JSON 数组：
   - 插入诗词到 `poems` 表
   - 检查/创建标签到 `tags` 表
   - 建立关联到 `poem_tags` 表

## 核心类设计

### 1. Model 层

#### `Poem` - 诗词模型
```dart
class Poem {
  final int? id;
  final String title;
  final String author;        // 格式: "李白 [唐]"
  final String cleanContent;
  final String annotatedContent;
  final String? localAudioPath;
  final bool isFavorite;
  final DateTime createdAt;
  final List<Tag> tags;       // 运行时填充
}
```

#### `Tag` - 标签模型
```dart
class Tag {
  final int? id;
  final String name;
  final int poemCount;        // 运行时计算
}
```

#### `Collection` - 小集模型
```dart
class Collection {
  final int? id;
  final String name;
  final String? description;
  final String? coverImage;
  final DateTime createdAt;
  final int poemCount;        // 运行时计算
  final List<CollectionItem> items;  // 详情时填充
}
```

#### `PlaybackContext` - 播放上下文
```dart
enum PlaybackContextType { all, tag, collection, favorite, search }

class PlaybackContext {
  final PlaybackContextType type;
  final String? tagName;      // type=tag
  final int? collectionId;    // type=collection
  final String? searchQuery;  // type=search
  final int? initialPoemId;   // 初始播放ID
}
```

### 2. Service 层

#### `DatabaseHelper` - 数据库操作
- Schema 创建和升级
- JSON 数据初始化
- CRUD 操作（诗词、标签、小集）
- 关联查询

#### `PoemService` - 业务逻辑 (GetX Service)
- 状态管理：`allPoems`, `allTags`, `allCollections`
- 筛选逻辑：标签筛选、搜索
- 播放上下文管理
- 小集管理（创建、编辑、排序）

### 3. UI 层

#### `BookshelfPage` - 书架页
- Cherry Studio 风格搜索栏（灰底圆角）
- 横向滚动的标签筛选栏
- 诗词卡片列表（显示标签 Chips）
- 支持滑动收起键盘

#### `CollectionsPage` - 小集页
- GridView 歌单封面墙
- 创建/编辑/删除小集
- 详情页支持拖拽排序
- "播放全部"功能

#### `CollectionDetailPage` - 小集详情
- 头部：歌单信息 + 播放按钮
- ReorderableListView 支持拖拽排序
- 点击播放（设置 collection 上下文）

## 播放队列逻辑

根据当前上下文生成播放队列：

| 场景 | 队列来源 | 排序 |
|------|---------|------|
| All | 全部诗词 | created_at DESC |
| Tag | 带该标签的诗词 | created_at DESC |
| Collection | 小集内的诗词 | sort_order ASC |
| Favorite | 收藏诗词 | created_at DESC |
| Search | 搜索结果 | 相关度 |

## 迁移策略

### 兼容性处理
- `PoemController` 保持原有接口（逐步迁移）
- `PoemService` 作为新架构入口
- 数据库版本升级：v1 → v2 重新创建表

### 后续工作
1. 迁移 `PoemDetailPage` 使用 `PoemService`
2. 迁移 `PlayerController` 使用 `PlaybackContext`
3. 添加 "添加到小集" BottomSheet
4. 替换 MainPage 使用新页面

## 文件结构

```
lib/
├── models/
│   ├── poem.dart              # Poem, Tag, PoemTag
│   └── collection.dart        # Collection, CollectionItem, PlaybackContext
├── services/
│   ├── database_helper.dart   # 新数据库架构
│   └── poem_service.dart      # 业务逻辑
├── pages/
│   ├── bookshelf_page.dart    # 新书架页
│   └── collections_page.dart  # 小集页面
└── assets/data/
    └── builtin_poems.json     # 初始化数据
```

## 技术特性

- **响应式状态管理**：GetX Rx 变量
- **数据驱动**：JSON 初始化，无需硬编码
- **灵活筛选**：标签系统支持多维度分类
- **歌单管理**：类似音乐 App 的小集功能
- **播放上下文**：智能生成播放队列
- **主题统一**：使用全局主题色
