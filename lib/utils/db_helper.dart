import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/category_model.dart';
import '../../models/message_model.dart';
import '../../models/video_model.dart';
import '../core/constants/constants.dart';
import '../models/user_model.dart';
import 'shared_pref.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _getDbPath();
    final localVersion = SharedPref.getInt('db_version') ?? 0;

    // التحقق من الحاجة لنسخ قاعدة البيانات (أول مرة أو عند تحديث الإصدار)
    if (!await File(path).exists() || localVersion < Constants.dbVersion) {
      await _copyDatabaseFromAssets(path);
      await SharedPref.setInt('db_version', Constants.dbVersion);
    }

    // ✅ فتح قاعدة البيانات مع التأكد من أنها ليست للقراءة فقط
    final db = await openDatabase(
      path,
      version: Constants.dbVersion,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: _onUpgrade,
    );

    // إنشاء الجداول الناقصة
    await _createVideoTables(db);
    await _createIndexes(db);
    await _createFTS(db);

    return db;
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    // 🔹 1. قراءة قاعدة البيانات من الـ Assets
    final data = await rootBundle.load(Constants.database);
    final bytes = data.buffer.asUint8List();
    
    // 🔹 2. كتابة الملف في مسار التطبيق
    final file = File(path);
    if (await file.exists()) {
      // إغلاق قاعدة البيانات الحالية قبل الحذف إذا كانت مفتوحة
      await _database?.close();
      _database = null;
      await file.delete();
    }
    
    await file.writeAsBytes(bytes, flush: true);

    // 🔹 3. ✅ إصلاح حاسم: ضمان أن الملف الجديد قابل للكتابة (خصوصاً في أندرويد)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Process.run('chmod', ['666', path]);
      } catch (_) {
        // إذا فشل chmod (نادر جداً)، فلاتر يقوم بها تلقائياً في أغلب الحالات
      }
    }
  }

  Future<void> _createVideoTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS videos (
        id TEXT PRIMARY KEY,
        title TEXT,
        video_url TEXT,
        thumbnail TEXT,
        views_count INTEGER,
        likes_count INTEGER,
        created_at TEXT,
        user_id TEXT,
        user_name TEXT,
        user_photo TEXT
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_category ON messages(category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_favorite ON messages(is_favorite)');
  }

  Future<void> _createFTS(Database db) async {
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts4(
        content,
        category_id
      );
    ''');

    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM messages_fts'));
    if (count == 0) {
      await db.execute('''
        INSERT INTO messages_fts(rowid, content, category_id)
        SELECT id, content, category_id FROM messages;
      ''');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await _createVideoTables(db);
      await _createIndexes(db);
      await _createFTS(db);
    }
  }

  Future<List<MessageModel>> searchMessages({
    required String query,
    int? categoryId,
    int limit = 30,
    int offset = 0,
  }) async {
    final db = await database;
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    final ftsQuery = '"$cleanQuery"*';

    final sql = '''
      SELECT m.* FROM messages m
      JOIN messages_fts f ON m.id = f.rowid
      WHERE f.content MATCH ?
      ${categoryId != null ? 'AND m.category_id = ?' : ''}
      ORDER BY m.id DESC LIMIT ? OFFSET ?
    ''';

    final args = categoryId != null ? [ftsQuery, categoryId, limit, offset] : [ftsQuery, limit, offset];

    try {
      final maps = await db.rawQuery(sql, args);
      return maps.map((e) => MessageModel.fromMap(e)).toList();
    } catch (e) {
      final fallbackSql = 'SELECT * FROM messages WHERE content LIKE ? ${categoryId != null ? 'AND category_id = ?' : ''} ORDER BY id DESC LIMIT ? OFFSET ?';
      final fallbackArgs = categoryId != null ? ['%$cleanQuery%', categoryId, limit, offset] : ['%$cleanQuery%', limit, offset];
      final maps = await db.rawQuery(fallbackSql, fallbackArgs);
      return maps.map((e) => MessageModel.fromMap(e)).toList();
    }
  }

  Future<void> syncMessages(List<MessageModel> messages) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var msg in messages) {
        batch.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        batch.insert('messages_fts', {'rowid': msg.id, 'content': msg.content, 'category_id': msg.categoryId}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    final Map<int, int> newlyAddedByCat = {};
    for (var msg in messages) { newlyAddedByCat[msg.categoryId] = (newlyAddedByCat[msg.categoryId] ?? 0) + 1; }
    for (var entry in newlyAddedByCat.entries) { await recalculateCategoryCounters(entry.key, newlyAddedCount: entry.value); }
  }

  Future<void> cacheVideos(List<VideoModel> videos) async {
    final db = await database;
    await db.transaction((txn) async {
      if (videos.isNotEmpty) {
        await txn.delete('videos');
        for (var video in videos.take(50)) {
          await txn.insert('videos', {
            'id': video.id, 'title': video.title, 'video_url': video.videoUrl, 'thumbnail': video.thumbnail,
            'views_count': video.viewsCount, 'likes_count': video.likesCount, 'created_at': video.createdAt.toIso8601String(),
            'user_id': video.user.id, 'user_name': video.user.name, 'user_photo': video.user.photoUrl,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<List<VideoModel>> getCachedVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('videos');
    return maps.map((m) => VideoModel(
      id: m['id'], title: m['title'], videoUrl: m['video_url'], thumbnail: m['thumbnail'],
      viewsCount: m['views_count'], likesCount: m['likes_count'], createdAt: DateTime.parse(m['created_at']),
      user: UserModel(id: int.tryParse(m['user_id'].toString()) ?? 0, name: m['user_name'] ?? '', photoUrl: m['user_photo'] ?? ''),
    )).toList();
  }

  Future<void> syncCategories(List<CategoryModel> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var cat in categories) { batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
      await batch.commit(noResult: true);
    });
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<void> resetNewMessagesCounter(int categoryId) async {
    final db = await database;
    await db.update('categories', {'new_msg': 0}, where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<void> recalculateCategoryCounters(int categoryId, {int newlyAddedCount = 0}) async {
    final db = await database;
    await db.rawUpdate('UPDATE categories SET total_msg = (SELECT COUNT(*) FROM messages WHERE category_id = ?), new_msg = new_msg + ? WHERE id = ?', [categoryId, newlyAddedCount, categoryId]);
  }

  Future<List<MessageModel>> getMessages({required int categoryId, int limit = 30, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('messages', where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'id DESC', limit: limit, offset: offset);
    return maps.map(MessageModel.fromMap).toList();
  }

  Future<List<MessageModel>> getFavoriteMessages({int? categoryId, int limit = 30, int offset = 0}) async {
    final db = await database;
    String where = 'is_favorite = 1';
    List<dynamic> args = [];
    if (categoryId != null) {
      where += ' AND category_id = ?';
      args.add(categoryId);
    }
    final maps = await db.query('messages', where: where, whereArgs: args, orderBy: 'id DESC', limit: limit, offset: offset);
    return maps.map(MessageModel.fromMap).toList();
  }

  Future<Set<int>> getAllFavoriteIds() async {
    final db = await database;
    final maps = await db.query('messages', columns: ['id'], where: 'is_favorite = 1');
    return maps.map((e) => e['id'] as int).toSet();
  }

  Future<List<CategoryModel>> getFavoriteCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, (SELECT COUNT(*) FROM messages m2 WHERE m2.category_id = c.id AND m2.is_favorite = 1) as fav_count
      FROM categories c
      WHERE EXISTS (SELECT 1 FROM messages m WHERE m.category_id = c.id AND m.is_favorite = 1)
      ORDER BY c.id ASC
    ''');
    return maps.map((m) => CategoryModel.fromMap({...m, 'total_msg': m['fav_count'], 'new_msg': 0})).toList();
  }

  Future<void> updateFavoriteStatus(int messageId, bool value) async {
    final db = await database;
    await db.update('messages', {'is_favorite': value ? 1 : 0}, where: 'id = ?', whereArgs: [messageId]);
  }

  Future<int> getLastCategoryId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM categories');
    return (result.first['max_id'] as int?) ?? 0;
  }

  Future<int> getLastMessageId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM messages');
    return (result.first['max_id'] as int?) ?? 0;
  }

  Future<String> _getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'data.db');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
