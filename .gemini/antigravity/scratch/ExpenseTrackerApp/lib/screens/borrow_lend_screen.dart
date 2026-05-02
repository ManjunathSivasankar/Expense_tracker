import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/borrow_lend_provider.dart';
import '../models/borrow_lend.dart';

class BorrowLendScreen extends StatelessWidget {
  const BorrowLendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BorrowLendProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lend'),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                _buildSummaryItem('Borrowed', currencyFormat.format(provider.totalBorrowed), Colors.redAccent),
                const VerticalDivider(width: 32),
                _buildSummaryItem('Given', currencyFormat.format(provider.totalGiven), Colors.green),
              ],
            ),
          ),

          Expanded(
            child: provider.records.isEmpty
                ? const Center(child: Text('No records yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(record.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(record.date)),
                              if (record.notes != null && record.notes!.isNotEmpty)
                                Text(record.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormat.format(record.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: record.type == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Checkbox(
                                value: record.isCleared,
                                onChanged: (val) => provider.toggleCleared(record.id!, record.isCleared),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => provider.deleteRecord(record.id!),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          onTap: () => _showAddEditDialog(context, provider, record),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, provider, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, BorrowLendProvider provider, BorrowLend? record) {
    final nameController = TextEditingController(text: record?.personName);
    final amountController = TextEditingController(text: record?.amount.toString());
    final notesController = TextEditingController(text: record?.notes);
    BorrowLendType selectedType = record?.type ?? BorrowLendType.borrowed;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(record == null ? 'Add Record' : 'Edit Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<BorrowLendType>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: BorrowLendType.borrowed, child: Text('Borrowed From')),
                    DropdownMenuItem(value: BorrowLendType.given, child: Text('Given To')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Person Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final newRecord = BorrowLend(
                    id: record?.id,
                    personName: nameController.text,
                    amount: double.parse(amountController.text),
                    type: selectedType,
                    date: record?.date ?? DateTime.now(),
                    notes: notesController.text,
                    isCleared: record?.isCleared ?? false,
                  );

                  if (record == null) {
                    provider.addRecord(newRecord);
                  } else {
                    provider.updateRecord(newRecord);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
