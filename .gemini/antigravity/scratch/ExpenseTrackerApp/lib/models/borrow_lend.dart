enum BorrowLendType { borrowed, given }

class BorrowLend {
  final int? id;
  final String personName;
  final double amount;
  final BorrowLendType type;
  final DateTime date;
  final String? notes;
  final bool isCleared;

  BorrowLend({
    this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.isCleared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'type': type.index,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'isCleared': isCleared ? 1 : 0,
    };
  }

  factory BorrowLend.fromMap(Map<String, dynamic> map) {
    return BorrowLend(
      id: map['id'],
      personName: map['personName'],
      amount: map['amount'],
      type: BorrowLendType.values[map['type']],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
      isCleared: map['isCleared'] == 1,
    );
  }
}
