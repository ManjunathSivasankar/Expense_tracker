import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../data/database_helper.dart';

class BorrowLendProvider with ChangeNotifier {
  List<BorrowLend> _records = [];

  List<BorrowLend> get records => _records;
  List<BorrowLend> get activeRecords => _records.where((r) => !r.isCleared).toList();

  Future<void> fetchRecords() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('borrow_lend', orderBy: 'date DESC');
    _records = result.map((json) => BorrowLend.fromMap(json)).toList();
    notifyListeners();
  }

  Future<void> addRecord(BorrowLend record) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('borrow_lend', record.toMap());
    await fetchRecords();
  }

  Future<void> updateRecord(BorrowLend record) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'borrow_lend',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    await fetchRecords();
  }

  Future<void> deleteRecord(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('borrow_lend', where: 'id = ?', whereArgs: [id]);
    await fetchRecords();
  }

  Future<void> toggleCleared(int id, bool currentStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'borrow_lend',
      {'isCleared': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchRecords();
  }

  double get totalBorrowed => _records
      .where((r) => r.type == BorrowLendType.borrowed && !r.isCleared)
      .fold(0, (sum, r) => sum + r.amount);

  double get totalGiven => _records
      .where((r) => r.type == BorrowLendType.given && !r.isCleared)
      .fold(0, (sum, r) => sum + r.amount);
}
