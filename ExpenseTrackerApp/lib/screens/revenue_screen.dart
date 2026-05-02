import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/income_provider.dart';
import '../models/income.dart';
import '../models/category.dart';

class RevenueScreen extends StatelessWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncomeProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Revenue & Sales'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Manage Sources'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // History Tab
            _buildHistoryTab(context, provider, currencyFormat, dateFormat),
            // Sources Tab
            _buildSourcesTab(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, IncomeProvider provider, NumberFormat currencyFormat, DateFormat dateFormat) {
    final entries = provider.allEntries;
    if (entries.isEmpty) {
      return const Center(child: Text('No income records found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final source = provider.allSources.firstWhere(
          (s) => s.id == entry.sourceId, 
          orElse: () => IncomeSource(name: 'Unknown', type: entry.type)
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha((0.5 * 255).toInt())),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Row(
              children: [
                Text(source.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.type == TransactionType.personal ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.type == TransactionType.personal ? 'PERS' : 'BIZ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: entry.type == TransactionType.personal ? Colors.blue : Colors.orange),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(entry.date), style: const TextStyle(fontSize: 12)),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(entry.notes!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormat.format(entry.amount), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDeleteEntry(context, provider, entry),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourcesTab(BuildContext context, IncomeProvider provider) {
    final sources = provider.allSources;
    return Scaffold(
      body: sources.isEmpty 
          ? const Center(child: Text('No sources defined yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor.withAlpha((0.3 * 255).toInt())),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: source.type == TransactionType.personal ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                      child: Icon(source.type == TransactionType.personal ? Icons.person : Icons.business, size: 20, color: source.type == TransactionType.personal ? Colors.blue : Colors.orange),
                    ),
                    title: Text(source.name),
                    subtitle: Text(source.type == TransactionType.personal ? 'Personal Source' : 'Business Source'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showSourceDialog(context, provider, source),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSourceDialog(context, provider, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSourceDialog(BuildContext context, IncomeProvider provider, IncomeSource? source) {
    final nameController = TextEditingController(text: source?.name);
    TransactionType selectedType = source?.type ?? TransactionType.personal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(source == null ? 'Add Income Source' : 'Edit Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Source Name*', hintText: 'e.g. Freelance Work'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text('Source Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.personal, label: Text('Personal'), icon: Icon(Icons.person)),
                  ButtonSegment(value: TransactionType.business, label: Text('Business'), icon: Icon(Icons.business_center)),
                ],
                selected: {selectedType},
                onSelectionChanged: (val) => setDialogState(() => selectedType = val.first),
              ),
            ],
          ),
          actions: [
            if (source != null)
              TextButton(
                onPressed: () {
                  provider.deleteSource(source.id!);
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  // Check for duplicates
                  if (source == null && provider.allSources.any((s) => s.name.toLowerCase() == nameController.text.toLowerCase() && s.type == selectedType)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source already exists')));
                    return;
                  }

                  final newSource = IncomeSource(
                    id: source?.id,
                    name: nameController.text,
                    type: selectedType,
                  );

                  if (source == null) {
                    provider.addSource(newSource);
                  } else {
                    provider.updateSource(newSource);
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

  void _confirmDeleteEntry(BuildContext context, IncomeProvider provider, IncomeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this income entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
