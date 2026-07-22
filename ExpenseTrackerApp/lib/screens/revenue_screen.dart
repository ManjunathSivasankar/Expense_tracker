import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/income_provider.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../widgets/delete_confirmation_dialog.dart';

class RevenueScreen extends StatelessWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncomeProvider>(context);

    final sources = provider.allSources;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sources', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: sources.isEmpty
          ? const Center(
              child: Text(
                'No sources defined yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Theme.of(context).dividerColor.withAlpha((0.3 * 255).toInt())),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: source.type == TransactionType.personal
                          ? Colors.blue.withAlpha((0.15 * 255).toInt())
                          : Colors.orange.withAlpha((0.15 * 255).toInt()),
                      child: Icon(
                        source.type == TransactionType.personal ? Icons.person : Icons.business_center,
                        color: source.type == TransactionType.personal ? Colors.blue : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(source.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(source.type == TransactionType.personal ? 'Personal Source' : 'Business Source'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showSourceDialog(context, provider, source),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSourceDialog(context, provider, null),
        label: const Text('Add Source'),
        icon: const Icon(Icons.add),
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
          title: Text(source == null ? 'Add Income Source' : 'Edit Source', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Source Name*', hintText: 'e.g. Freelance Work'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text('Source Type', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                onPressed: () async {
                  final confirm = await showDeleteConfirmationDialog(
                    context: context,
                    title: 'Delete Source?',
                    content: 'Are you sure you want to permanently delete this income source? This action cannot be undone.',
                  );
                  if (confirm) {
                    await provider.deleteSource(source.id!);
                    if (context.mounted) {
                      Navigator.pop(context); // Close the dialog
                    }
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  // Check for duplicates
                  if (source == null &&
                      provider.allSources.any((s) =>
                          s.name.toLowerCase() == nameController.text.toLowerCase() && s.type == selectedType)) {
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
}
