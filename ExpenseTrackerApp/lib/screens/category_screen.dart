import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/delete_confirmation_dialog.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categories = expenseProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.category)),
              title: Text(category.name),
              subtitle: category.monthlyLimit != null 
                  ? Text('Limit: ₹${category.monthlyLimit}') 
                  : const Text('No limit set'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showCategoryDialog(context, expenseProvider, category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, expenseProvider, category),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, expenseProvider, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, ExpenseProvider provider, Category? category) {
    final nameController = TextEditingController(text: category?.name);
    final limitController = TextEditingController(text: category?.monthlyLimit?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Limit (Optional)', prefixText: '₹'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCategory = Category(
                  id: category?.id,
                  name: nameController.text,
                  type: provider.currentType,
                  monthlyLimit: limitController.text.isNotEmpty ? double.parse(limitController.text) : null,
                );

                if (category == null) {
                  provider.addCategory(newCategory);
                } else {
                  provider.updateCategory(newCategory);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseProvider provider, Category category) async {
    final confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Category?',
      content: 'Are you sure you want to delete "${category.name}"? All associated transactions will still exist but will be unlinked.',
    );
    if (confirm) {
      await provider.deleteCategory(category.id!);
    }
  }
}
