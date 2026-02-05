import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/poem_new.dart';
import '../models/collection.dart';

/// 数据库帮助类 - 标签+歌单架构
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // 数据库版本（架构变更时递增）
  static const int _databaseVersion = 3;
  static const String _databaseName = 'tongsheng_guyun.db';

  // 表名
  static const String _tablePoems = 'poems';
  static const String _tableTags = 'tags';
  static const String _tablePoemTags = 'poem_tags';
  static const String _tableCollections = 'collections';
  static const String _tableCollectionPoems = 'collection_poems';
  static const String _tableVoiceCaches = 'voice_caches';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表结构
  Future<void> _onCreate(Database db, int version) async {
    // 1. 诗词表
    await db.execute('''
      CREATE TABLE $_tablePoems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        clean_content TEXT NOT NULL,
        annotated_content TEXT NOT NULL,
        local_audio_path TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. 标签表
    await db.execute('''
      CREATE TABLE $_tableTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 3. 诗词-标签关联表
    await db.execute('''
      CREATE TABLE $_tablePoemTags (
        poem_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (poem_id, tag_id),
        FOREIGN KEY (poem_id) REFERENCES $_tablePoems(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $_tableTags(id) ON DELETE CASCADE
      )
    ''');

    // 4. 小集/歌单表
    await db.execute('''
      CREATE TABLE $_tableCollections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        cover_image TEXT,
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. 小集内容表
    await db.execute('''
      CREATE TABLE $_tableCollectionPoems (
        collection_id INTEGER NOT NULL,
        poem_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (collection_id, poem_id),
        FOREIGN KEY (collection_id) REFERENCES $_tableCollections(id) ON DELETE CASCADE,
        FOREIGN KEY (poem_id) REFERENCES $_tablePoems(id) ON DELETE CASCADE
      )
    ''');

    // 创建索引优化查询
    await db.execute('CREATE INDEX idx_poems_favorite ON $_tablePoems(is_favorite)');
    await db.execute('CREATE INDEX idx_poem_tags_poem ON $_tablePoemTags(poem_id)');
    await db.execute('CREATE INDEX idx_poem_tags_tag ON $_tablePoemTags(tag_id)');
    await db.execute('CREATE INDEX idx_collection_poems_collection ON $_tableCollectionPoems(collection_id)');
    await db.execute('CREATE INDEX idx_collection_poems_sort ON $_tableCollectionPoems(collection_id, sort_order)');
    
    // 创建语音缓存表
    await _createVoiceCacheTable(db);
  }

  /// 创建语音缓存表
  Future<void> _createVoiceCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableVoiceCaches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_id INTEGER NOT NULL,
        voice_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        timestamp_path TEXT,
        file_size INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE(poem_id, voice_type),
        FOREIGN KEY (poem_id) REFERENCES $_tablePoems(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_voice_caches_poem ON $_tableVoiceCaches(poem_id)');
    await db.execute('CREATE INDEX idx_voice_caches_voice ON $_tableVoiceCaches(voice_type)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从v1迁移到v2：删除旧表，重新创建
      await db.execute('DROP TABLE IF EXISTS poem_groups');
      await db.execute('DROP TABLE IF EXISTS poems_backup');
      
      // 新架构直接重新初始化
      await _onCreate(db, newVersion);
    }
    if (oldVersion < 3) {
      // 仉2迁移到v3：添加语音缓存表和小集置顶字段
      await _createVoiceCacheTable(db);
      // 添加小集置顶字段
      try {
        await db.execute('ALTER TABLE $_tableCollections ADD COLUMN is_pinned INTEGER DEFAULT 0');
      } catch (e) {
        // 字段可能已存在
      }
    }
  }

  // ==================== 初始化数据 ====================

  /// 检查是否需要初始化数据
  Future<bool> needInitialization() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tablePoems'),
    );
    return count == 0;
  }

  /// 从JSON初始化内置数据
  Future<void> initializeBuiltinData() async {
    final db = await database;
    
    try {
      // 读取JSON文件
      final jsonString = await rootBundle.loadString('assets/data/builtin_poems.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      await db.transaction((txn) async {
        for (final json in jsonList) {
          await _insertPoemWithTags(txn, json);
        }
      });

      print('DatabaseHelper: 成功初始化 ${jsonList.length} 首诗词');
    } catch (e) {
      print('DatabaseHelper: 初始化数据失败 - $e');
      rethrow;
    }
  }

  /// 插入诗词及其标签（事务内）
  Future<void> _insertPoemWithTags(Transaction txn, Map<String, dynamic> json) async {
    // 1. 插入诗词
    final poem = Poem.fromJson(json);
    final poemId = await txn.insert(_tablePoems, poem.toMap());

    // 2. 处理标签
    final tags = json['tags'] as List<dynamic>? ?? [];
    for (final tagName in tags) {
      // 查找或创建标签
      final tagId = await _getOrCreateTag(txn, tagName as String);
      
      // 建立关联
      await txn.insert(_tablePoemTags, {
        'poem_id': poemId,
        'tag_id': tagId,
      });
    }
  }

  /// 获取或创建标签（返回tagId）
  Future<int> _getOrCreateTag(Transaction txn, String name) async {
    // 尝试查找
    final results = await txn.query(
      _tableTags,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['id'] as int;
    }

    // 创建新标签
    return await txn.insert(_tableTags, {'name': name});
  }

  // ==================== 诗词操作 ====================

  /// 获取所有诗词
  Future<List<Poem>> getAllPoems() async {
    final db = await database;
    final maps = await db.query(_tablePoems, orderBy: 'created_at DESC');
    
    final poems = <Poem>[];
    for (final map in maps) {
      final poem = Poem.fromMap(map);
      final tags = await getTagsForPoem(poem.id!);
      poems.add(poem.copyWith(tags: tags));
    }
    return poems;
  }

  /// 按标签获取诗词
  Future<List<Poem>> getPoemsByTag(String tagName) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT p.* FROM $_tablePoems p
      INNER JOIN $_tablePoemTags pt ON p.id = pt.poem_id
      INNER JOIN $_tableTags t ON pt.tag_id = t.id
      WHERE t.name = ?
      ORDER BY p.created_at DESC
    ''', [tagName]);

    final poems = <Poem>[];
    for (final map in maps) {
      final poem = Poem.fromMap(map);
      final tags = await getTagsForPoem(poem.id!);
      poems.add(poem.copyWith(tags: tags));
    }
    return poems;
  }

  /// 搜索诗词
  Future<List<Poem>> searchPoems(String query) async {
    final db = await database;
    final keyword = '%$query%';
    final maps = await db.query(
      _tablePoems,
      where: 'title LIKE ? OR author LIKE ? OR clean_content LIKE ?',
      whereArgs: [keyword, keyword, keyword],
      orderBy: 'created_at DESC',
    );

    final poems = <Poem>[];
    for (final map in maps) {
      final poem = Poem.fromMap(map);
      final tags = await getTagsForPoem(poem.id!);
      poems.add(poem.copyWith(tags: tags));
    }
    return poems;
  }

  /// 获取收藏诗词
  Future<List<Poem>> getFavoritePoems() async {
    final db = await database;
    final maps = await db.query(
      _tablePoems,
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );

    final poems = <Poem>[];
    for (final map in maps) {
      final poem = Poem.fromMap(map);
      final tags = await getTagsForPoem(poem.id!);
      poems.add(poem.copyWith(tags: tags));
    }
    return poems;
  }

  /// 获取单首诗词
  Future<Poem?> getPoem(int id) async {
    final db = await database;
    final maps = await db.query(
      _tablePoems,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    final poem = Poem.fromMap(maps.first);
    final tags = await getTagsForPoem(poem.id!);
    return poem.copyWith(tags: tags);
  }

  /// 插入诗词
  Future<int> insertPoem(Poem poem, {List<String> tagNames = const []}) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      final poemId = await txn.insert(_tablePoems, poem.toMap());
      
      // 处理标签
      for (final name in tagNames) {
        final tagId = await _getOrCreateTag(txn, name);
        await txn.insert(_tablePoemTags, {
          'poem_id': poemId,
          'tag_id': tagId,
        });
      }
      
      return poemId;
    });
  }

  /// 更新诗词
  Future<void> updatePoem(Poem poem, {List<String>? tagNames}) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.update(
        _tablePoems,
        poem.toMap(),
        where: 'id = ?',
        whereArgs: [poem.id],
      );

      // 如果提供了标签，更新标签
      if (tagNames != null) {
        // 删除旧关联
        await txn.delete(
          _tablePoemTags,
          where: 'poem_id = ?',
          whereArgs: [poem.id],
        );

        // 添加新关联
        for (final name in tagNames) {
          final tagId = await _getOrCreateTag(txn, name);
          await txn.insert(_tablePoemTags, {
            'poem_id': poem.id,
            'tag_id': tagId,
          });
        }
      }
    });
  }

  /// 删除诗词
  Future<void> deletePoem(int id) async {
    final db = await database;
    await db.delete(
      _tablePoems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      _tablePoems,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新音频路径
  Future<void> updateAudioPath(int id, String? path) async {
    final db = await database;
    await db.update(
      _tablePoems,
      {'local_audio_path': path},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 标签操作 ====================

  /// 获取所有标签（带诗词数量）
  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.*, COUNT(pt.poem_id) as poem_count 
      FROM $_tableTags t
      LEFT JOIN $_tablePoemTags pt ON t.id = pt.tag_id
      GROUP BY t.id
      ORDER BY poem_count DESC, t.name
    ''');

    return maps.map((map) => Tag(
      id: map['id'] as int,
      name: map['name'] as String,
      poemCount: map['poem_count'] as int,
    )).toList();
  }

  /// 获取诗词的标签
  Future<List<Tag>> getTagsForPoem(int poemId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM $_tableTags t
      INNER JOIN $_tablePoemTags pt ON t.id = pt.tag_id
      WHERE pt.poem_id = ?
      ORDER BY t.name
    ''', [poemId]);

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  // ==================== 标签管理操作 ====================

  /// 创建新标签
  Future<int> createTag(String name) async {
    final db = await database;
    try {
      return await db.insert(_tableTags, {'name': name});
    } catch (e) {
      // 标签已存在，返回现有标签ID
      final existing = await db.query(
        _tableTags,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }
      rethrow;
    }
  }

  /// 更新标签名称
  Future<void> updateTag(int tagId, String newName) async {
    final db = await database;
    await db.update(
      _tableTags,
      {'name': newName},
      where: 'id = ?',
      whereArgs: [tagId],
    );
  }

  /// 删除标签（会自动删除关联的 poem_tags 记录）
  Future<void> deleteTag(int tagId) async {
    final db = await database;
    await db.delete(
      _tableTags,
      where: 'id = ?',
      whereArgs: [tagId],
    );
  }

  /// 为诗词添加标签
  Future<void> addTagToPoem(int poemId, int tagId) async {
    final db = await database;
    try {
      await db.insert(_tablePoemTags, {
        'poem_id': poemId,
        'tag_id': tagId,
      });
    } catch (e) {
      // 关联已存在，忽略错误
    }
  }

  /// 为诗词移除标签
  Future<void> removeTagFromPoem(int poemId, int tagId) async {
    final db = await database;
    await db.delete(
      _tablePoemTags,
      where: 'poem_id = ? AND tag_id = ?',
      whereArgs: [poemId, tagId],
    );
  }

  /// 设置诗词的标签（完全替换）
  Future<void> setPoemTags(int poemId, List<int> tagIds) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. 删除现有标签关联
      await txn.delete(
        _tablePoemTags,
        where: 'poem_id = ?',
        whereArgs: [poemId],
      );
      // 2. 添加新标签关联
      for (final tagId in tagIds) {
        try {
          await txn.insert(_tablePoemTags, {
            'poem_id': poemId,
            'tag_id': tagId,
          });
        } catch (e) {
          // 忽略重复错误
        }
      }
    });
  }

  // ==================== 小集操作 ====================

  /// 获取所有小集（带诗词数量）
  Future<List<Collection>> getAllCollections() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.*, COUNT(cp.poem_id) as poem_count 
      FROM $_tableCollections c
      LEFT JOIN $_tableCollectionPoems cp ON c.id = cp.collection_id
      GROUP BY c.id
      ORDER BY c.is_pinned DESC, c.created_at DESC
    ''');

    return maps.map((map) => Collection(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      coverImage: map['cover_image'] as String?,
      isPinned: (map['is_pinned'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      poemCount: map['poem_count'] as int,
    )).toList();
  }

  /// 获取小集详情（包含诗词列表）
  Future<Collection?> getCollection(int id) async {
    final db = await database;
    
    // 获取小集信息
    final collectionMaps = await db.query(
      _tableCollections,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (collectionMaps.isEmpty) return null;

    final collection = Collection.fromMap(collectionMaps.first);

    // 获取小集内的诗词
    final itemMaps = await db.rawQuery('''
      SELECT cp.*, p.* FROM $_tableCollectionPoems cp
      INNER JOIN $_tablePoems p ON cp.poem_id = p.id
      WHERE cp.collection_id = ?
      ORDER BY cp.sort_order ASC
    ''', [id]);

    final items = <CollectionItem>[];
    for (final map in itemMaps) {
      final poem = Poem.fromMap(map);
      final tags = await getTagsForPoem(poem.id!);
      items.add(CollectionItem(
        collectionId: id,
        poemId: poem.id!,
        sortOrder: map['sort_order'] as int,
        poem: poem.copyWith(tags: tags),
      ));
    }

    return collection.copyWith(
      items: items,
      poemCount: items.length,
    );
  }

  /// 创建小集
  Future<int> insertCollection(Collection collection) async {
    final db = await database;
    return await db.insert(_tableCollections, collection.toMap());
  }

  /// 更新小集
  Future<void> updateCollection(Collection collection) async {
    final db = await database;
    await db.update(
      _tableCollections,
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  /// 删除小集
  Future<void> deleteCollection(int id) async {
    final db = await database;
    await db.delete(
      _tableCollections,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 设置小集置顶状态
  Future<void> setCollectionPinned(int id, bool isPinned) async {
    final db = await database;
    await db.update(
      _tableCollections,
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 添加诗词到小集
  Future<void> addPoemToCollection(int collectionId, int poemId) async {
    final db = await database;
    
    // 获取当前最大sort_order
    final result = await db.rawQuery('''
      SELECT MAX(sort_order) as max_order 
      FROM $_tableCollectionPoems 
      WHERE collection_id = ?
    ''', [collectionId]);
    
    final maxOrder = result.first['max_order'] as int? ?? -1;
    
    await db.insert(_tableCollectionPoems, {
      'collection_id': collectionId,
      'poem_id': poemId,
      'sort_order': maxOrder + 1,
    });
  }

  /// 从小集移除诗词
  Future<void> removePoemFromCollection(int collectionId, int poemId) async {
    final db = await database;
    await db.delete(
      _tableCollectionPoems,
      where: 'collection_id = ? AND poem_id = ?',
      whereArgs: [collectionId, poemId],
    );
  }

  /// 更新小集内诗词排序
  Future<void> updateCollectionOrder(int collectionId, List<int> poemIds) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (int i = 0; i < poemIds.length; i++) {
        await txn.update(
          _tableCollectionPoems,
          {'sort_order': i},
          where: 'collection_id = ? AND poem_id = ?',
          whereArgs: [collectionId, poemIds[i]],
        );
      }
    });
  }

  // ==================== 统计 ====================

  /// 获取统计数据
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final poemCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tablePoems'),
    ) ?? 0;
    
    final favoriteCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tablePoems WHERE is_favorite = 1'),
    ) ?? 0;
    
    final tagCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableTags'),
    ) ?? 0;
    
    final collectionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableCollections'),
    ) ?? 0;

    return {
      'poems': poemCount,
      'favorites': favoriteCount,
      'tags': tagCount,
      'collections': collectionCount,
    };
  }

  // ==================== 兼容旧代码的方法 ====================
  
  /// 单例模式（兼容旧代码）
  static DatabaseHelper get instance => _instance;

  /// 初始化（兼容旧代码）
  Future<void> initialize() async {
    await database;
  }

  /// 获取诗词通过ID（兼容旧代码）
  /// 注意：返回旧模型格式的 Map
  Future<Map<String, dynamic>?> getPoemById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tablePoems,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    final map = maps.first;
    
    // 转换为旧格式
    return _convertToOldFormat(map);
  }

  /// 获取所有分组（兼容旧代码 - 返回空列表）
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    // 新架构不使用 group，返回空列表保持兼容
    return [];
  }

  /// 插入分组（兼容旧代码 - 空实现）
  Future<int> insertGroup(Map<String, dynamic> group) async {
    // 新架构不使用 group
    return -1;
  }

  /// 删除分组（兼容旧代码 - 空实现）
  Future<void> deleteGroup(int id) async {
    // 新架构不使用 group
  }

  /// 更新分组排序（兼容旧代码 - 空实现）
  Future<void> updateGroupsSortOrder(List<Map<String, dynamic>> groups) async {
    // 新架构不使用 group
  }

  /// 更新分组（兼容旧代码 - 空实现）
  Future<void> updateGroup(Map<String, dynamic> group) async {
    // 新架构不使用 group
  }

  /// 更新诗词分组（兼容旧代码 - 空实现）
  Future<void> updatePoemGroup(int poemId, int? groupId) async {
    // 新架构不使用 group
  }

  // toggleFavorite 已在上方定义，此处省略

  /// 获取语音缓存
  Future<Map<String, dynamic>?> getVoiceCache(int poemId, String voiceType) async {
    final db = await database;
    final maps = await db.query(
      _tableVoiceCaches,
      where: 'poem_id = ? AND voice_type = ?',
      whereArgs: [poemId, voiceType],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// 保存语音缓存
  Future<void> saveVoiceCache(Map<String, dynamic> cache) async {
    final db = await database;
    await db.insert(
      _tableVoiceCaches,
      cache,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取诗词的所有语音缓存
  Future<List<Map<String, dynamic>>> getVoiceCachesForPoem(int poemId) async {
    final db = await database;
    return await db.query(
      _tableVoiceCaches,
      where: 'poem_id = ?',
      whereArgs: [poemId],
      orderBy: 'created_at DESC',
    );
  }

  /// 删除语音缓存
  Future<void> deleteVoiceCache(int cacheId) async {
    final db = await database;
    await db.delete(
      _tableVoiceCaches,
      where: 'id = ?',
      whereArgs: [cacheId],
    );
  }

  /// 删除诗词的所有语音缓存
  Future<void> deleteAllVoiceCachesForPoem(int poemId) async {
    final db = await database;
    await db.delete(
      _tableVoiceCaches,
      where: 'poem_id = ?',
      whereArgs: [poemId],
    );
  }

  /// 更新诗词音频路径（兼容旧代码）
  Future<void> updatePoemAudioPath(int poemId, String? path) async {
    final db = await database;
    await db.update(
      _tablePoems,
      {'local_audio_path': path},
      where: 'id = ?',
      whereArgs: [poemId],
    );
  }

  /// 获取所有语音缓存
  Future<List<Map<String, dynamic>>> getAllVoiceCaches() async {
    final db = await database;
    return await db.query(_tableVoiceCaches);
  }

  /// 清除所有语音缓存
  Future<void> clearAllVoiceCaches() async {
    final db = await database;
    await db.delete(_tableVoiceCaches);
  }

  /// 获取语音缓存大小
  Future<int> getVoiceCacheSize() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(file_size) as total_size FROM $_tableVoiceCaches',
    );
    return result.first['total_size'] as int? ?? 0;
  }

  /// 转换新格式为旧格式（兼容层）
  Map<String, dynamic> _convertToOldFormat(Map<String, dynamic> map) {
    // 解析 author 字段 "李白 [唐]"
    final author = map['author'] as String;
    final authorMatch = RegExp(r'(.+)\s*\[(.+?)\]').firstMatch(author);
    final authorName = authorMatch?.group(1)?.trim() ?? author;
    final dynasty = authorMatch?.group(2)?.trim();

    return {
      'id': map['id'],
      'title': map['title'],
      'author': authorName,
      'dynasty': dynasty,
      'content': map['clean_content'],
      'clean_content': map['clean_content'],
      'annotated_content': map['annotated_content'],
      'local_audio_path': map['local_audio_path'],
      'is_favorite': map['is_favorite'],
      'created_at': map['created_at'],
      'group_id': null, // 新架构无 group
    };
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
