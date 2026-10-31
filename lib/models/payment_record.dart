class PaymentRecord {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String paymentMethod; // "Cash", "UPI / Online", "Bank Transfer"
  final String notes;
  final String? collectionEventId;

  PaymentRecord({
    required this.id,
    required this.memberId,
    required this.amount,
    DateTime? date,
    this.paymentMethod = 'UPI / Online',
    this.notes = '',
    this.collectionEventId,
  }) : date = date ?? DateTime.now();

  PaymentRecord copyWith({
    String? id,
    String? memberId,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? collectionEventId,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      collectionEventId: collectionEventId ?? this.collectionEventId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'collectionEventId': collectionEventId,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] ?? '',
      memberId: map['memberId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'UPI / Online',
      notes: map['notes'] ?? '',
      collectionEventId: map['collectionEventId'],
    );
  }
}

