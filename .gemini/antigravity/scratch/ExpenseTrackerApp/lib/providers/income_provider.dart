import 'package:flutter/material.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../data/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  List<IncomeSource> _sources = [];
  List<IncomeEntry> _entries = [];
  TransactionType _currentType = TransactionType.personal;

  List<IncomeSource> get allSources => _sources;
  List<IncomeEntry> get allEntries => _entries;

  List<IncomeSource> get sources => _sources.where((s) => s.type == _currentType).toList();
  List<IncomeEntry> get entries => _entries.where((e) => e.type == _currentType).toList();

  void updateType(TransactionType type) {
    _currentType = type;
    notifyListeners();
  }

  Future<void> fetchSources() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('income_sources');
    _sources = result.map((json) => IncomeSource.fromMap(json)).toList();
    notifyListeners();
  }

  Future<void> fetchEntries() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('income_entries', orderBy: 'date DESC');
    _entries = result.map((json) => IncomeEntry.fromMap(json)).toList();
    notifyListeners();
  }

  Future<void> addSource(IncomeSource source) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('income_sources', source.toMap());
    await fetchSources();
  }

  Future<void> updateSource(IncomeSource source) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'income_sources',
      source.toMap(),
      where: 'id = ?',
      whereArgs: [source.id],
    );
    await fetchSources();
  }

  Future<void> deleteSource(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
    await fetchSources();
  }

  Future<void> addEntry(IncomeEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('income_entries', entry.toMap());
    await fetchEntries();
  }

  Future<void> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('income_entries', where: 'id = ?', whereArgs: [id]);
    await fetchEntries();
  }

  // Personal Totals
  double get personalTodayIncome => _entries
      .where((e) => e.type == TransactionType.personal && _isToday(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  double get personalWeeklyIncome => _entries
      .where((e) => e.type == TransactionType.personal && _isThisWeek(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  double get personalMonthlyIncome => _entries
      .where((e) => e.type == TransactionType.personal && _isThisMonth(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  // Business Totals
  double get businessTodayIncome => _entries
      .where((e) => e.type == TransactionType.business && _isToday(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  double get businessWeeklyIncome => _entries
      .where((e) => e.type == TransactionType.business && _isThisWeek(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  double get businessMonthlyIncome => _entries
      .where((e) => e.type == TransactionType.business && _isThisMonth(e.date))
      .fold(0, (sum, e) => sum + e.amount);

  // General Helpers
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1)));
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  double get todayIncome => _currentType == TransactionType.personal ? personalTodayIncome : businessTodayIncome;
  double get weeklyIncome => _currentType == TransactionType.personal ? personalWeeklyIncome : businessWeeklyIncome;
  double get monthlyIncome => _currentType == TransactionType.personal ? personalMonthlyIncome : businessMonthlyIncome;

  Map<String, double> get sourceWiseIncome {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthEntries = entries
        .where((e) => e.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))));
    
    Map<String, double> summary = {};
    for (var e in monthEntries) {
      final source = _sources.firstWhere((s) => s.id == e.sourceId, orElse: () => IncomeSource(name: 'Unknown', type: _currentType));
      summary[source.name] = (summary[source.name] ?? 0) + e.amount;
    }
    return summary;
  }
}
