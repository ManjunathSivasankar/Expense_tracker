import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../data/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  TransactionType _currentType = TransactionType.personal;
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  DateTime _selectedMonth = DateTime.now();

  DateTime get selectedMonth => _selectedMonth;

  void setSelectedMonth(DateTime date) {
    _selectedMonth = date;
    notifyListeners();
  }

  TransactionType get currentType => _currentType;
  List<Category> get categories => _categories.where((c) => c.type == _currentType).toList();
  List<Transaction> get transactions => _transactions.where((t) => t.type == _currentType).toList();
  List<Transaction> get allTransactions => _transactions;
  List<Category> get allCategories => _categories;

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
    return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
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
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return transactions
          .where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
          .fold(0, (sum, t) => sum + t.amount);
    }
    return 0.0;
  }

  double get monthlySpending {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).subtract(const Duration(microseconds: 1));
    return transactions
        .where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && t.date.isBefore(endOfMonth))
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get categorySpending {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).subtract(const Duration(microseconds: 1));
    final monthTransactions = transactions
        .where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && t.date.isBefore(endOfMonth));
    
    Map<String, double> spending = {};
    for (var t in monthTransactions) {
      final category = _categories.firstWhere((c) => c.id == t.categoryId, orElse: () => Category(name: 'Unknown', type: _currentType));
      spending[category.name] = (spending[category.name] ?? 0) + t.amount;
    }
    return spending;
  }
}
