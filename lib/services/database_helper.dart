import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../models/poem.dart';

/// 数据库帮助类 - 单例模式
/// 
/// 负责 SQLite 数据库的初始化和 CRUD 操作
/// 支持 Web 平台使用 ffi_web 实现
class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  /// 初始化数据库工厂（Web 平台需要）
  static void initialize() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
  }

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 确保初始化（Web 平台）
    initialize();

    String path;
    if (kIsWeb) {
      // Web 平台使用内存数据库或 IndexedDB
      path = DatabaseConstants.dbName;
    } else {
      // 获取应用文档目录
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, DatabaseConstants.dbName);
    }

    return await openDatabase(
      path,
      version: DatabaseConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.poemsTable} (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        dynasty TEXT,
        content TEXT NOT NULL,
        local_audio_path TEXT,
        created_at TEXT
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_poems_title ON ${DatabaseConstants.poemsTable}(title)
    ''');

    // 预置一些经典古诗数据
    await _insertDefaultPoems(db);
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级时在此处理
  }

  /// 插入默认诗词数据
  Future<void> _insertDefaultPoems(Database db) async {
    final defaultPoems = [
      {
        'id': 1,
        'title': '静夜思',
        'author': '李白',
        'dynasty': '唐',
        'content': '床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'title': '春晓',
        'author': '孟浩然',
        'dynasty': '唐',
        'content': '春眠不觉晓，处处闻啼鸟。\n夜来风雨声，花落知多少。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'title': '登鹳雀楼',
        'author': '王之涣',
        'dynasty': '唐',
        'content': '白日依山尽，黄河入海流。\n欲穷千里目，更上一层楼。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'title': '江雪',
        'author': '柳宗元',
        'dynasty': '唐',
        'content': '千山鸟飞绝，万径人踪灭。\n孤舟蓑笠翁，独钓寒江雪。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 5,
        'title': '望庐山瀑布',
        'author': '李白',
        'dynasty': '唐',
        'content': '日照香炉生紫烟，遥看瀑布挂前川。\n飞流直下三千尺，疑是银河落九天。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 6,
        'title': '早发白帝城',
        'author': '李白',
        'dynasty': '唐',
        'content': '朝辞白帝彩云间，千里江陵一日还。\n两岸猿声啼不住，轻舟已过万重山。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 7,
        'title': '赋得古原草送别',
        'author': '白居易',
        'dynasty': '唐',
        'content': '离离原上草，一岁一枯荣。\n野火烧不尽，春风吹又生。\n远芳侵古道，晴翠接荒城。\n又送王孙去，萋萋满别情。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 8,
        'title': '清明',
        'author': '杜牧',
        'dynasty': '唐',
        'content': '清明时节雨纷纷，路上行人欲断魂。\n借问酒家何处有？牧童遥指杏花村。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 9,
        'title': '相思',
        'author': '王维',
        'dynasty': '唐',
        'content': '红豆生南国，春来发几枝。\n愿君多采撷，此物最相思。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 10,
        'title': '水调歌头·明月几时有',
        'author': '苏轼',
        'dynasty': '宋',
        'content': '明月几时有？把酒问青天。\n不知天上宫阙，今夕是何年。\n我欲乘风归去，又恐琼楼玉宇，高处不胜寒。\n起舞弄清影，何似在人间。\n\n转朱阁，低绮户，照无眠。\n不应有恨，何事长向别时圆？\n人有悲欢离合，月有阴晴圆缺，此事古难全。\n但愿人长久，千里共婵娟。',
        'local_audio_path': null,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    final batch = db.batch();
    for (final poem in defaultPoems) {
      batch.insert(
        DatabaseConstants.poemsTable,
        poem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  // ==================== CRUD 操作 ====================

  /// 获取所有诗词
  Future<List<Poem>> getAllPoems() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.poemsTable,
      orderBy: 'id ASC',
    );
    return maps.map((map) => Poem.fromMap(map)).toList();
  }

  /// 根据 ID 获取诗词
  Future<Poem?> getPoemById(int id) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.poemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Poem.fromMap(maps.first);
  }

  /// 搜索诗词
  Future<List<Poem>> searchPoems(String keyword) async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.poemsTable,
      where: 'title LIKE ? OR author LIKE ? OR content LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'id ASC',
    );
    return maps.map((map) => Poem.fromMap(map)).toList();
  }

  /// 插入新诗词
  Future<int> insertPoem(Poem poem) async {
    final db = await database;
    return await db.insert(
      DatabaseConstants.poemsTable,
      poem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新诗词信息（主要用于更新本地音频路径）
  Future<int> updatePoem(Poem poem) async {
    final db = await database;
    return await db.update(
      DatabaseConstants.poemsTable,
      poem.toMap(),
      where: 'id = ?',
      whereArgs: [poem.id],
    );
  }

  /// 更新音频路径
  Future<int> updateAudioPath(int poemId, String? audioPath) async {
    final db = await database;
    return await db.update(
      DatabaseConstants.poemsTable,
      {'local_audio_path': audioPath},
      where: 'id = ?',
      whereArgs: [poemId],
    );
  }

  /// 删除诗词
  Future<int> deletePoem(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseConstants.poemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取已缓存音频的诗词列表
  Future<List<Poem>> getCachedPoems() async {
    final db = await database;
    final maps = await db.query(
      DatabaseConstants.poemsTable,
      where: 'local_audio_path IS NOT NULL',
      orderBy: 'id ASC',
    );
    return maps.map((map) => Poem.fromMap(map)).toList();
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
