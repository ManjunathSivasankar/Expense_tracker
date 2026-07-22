import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/database_helper.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/borrow_lend_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isProcessing = false;

  Future<void> _backupDatabase() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database backup is not supported on Web.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final file = File(dbPath);

      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'My Expense Tracker Database Backup',
          subject: 'Expense Tracker Backup',
        );
      } else {
        throw Exception('Database file not found.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to backup: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _restoreDatabase() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database restore is not supported on Web.')),
      );
      return;
    }

    // Confirm action
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will overwrite all current transactions, income entries, and categories with the data in the backup file. This action cannot be undone.\n\nAre you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Overwrite & Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Android and iOS handle file extensions differently, using any to allow picking .db file
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        // Simple verification - file must end with .db or contain SQLite header
        if (!path.endsWith('.db') && !path.endsWith('.sqlite')) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          // SQLite database header check "SQLite format 3\0"
          if (bytes.length < 16 || String.fromCharCodes(bytes.sublist(0, 15)) != 'SQLite format 3') {
            throw Exception('Invalid database file format. Please select a valid database backup file.');
          }
        }

        await DatabaseHelper.instance.restoreDatabase(path);

        // Refresh all providers to reload the interface with new data
        if (mounted) {
          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
          final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
          final borrowLendProvider = Provider.of<BorrowLendProvider>(context, listen: false);

          await expenseProvider.fetchCategories();
          await expenseProvider.fetchTransactions();
          await incomeProvider.fetchSources();
          await incomeProvider.fetchEntries();
          await borrowLendProvider.fetchRecords();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database restored successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Information Card
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withAlpha((0.2 * 255).toInt()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: theme.colorScheme.primary, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protect Your Data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Uninstalling the app deletes all stored data. Save a backup file externally (e.g. Google Drive) to ensure you never lose it.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onPrimaryContainer.withAlpha((0.85 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Backup section
                  Text(
                    'Backup Options',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha((0.5 * 255).toInt())),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.backup_outlined, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Export Database Backup',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Creates a backup of your local database containing categories, expenses, incomes, and borrower records. Share it or save it in your Downloads folder/Google Drive.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Export Backup File', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _backupDatabase,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Restore section
                  Text(
                    'Restore Options',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha((0.5 * 255).toInt())),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restore_outlined, color: theme.colorScheme.error),
                              const SizedBox(width: 12),
                              const Text(
                                'Import & Restore',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a previously saved database file (.db) to restore your transaction history. Note that this replaces all current data on this device.',
                            style: TextStyle(color: theme.colorScheme.error.withAlpha((0.8 * 255).toInt()), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                            icon: const Icon(Icons.file_open_outlined),
                            label: const Text('Select Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _restoreDatabase,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
