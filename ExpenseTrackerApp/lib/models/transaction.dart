import 'category.dart';

class Transaction {
  final int? id;
  final double amount;
  final int categoryId;
  final String? description;
  final DateTime date;
  final TransactionType type;
  final bool isRecurring;

  Transaction({
    this.id,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.date,
    required this.type,
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'type': type.index,
      'isRecurring': isRecurring ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      type: TransactionType.values[map['type']],
      isRecurring: map['isRecurring'] == 1,
    );
  }
}
