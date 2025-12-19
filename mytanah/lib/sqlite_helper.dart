import 'dart:async';
import 'package:mytanah/division.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  factory SQLiteHelper() => _instance;

  SQLiteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mytanah.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tanah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_geran TEXT UNIQUE,
        no_lot TEXT,
        jumlah_cukai REAL,
        jumlah_hektar REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE pembahagian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        geran_id INTEGER,
        pembilang INTEGER,
        penyebut INTEGER,
        FOREIGN KEY (geran_id) REFERENCES tanah (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<bool> isGeranExist(String noGeran) async {
    final db = await database;
    final result = await db.query(
      'tanah',
      where: 'no_geran = ?',
      whereArgs: [noGeran],
    );
    return result.isNotEmpty;
  }

  Future<int> insertTanah({
    required String noGeran,
    required String noLot,
    required double cukai,
    required double hektar,
  }) async {
    final db = await database;

    return await db.insert('tanah', {
      'no_geran': noGeran,
      'no_lot': noLot,
      'jumlah_cukai': cukai,
      'jumlah_hektar': hektar,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPembahagian(
    int geranId,
    List<Division> pembahagianList,
  ) async {
    final db = await database;

    // Clear old pembahagian for the same geran
    await db.delete('pembahagian', where: 'geran_id = ?', whereArgs: [geranId]);

    for (var pembahagian in pembahagianList) {
      // log("Inserting pembahagian");
      // log(pembahagian.numeratorController.text.toString());
      // log(pembahagian.denominatorController.text.toString());
      await db.insert('pembahagian', {
        'geran_id': geranId,
        'pembilang': int.tryParse(
          pembahagian.numeratorController.text.toString(),
        ),
        'penyebut': int.tryParse(
          pembahagian.denominatorController.text.toString(),
        ),
      });
    }
  }

  //implement delete based on id
  Future<void> deleteGeranAndPembahagianById(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('pembahagian', where: 'geran_id = ?', whereArgs: [id]);
      await txn.delete('tanah', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> saveData(
    String noGeran,
    String noLot,
    double cukai,
    double hektar,
    List<Division> pembahagianList,
  ) async {
    final exists = await isGeranExist(noGeran);
    if (exists) {
      throw Exception("Geran already exists");
    }
    // for (var d in pembahagianList) {
    //   log("HELLO");
    //   log(d.numeratorController.text);
    //   log(d.denominatorController.text);
    // }
    final geranId = await insertTanah(
      noGeran: noGeran,
      noLot: noLot,
      cukai: cukai,
      hektar: hektar,
    );

    await insertPembahagian(geranId, pembahagianList);
  }

  Future<List<Map<String, dynamic>>> getAllTanah() async {
    final db = await database;
    return await db.query('tanah');
  }

  Future<List<Map<String, dynamic>>> getPembahagianByGeranId(
    int geranId,
  ) async {
    final db = await database;
    return await db.query(
      'pembahagian',
      where: 'geran_id = ?',
      whereArgs: [geranId],
    );
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('pembahagian');
    await db.delete('tanah');
  }

  Future<void> updateGeranAndPembahagian(
    String noGeran,
    String noLot,
    double cukai,
    double hektar,
    List<Division> divisions,
  ) async {
    final db = await database;

    // Check if the geran already exists
    final existing = await db.query(
      'tanah',
      where: 'no_geran = ?',
      whereArgs: [noGeran],
    );

    if (existing.isNotEmpty) {
      final geranId = existing.first['id'] as int;

      // Delete existing records
      await db.delete(
        'pembahagian',
        where: 'geran_id = ?',
        whereArgs: [geranId],
      );
      await db.delete('tanah', where: 'id = ?', whereArgs: [geranId]);

      // Insert updated tanah
      final newId = await db.insert('tanah', {
        'no_geran': noGeran,
        'no_lot': noLot,
        'jumlah_cukai': cukai,
        'jumlah_hektar': hektar,
      });

      // Insert updated pembahagian
      for (var division in divisions) {
        await db.insert('pembahagian', {
          'geran_id': newId,
          'pembilang': division.numeratorController.text,
          'penyebut': division.denominatorController.text,
        });
      }
    } else {
      throw Exception("No geran found to update");
    }
  }
}
