import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIncomeTables(db);
      await _insertDefaultIncomeSources(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        icon TEXT,
        monthlyLimit REAL,
        parentId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        type INTEGER NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE borrow_lend (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personName TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        isCleared INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createIncomeTables(db);
    await _insertDefaultCategories(db);
    await _insertDefaultIncomeSources(db);
  }

  Future _createIncomeTables(Database db) async {
    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE income_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        quantity INTEGER,
        customerName TEXT,
        type INTEGER NOT NULL,
        FOREIGN KEY (sourceId) REFERENCES income_sources (id)
      )
    ''');
  }

  Future _insertDefaultCategories(Database db) async {
    final personalCategories = ['Food', 'Transport', 'Rent', 'Shopping', 'Health', 'Other'];
    final businessCategories = ['Supplies', 'Marketing', 'Software', 'Travel', 'Salaries', 'Other'];

    for (var cat in personalCategories) {
      await db.insert('categories', {
        'name': cat,
        'type': 0, // PERSONAL
      });
    }

    for (var cat in businessCategories) {
      await db.insert('categories', {
        'name': cat,
        'type': 1, // BUSINESS
      });
    }
  }

  Future _insertDefaultIncomeSources(Database db) async {
    final personalSources = ['Salary', 'Freelance', 'Gift', 'Other'];
    final businessSources = [
      'Oversized Printing',
      'Oversized Wash Printing',
      'Printing Only',
      'External Orders',
      'Internal Sales'
    ];

    for (var source in personalSources) {
      await db.insert('income_sources', {
        'name': source,
        'type': 0, // PERSONAL
      });
    }

    for (var source in businessSources) {
      await db.insert('income_sources', {
        'name': source,
        'type': 1, // BUSINESS
      });
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
