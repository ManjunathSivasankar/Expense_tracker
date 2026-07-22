import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../widgets/delete_confirmation_dialog.dart';

class UnifiedTransaction {
  final String id;
  final int? dbId;
  final double amount;
  final String categoryOrSourceName;
  final String? description;
  final DateTime date;
  final bool isIncome;
  final TransactionType transactionType;

  UnifiedTransaction({
    required this.id,
    this.dbId,
    required this.amount,
    required this.categoryOrSourceName,
    this.description,
    required this.date,
    required this.isIncome,
    required this.transactionType,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Filter States
  String _searchQuery = '';
  String _selectedType = 'All'; // All, Income, Expense, Personal, Business
  String? _selectedCategoryOrSource;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isNewestFirst = true;
  int? _selectedMonth; // 1-12
  int? _selectedYear;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final timeFormat = DateFormat('hh:mm a');

    // 1. Build unified transaction list
    final List<UnifiedTransaction> allUnified = [];

    // Expenses
    for (var t in expenseProvider.allTransactions) {
      final category = expenseProvider.categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => Category(name: 'Unknown', type: t.type),
      );
      allUnified.add(UnifiedTransaction(
        id: 'expense_${t.id}',
        dbId: t.id,
        amount: t.amount,
        categoryOrSourceName: category.name,
        description: t.description,
        date: t.date,
        isIncome: false,
        transactionType: t.type,
      ));
    }

    // Income
    for (var entry in incomeProvider.allEntries) {
      final source = incomeProvider.allSources.firstWhere(
        (s) => s.id == entry.sourceId,
        orElse: () => IncomeSource(name: 'Unknown', type: entry.type),
      );
      allUnified.add(UnifiedTransaction(
        id: 'income_${entry.id}',
        dbId: entry.id,
        amount: entry.amount,
        categoryOrSourceName: source.name,
        description: entry.notes,
        date: entry.date,
        isIncome: true,
        transactionType: entry.type,
      ));
    }

    // 2. Apply Filtering
    List<UnifiedTransaction> filteredList = allUnified.where((t) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchesDesc = t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final matchesCat = t.categoryOrSourceName.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesDesc && !matchesCat) return false;
      }

      // Type filter
      if (_selectedType == 'Income' && !t.isIncome) return false;
      if (_selectedType == 'Expense' && t.isIncome) return false;
      if (_selectedType == 'Personal' && t.transactionType != TransactionType.personal) return false;
      if (_selectedType == 'Business' && t.transactionType != TransactionType.business) return false;

      // Category/Source filter
      if (_selectedCategoryOrSource != null && t.categoryOrSourceName != _selectedCategoryOrSource) {
        return false;
      }

