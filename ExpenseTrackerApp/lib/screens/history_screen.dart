import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    var transactions = expenseProvider.transactions;

    // Apply filters
    if (_startDate != null) {
      transactions = transactions.where((t) => t.date.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      transactions = transactions.where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }
    if (_filterCategoryId != null) {
      transactions = transactions.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportToCSV(transactions, expenseProvider.categories),
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, expenseProvider),
          ),
        ],
      ),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final category = expenseProvider.categories.firstWhere(
                  (c) => c.id == transaction.categoryId,
                  orElse: () => Category(name: 'Unknown', type: transaction.type),
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.receipt_long, size: 20),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction.description != null && transaction.description!.isNotEmpty)
                        Text(transaction.description!),
                      Text(dateFormat.format(transaction.date), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormat.format(transaction.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => expenseProvider.deleteTransaction(transaction.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showFilterDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                value: _filterCategoryId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) => setDialogState(() => _filterCategoryId = val),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setDialogState(() => _startDate = date);
                      },
                      child: Text(_startDate == null ? 'Start Date' : DateFormat('dd/MM').format(_startDate!)),
                    ),
                  ),
                  const Text('-'),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setDialogState(() => _endDate = date);
                      },
                      child: Text(_endDate == null ? 'End Date' : DateFormat('dd/MM').format(_endDate!)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _filterCategoryId = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV(List transactions, List<Category> categories) async {
    List<List<dynamic>> rows = [];
    rows.add(["Date", "Category", "Amount", "Description", "Type"]);

    for (var t in transactions) {
      final category = categories.firstWhere((c) => c.id == t.categoryId, orElse: () => Category(name: 'Unknown', type: t.type));
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        category.name,
        t.amount,
        t.description ?? "",
        t.type == TransactionType.personal ? "Personal" : "Business"
      ]);
    }

    String csvString = csv.encode(rows);
    final directory = await getExternalStorageDirectory();
    if (directory == null) return;
    
    final path = "${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvString);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    }
  }
}
