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
                          onTap: () => _showEntryFormDialog(context, provider, record, record.type),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeSelectionDialog(context, provider),
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
    final amountController = TextEditingController(text: record?.amount.toString() == 'null' ? '' : record?.amount.toString());
    final notesController = TextEditingController(text: record?.notes);
    DateTime selectedDate = record?.date ?? DateTime.now();

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
                      record == null ? 'New ${type == BorrowLendType.borrowed ? "Borrow" : "Lend"}' : 'Edit Transaction',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(
                        type == BorrowLendType.borrowed ? "BORROW" : "LEND",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: type == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                          type: type,
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
                      backgroundColor: type == BorrowLendType.borrowed ? Colors.redAccent : Colors.green,
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
