enum TransactionType { personal, business }
enum AppMode { personal, business, income }

class Category {
  final int? id;
  final String name;
  final TransactionType type;
  final String? icon;
  final double? monthlyLimit;
  final int? parentId;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.monthlyLimit,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'icon': icon,
      'monthlyLimit': monthlyLimit,
      'parentId': parentId,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: TransactionType.values[map['type']],
      icon: map['icon'],
      monthlyLimit: map['monthlyLimit'],
      parentId: map['parentId'],
    );
  }
}