      // Date Range filter
      if (_startDate != null && t.date.isBefore(_startDate!)) return false;
      if (_endDate != null && t.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

      // Month filter
      if (_selectedMonth != null && t.date.month != _selectedMonth) return false;

      // Year filter
      if (_selectedYear != null && t.date.year != _selectedYear) return false;

      return true;
    }).toList();

    // 3. Apply Sorting
    filteredList.sort((a, b) {
      return _isNewestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
    });

    // 4. Group Month-wise
    // We group by "Month Year" string key to preserve order
    final Map<String, List<UnifiedTransaction>> groupedTransactions = {};
    for (var t in filteredList) {
      final key = DateFormat('MMMM yyyy').format(t.date);
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      groupedTransactions[key]!.add(t);
    }

    // Collect all categories and sources for the category filter dropdown
    final allCategoryNames = {
      ...expenseProvider.categories.map((c) => c.name),
      ...incomeProvider.allSources.map((s) => s.name)
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportToCSV(filteredList),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search description, category...',
                    leading: const Icon(Icons.search),
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceVariant.withAlpha((0.3 * 255).toInt()),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterBottomSheet(context, allCategoryNames),
                  tooltip: 'More Filters',
                ),
              ],
            ),
          ),

          // Quick Filter Chips (Horizontal)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: ['All', 'Income', 'Expense', 'Personal', 'Business'].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(type),
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                );
              }).toList(),
            ),
          ),

          // Main timeline list
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions found',
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedTransactions.keys.length,
                    itemBuilder: (context, index) {
                      final monthKey = groupedTransactions.keys.elementAt(index);
                      final monthItems = groupedTransactions[monthKey]!;

                      // Calculate Month Totals
                      double monthIncome = 0;
                      double monthExpense = 0;
                      for (var item in monthItems) {
                        if (item.isIncome) {
                          monthIncome += item.amount;
                        } else {
                          monthExpense += item.amount;
                        }
                      }
                      double netPosition = monthIncome - monthExpense;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Monthly Header & Summary (GPay style)
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withAlpha((0.25 * 255).toInt()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  monthKey,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Income: ₹${monthIncome.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Expense: ₹${monthExpense.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Net: ${netPosition >= 0 ? "+" : ""}₹${netPosition.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: netPosition >= 0 ? Colors.green : Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Transactions list for this month
                          ...monthItems.map((item) {
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant.withAlpha((0.5 * 255).toInt()),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: item.isIncome
                                      ? Colors.green.withAlpha((0.15 * 255).toInt())
                                      : Colors.redAccent.withAlpha((0.15 * 255).toInt()),
                                  child: Icon(
                                    item.isIncome ? Icons.trending_up : Icons.trending_down,
                                    color: item.isIncome ? Colors.green : Colors.redAccent,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.categoryOrSourceName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.isIncome ? "+" : "-"}₹${item.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: item.isIncome ? Colors.green : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Personal/Business badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.transactionType == TransactionType.personal
                                                ? Colors.blue.withAlpha((0.1 * 255).toInt())
                                                : Colors.orange.withAlpha((0.1 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.transactionType == TransactionType.personal ? 'Personal' : 'Business',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: item.transactionType == TransactionType.personal
                                                  ? Colors.blue
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${DateFormat('dd MMM').format(item.date)} • ${timeFormat.format(item.date)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    if (item.description != null && item.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!,
                                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () async {
                                    final confirm = await showDeleteConfirmationDialog(
                                      context: context,
                                      title: 'Delete Transaction?',
                                      content: 'Are you sure you want to permanently delete this transaction? This action cannot be undone.',
                                    );
                                    if (confirm) {
                                      if (item.isIncome) {
                                        await incomeProvider.deleteEntry(item.dbId!);
                                      } else {
                                        await expenseProvider.deleteTransaction(item.dbId!);
                                      }
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, List<String> categoriesAndSources) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedCategoryOrSource = null;
                        _startDate = null;
                        _endDate = null;
                        _selectedMonth = null;
                        _selectedYear = null;
                        _isNewestFirst = true;
                      });
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Category/Source Filter
              const Text('Category / Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedCategoryOrSource,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories/Sources')),
                  ...categoriesAndSources.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (val) => setModalState(() => _selectedCategoryOrSource = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              // Sort Order
              const Text('Sort Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Newest First')),
                  ButtonSegment(value: false, label: Text('Oldest First')),
                ],
                selected: {_isNewestFirst},
                onSelectionChanged: (val) => setModalState(() => _isNewestFirst = val.first),
              ),
              const SizedBox(height: 16),

              // Month & Year Filter
              const Text('Month & Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedMonth,
                      hint: const Text('Month'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM').format(DateTime(2026, i + 1))))),
                      ],
                      onChanged: (val) => setModalState(() => _selectedMonth = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedYear,
                      hint: const Text('Year'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...[2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))),
                      ],
                      onChanged: (val) => setModalState(() => _selectedYear = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Range Picker
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range, size: 16),
                      label: Text(_startDate == null ? 'Start Date' : DateFormat('dd/MM/yy').format(_startDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range, size: 16),
                      label: Text(_endDate == null ? 'End Date' : DateFormat('dd/MM/yy').format(_endDate!)),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToCSV(List<UnifiedTransaction> transactions) async {
    List<List<dynamic>> rows = [];
    rows.add(["Date", "Type", "Category/Source", "Amount", "Description", "Transaction Mode"]);

    for (var t in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(t.date),
        t.isIncome ? "Income" : "Expense",
        t.categoryOrSourceName,
        t.amount,
        t.description ?? "",
        t.transactionType == TransactionType.personal ? "Personal" : "Business"
      ]);
    }

    String csvString = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/finance_history_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'My Expense Tracker Transaction History',
      subject: 'Transaction History Export',
    );
  }
}
