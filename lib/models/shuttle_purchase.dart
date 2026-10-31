class ShuttlePurchase {
  final String id;
  final String title;
  final int quantity; // Number of shuttles bought
  final double totalCost; // Total price paid (e.g. 700)
  final DateTime date;
  final String notes;

  ShuttlePurchase({
    required this.id,
    required this.title,
    required this.quantity,
    required this.totalCost,
    DateTime? date,
    this.notes = '',
  }) : date = date ?? DateTime.now();

  double get costPerUnit => quantity > 0 ? totalCost / quantity : totalCost;

  ShuttlePurchase copyWith({
    String? id,
    String? title,
    int? quantity,
    double? totalCost,
    DateTime? date,
    String? notes,
  }) {
    return ShuttlePurchase(
      id: id ?? this.id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      totalCost: totalCost ?? this.totalCost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'quantity': quantity,
      'totalCost': totalCost,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory ShuttlePurchase.fromMap(Map<String, dynamic> map) {
    return ShuttlePurchase(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Shuttles',
      quantity: map['quantity'] ?? 1,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}

