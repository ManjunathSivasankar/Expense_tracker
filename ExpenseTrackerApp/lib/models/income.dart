import 'category.dart';

class IncomeSource {
  final int? id;
  final String name;
  final TransactionType type;

  IncomeSource({
    this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'],
      name: map['name'],
      type: TransactionType.values[map['type']],
    );
  }
}

class IncomeEntry {
  final int? id;
  final int sourceId;
  final double amount;
  final DateTime date;
  final String? notes;
  final int? quantity;
  final String? customerName;
  final TransactionType type;

  IncomeEntry({
    this.id,
    required this.sourceId,
    required this.amount,
    required this.date,
    this.notes,
    this.quantity,
    this.customerName,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'quantity': quantity,
      'customerName': customerName,
      'type': type.index,
    };
  }

  factory IncomeEntry.fromMap(Map<String, dynamic> map) {
    return IncomeEntry(
      id: map['id'],
      sourceId: map['sourceId'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
      quantity: map['quantity'],
      customerName: map['customerName'],
      type: TransactionType.values[map['type']],
    );
  }
}
