import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../models/transaction.dart' as model;
import 'history_screen.dart';
import 'borrow_lend_screen.dart';
import 'category_screen.dart';
import 'revenue_screen.dart';
import 'backup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppMode _currentMode = AppMode.personal;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen())),
            tooltip: 'Revenue & Sales',
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BorrowLendScreen())),
            tooltip: 'Borrow & Lend',
          ),
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
            tooltip: 'Backup & Restore',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Unified Toggle Control (At the top as requested)
            Center(
              child: SegmentedButton<AppMode>(
                segments: const [
                  ButtonSegment(value: AppMode.personal, label: Text('Personal'), icon: Icon(Icons.person)),
                  ButtonSegment(value: AppMode.business, label: Text('Business'), icon: Icon(Icons.business_center)),
                  ButtonSegment(value: AppMode.income, label: Text('Income'), icon: Icon(Icons.account_balance_wallet)),
                ],
                selected: {_currentMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _currentMode = newSelection.first;
                    if (_currentMode == AppMode.personal) {
                      expenseProvider.updateType(TransactionType.personal);
                      incomeProvider.updateType(TransactionType.personal);
                    } else if (_currentMode == AppMode.business) {
                      expenseProvider.updateType(TransactionType.business);
                      incomeProvider.updateType(TransactionType.business);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. Top Dashboard: Today & Monthly Expenditure
            _buildTopDashboard(context, expenseProvider, incomeProvider, currencyFormat),
            const SizedBox(height: 32),

            // Content based on Mode
            if (_currentMode == AppMode.income)
              _buildIncomeModule(context, incomeProvider, currencyFormat)
            else
              _buildExpenseModule(context, expenseProvider, incomeProvider, currencyFormat),

            const SizedBox(height: 40),

            // Combined Financial Summary (Bottom)
            _buildCombinedSummary(context, expenseProvider, incomeProvider, currencyFormat),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, expenseProvider, incomeProvider),
    );
  }

  Widget _buildTopDashboard(BuildContext context, ExpenseProvider expenseProvider, IncomeProvider incomeProvider, NumberFormat currencyFormat) {
    // Determine if we show Expenditure or Income metrics based on mode
    // However, the user specifically asked for "Expenditure" in the top dashboard
    final bool isIncomeMode = _currentMode == AppMode.income;
    
    final String todayLabel = isIncomeMode ? 'Today Income' : 'Today Expenditure';
    final String monthlyLabel = isIncomeMode ? 'Monthly Income' : 'Monthly Expenditure';
    
    final String todayValue = isIncomeMode 
        ? currencyFormat.format(incomeProvider.todayIncome)
        : currencyFormat.format(expenseProvider.todaySpending);
        
    final String monthlyValue = isIncomeMode
        ? currencyFormat.format(incomeProvider.monthlyIncome)
        : currencyFormat.format(expenseProvider.monthlySpending);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).toInt()),
            Theme.of(context).colorScheme.tertiary.withAlpha((0.05 * 255).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt())),
      ),
      child: Row(
        children: [
          _buildTopMetricCard(
            context,
            todayLabel,
            todayValue,
            isIncomeMode ? Icons.trending_up : Icons.today_outlined,
            isIncomeMode ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildTopMetricCard(
            context,
            monthlyLabel,
            monthlyValue,
            Icons.calendar_month_outlined,
            isIncomeMode ? Colors.blue : Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseModule(BuildContext context, ExpenseProvider expenseProvider, IncomeProvider incomeProvider, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Quick Entry
        const Text('Quick Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: expenseProvider.categories.length,
            itemBuilder: (context, index) {
              final category = expenseProvider.categories[index];
              return _buildQuickEntryItem(context, category, expenseProvider);
            },
          ),
        ),
        const SizedBox(height: 32),

        // 2. Category List & Limits
        Text(
          _currentMode == AppMode.personal ? 'Personal Expenses' : 'Business Expenses', 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 12),
        _buildCategoryLimits(context, expenseProvider),
        const SizedBox(height: 32),

        // 4. Monthly Insights & 5. Charts
        const Text('Monthly Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildExpenseInsights(context, expenseProvider, currencyFormat),
      ],
    );
  }

  Widget _buildIncomeModule(BuildContext context, IncomeProvider provider, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Income Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Totals Cards
        Row(
          children: [
            _buildSummaryCard(context, 'Personal Income', currencyFormat.format(provider.personalMonthlyIncome), Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            _buildSummaryCard(context, 'Business Income', currencyFormat.format(provider.businessMonthlyIncome), Theme.of(context).colorScheme.secondaryContainer, Theme.of(context).colorScheme.onSecondaryContainer),
          ],
        ),
        const SizedBox(height: 24),

        // Daily/Weekly/Monthly Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withAlpha((0.3 * 255).toInt()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInsightRow('Total Today', currencyFormat.format(provider.personalTodayIncome + provider.businessTodayIncome)),
              _buildInsightRow('Total Weekly', currencyFormat.format(provider.personalWeeklyIncome + provider.businessWeeklyIncome)),
              _buildInsightRow('Total Monthly', currencyFormat.format(provider.personalMonthlyIncome + provider.businessMonthlyIncome)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Source-wise breakdown
        const Text('Source-wise Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildIncomeSourceBreakdown(context, provider),
      ],
    );
  }

  Widget _buildCombinedSummary(BuildContext context, ExpenseProvider expenseProvider, IncomeProvider incomeProvider, NumberFormat currencyFormat) {
    final personalExp = expenseProvider.personalMonthlySpending;
    final businessExp = expenseProvider.businessMonthlySpending;
    final personalInc = incomeProvider.personalMonthlyIncome;
    final businessInc = incomeProvider.businessMonthlyIncome;
    final totalExp = personalExp + businessExp;
    final totalInc = personalInc + businessInc;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()), Theme.of(context).colorScheme.secondary.withAlpha((0.1 * 255).toInt())],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Combined Financial Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryRow('Personal Expenses', currencyFormat.format(personalExp), Colors.redAccent),
          _buildSummaryRow('Business Expenses', currencyFormat.format(businessExp), Colors.redAccent),
          _buildSummaryRow('Personal Income', currencyFormat.format(personalInc), Colors.green),
          _buildSummaryRow('Business Income', currencyFormat.format(businessInc), Colors.green),
          const Divider(height: 24),
          _buildSummaryRow('Overall Total Income', currencyFormat.format(totalInc), Colors.green, isBold: true),
          _buildSummaryRow('Overall Total Expenditure', currencyFormat.format(totalExp), Colors.redAccent, isBold: true),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Net Position: ${currencyFormat.format(totalInc - totalExp)}',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: (totalInc - totalExp) >= 0 ? Colors.green : Colors.red
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryLimits(BuildContext context, ExpenseProvider provider) {
    final spending = provider.categorySpending;
    final categories = provider.categories.where((c) => (spending[c.name] ?? 0) > 0).toList();

    if (categories.isEmpty) {
      return const Text('No transactions recorded for this month.', style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    return Column(
      children: categories.map((category) {
        final spent = spending[category.name] ?? 0;
        final hasLimit = category.monthlyLimit != null && category.monthlyLimit! > 0;
        final limit = category.monthlyLimit ?? 0;
        final percent = hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;
        final isExceeded = hasLimit && spent > limit;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                child: const Icon(Icons.category_outlined, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (hasLimit)
                          Text('₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}')
                        else
                          Text('₹${spent.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (hasLimit) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                color: isExceeded ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          if (isExceeded) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Limit Exceeded',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Unlimited',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpenseInsights(BuildContext context, ExpenseProvider expenseProvider, NumberFormat currencyFormat) {
    if (expenseProvider.categorySpending.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No transactions this month'),
      ));
    }

    return Column(
      children: [
        Center(
          child: SizedBox(
            height: 220,
            width: 220,
            child: PieChart(
              PieChartData(
                sections: expenseProvider.categorySpending.entries.map((entry) {
                  return PieChartSectionData(
                    color: Colors.primaries[expenseProvider.categorySpending.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                    value: entry.value,
                    title: '${(entry.value / expenseProvider.monthlySpending * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: expenseProvider.categorySpending.keys.map((name) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.primaries[expenseProvider.categorySpending.keys.toList().indexOf(name) % Colors.primaries.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(name, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIncomeSourceBreakdown(BuildContext context, IncomeProvider provider) {
    final sources = provider.sourceWiseIncome;
    if (sources.isEmpty) {
      return const Center(child: Text('No income data for this month', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: sources.entries.map((entry) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(entry.key),
            trailing: Text('₹${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String amount, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: textColor.withAlpha((0.8 * 255).toInt()), fontWeight: FontWeight.w500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(amount, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryItem(BuildContext context, Category category, ExpenseProvider provider) {
    return GestureDetector(
      onTap: () => _showQuickExpenseDialog(context, category, provider),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withAlpha((0.5 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withAlpha((0.1 * 255).toInt())),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.category_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(category.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, ExpenseProvider expenseProvider, IncomeProvider incomeProvider) {
    if (_currentMode == AppMode.income) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddIncomeDialog(context, incomeProvider),
        label: const Text('Add Income'),
        icon: const Icon(Icons.add),
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context, expenseProvider),
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      );
    }
  }

  void _showQuickExpenseDialog(BuildContext context, Category category, ExpenseProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Expense: ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addTransaction(model.Transaction(
                  amount: double.parse(controller.text),
                  categoryId: category.id!,
                  date: DateTime.now(),
                  type: provider.currentType,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, IncomeProvider provider) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    TransactionType selectedType = TransactionType.personal;
    IncomeSource? selectedSource = provider.allSources.isNotEmpty ? provider.allSources.first : null;

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Income', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Income Type Toggle
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.personal, label: Text('Personal'), icon: Icon(Icons.person)),
                    ButtonSegment(value: TransactionType.business, label: Text('Business'), icon: Icon(Icons.business_center)),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (val) {
                    setModalState(() {
                      selectedType = val.first;
                      final filteredSources = provider.allSources.where((s) => s.type == selectedType).toList();
                      selectedSource = filteredSources.isNotEmpty ? filteredSources.first : null;
                    });
                  },
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount*',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<IncomeSource>(
                  value: selectedSource,
                  items: provider.allSources
                      .where((s) => s.type == selectedType)
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedSource = val),
                  decoration: InputDecoration(
                    labelText: 'Source Name*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes / Description*',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (amountController.text.isNotEmpty && selectedSource != null && notesController.text.isNotEmpty) {
                        provider.addEntry(IncomeEntry(
                          sourceId: selectedSource!.id!,
                          amount: double.parse(amountController.text),
                          notes: notesController.text,
                          date: DateTime.now(),
                          type: selectedType,
                        ));
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All fields are mandatory')),
                        );
                      }
                    },
                    child: const Text('Save Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseProvider provider) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    Category? selectedCategory = provider.categories.isNotEmpty ? provider.categories.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              value: selectedCategory,
              items: provider.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => selectedCategory = val,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty && selectedCategory != null) {
                    provider.addTransaction(model.Transaction(
                      amount: double.parse(amountController.text),
                      categoryId: selectedCategory!.id!,
                      description: descController.text,
                      date: DateTime.now(),
                      type: provider.currentType,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
