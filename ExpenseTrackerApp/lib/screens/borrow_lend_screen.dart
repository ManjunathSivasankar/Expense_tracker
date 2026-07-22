import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/borrow_lend_provider.dart';
import '../models/borrow_lend.dart';
import '../widgets/delete_confirmation_dialog.dart';

class BorrowLendScreen extends StatelessWidget {
  const BorrowLendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BorrowLendProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    final activeRecords = provider.records.where((r) => !r.isCleared).toList();
    final settledRecords = provider.records.where((r) => r.isCleared).toList();

    // Summary calculations
    final double totalBorrowed = provider.totalBorrowed;
    final double totalGiven = provider.totalGiven;
    final double totalSettled = provider.records
        .where((r) => r.isCleared)
        .fold(0.0, (sum, r) => sum + r.amount);
    final double outstanding = totalGiven - totalBorrowed;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Borrow & Lend', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Premium Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer.withAlpha((0.2 * 255).toInt()),
                    Theme.of(context).colorScheme.secondaryContainer.withAlpha((0.1 * 255).toInt()),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha((0.3 * 255).toInt())),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(context, 'Borrowed', currencyFormat.format(totalBorrowed), Colors.redAccent),
                      Container(height: 32, width: 1, color: Theme.of(context).dividerColor),
                      _buildSummaryItem(context, 'Given', currencyFormat.format(totalGiven), Colors.green),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(context, 'Settled', currencyFormat.format(totalSettled), Colors.blue),
                      Container(height: 32, width: 1, color: Theme.of(context).dividerColor),
                      _buildSummaryItem(
                        context,
                        'Outstanding',
                        currencyFormat.format(outstanding.abs()),
                        outstanding >= 0 ? Colors.green : Colors.redAccent,
                        subtitle: outstanding >= 0 ? '(You receive)' : '(You owe)',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Active Tab
                  _buildList(context, provider, activeRecords, dateFormat, currencyFormat, isActiveTab: true),
                  // History Tab
                  _buildList(context, provider, settledRecords, dateFormat, currencyFormat, isActiveTab: false),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTypeSelectionDialog(context, provider),
          label: const Text('Add Record'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    BorrowLendProvider provider,
    List<BorrowLend> records,
    DateFormat dateFormat,
    NumberFormat currencyFormat, {
    required bool isActiveTab,
  }) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActiveTab ? Icons.assignment_outlined : Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              isActiveTab ? 'No active transactions' : 'No settlement history',
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha((0.4 * 255).toInt())),
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(record.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  currencyFormat.format(record.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: record.type == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: record.type == BorrowLendType.borrowed
                            ? Colors.redAccent.withAlpha((0.15 * 255).toInt())
                            : Colors.green.withAlpha((0.15 * 255).toInt()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.type == BorrowLendType.borrowed ? 'BORROWED' : 'LENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: record.type == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(record.date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(record.notes!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActiveTab) ...[
                  Checkbox(
                    value: record.isCleared,
                    onChanged: (val) {
                      provider.toggleCleared(record.id!, record.isCleared);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction with ${record.personName} settled!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                    onPressed: () => _showEntryFormDialog(context, provider, record, record.type),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Settled',
                      style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDeleteConfirmationDialog(
                      context: context,
                      title: 'Delete Record?',
                      content: 'Are you sure you want to permanently delete this Borrow/Lend record? This action cannot be undone.',
                    );
                    if (confirm) {
                      await provider.deleteRecord(record.id!);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String amount, Color color, {String? subtitle}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color.withAlpha((0.7 * 255).toInt()))),
        ],
      ],
    );
  }

  void _showTypeSelectionDialog(BuildContext context, BorrowLendProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Transaction Type', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeOption(
              context,
              'Borrow',
              'I borrowed money',
              Icons.call_received_rounded,
              Colors.redAccent,
              () {
                Navigator.pop(context);
                _showEntryFormDialog(context, provider, null, BorrowLendType.borrowed);
              },
            ),
            const SizedBox(height: 16),
            _buildTypeOption(
              context,
              'Lend',
              'I gave money',
              Icons.call_made_rounded,
              Colors.green,
              () {
                Navigator.pop(context);
                _showEntryFormDialog(context, provider, null, BorrowLendType.given);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  void _showEntryFormDialog(BuildContext context, BorrowLendProvider provider, BorrowLend? record, BorrowLendType type) {
    final nameController = TextEditingController(text: record?.personName);
    final amountController = TextEditingController(text: record?.amount == null ? '' : record?.amount.toString());
    final notesController = TextEditingController(text: record?.notes);
    DateTime selectedDate = record?.date ?? DateTime.now();
    BorrowLendType selectedType = type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record == null ? 'New Transaction' : 'Edit Transaction',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(
                        selectedType == BorrowLendType.borrowed ? "BORROW" : "LEND",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: selectedType == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Toggle Type
                const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                SegmentedButton<BorrowLendType>(
                  segments: const [
                    ButtonSegment(value: BorrowLendType.borrowed, label: Text('Borrow'), icon: Icon(Icons.call_received)),
                    ButtonSegment(value: BorrowLendType.given, label: Text('Lend'), icon: Icon(Icons.call_made)),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (val) {
                    setModalState(() {
                      selectedType = val.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Person Name*',
                    hintText: 'Who is it?',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount*',
                    prefixText: '₹ ',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes / Description*',
                    hintText: 'What was this for?',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text('Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}'),
                        const Spacer(),
                        const Icon(Icons.edit, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty &&
                          amountController.text.isNotEmpty &&
                          notesController.text.isNotEmpty) {
                        final newRecord = BorrowLend(
                          id: record?.id,
                          personName: nameController.text,
                          amount: double.parse(amountController.text),
                          type: selectedType,
                          date: selectedDate,
                          notes: notesController.text,
                          isCleared: record?.isCleared ?? false,
                        );

                        if (record == null) {
                          provider.addRecord(newRecord);
                        } else {
                          provider.updateRecord(newRecord);
                        }
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all mandatory fields (*)')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
