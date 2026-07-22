import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../data/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  TransactionType _currentType = TransactionType.personal;
  List<Category> _categories = [];
  List<Transaction> _transactions = [];

  TransactionType get currentType => _currentType;
  List<Category> get categories => _categories.where((c) => c.type == _currentType).toList();
  List<Transaction> get transactions => _transactions.where((t) => t.type == _currentType).toList();
  List<Transaction> get allTransactions => _transactions;

  void toggleType() {
    _currentType = _currentType == TransactionType.personal 
        ? TransactionType.business 
        : TransactionType.personal;
    notifyListeners();
  }

  void updateType(TransactionType type) {
    _currentType = type;
    notifyListeners();
  }

  double get personalMonthlySpending => _transactions
      .where((t) => t.type == TransactionType.personal && _isThisMonth(t.date))
      .fold(0, (sum, t) => sum + t.amount);

  double get businessMonthlySpending => _transactions
      .where((t) => t.type == TransactionType.business && _isThisMonth(t.date))
      .fold(0, (sum, t) => sum + t.amount);

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  Future<void> fetchCategories() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('categories');
    _categories = result.map((json) => Category.fromMap(json)).toList();
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    _transactions = result.map((json) => Transaction.fromMap(json)).toList();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('transactions', transaction.toMap());
    await fetchTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await fetchTransactions();
  }

  Future<void> addCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', category.toMap());
    await fetchCategories();
  }

  Future<void> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await fetchCategories();
  }

  double get todaySpending {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return transactions
        .where((t) => t.date.isAfter(today.subtract(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get monthlySpending {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return transactions
        .where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get categorySpending {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))));
    
    Map<String, double> spending = {};
    for (var t in monthTransactions) {
      final category = _categories.firstWhere((c) => c.id == t.categoryId, orElse: () => Category(name: 'Unknown', type: _currentType));
      spending[category.name] = (spending[category.name] ?? 0) + t.amount;
    }
    return spending;
  }
}
