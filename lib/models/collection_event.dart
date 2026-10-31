class CollectionEvent {
  final String id;
  final String title;
  final double amountPerMember;
  final String notes;
  final List<String> targetMemberIds;
  final DateTime createdAt;
  final String shuttleBrand;

  CollectionEvent({
    required this.id,
    required this.title,
    required this.amountPerMember,
    this.notes = '',
    required this.targetMemberIds,
    DateTime? createdAt,
    this.shuttleBrand = 'Ghafoor Gold',
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalTargetAmount => amountPerMember * targetMemberIds.length;

  CollectionEvent copyWith({
    String? id,
    String? title,
    double? amountPerMember,
    String? notes,
    List<String>? targetMemberIds,
    DateTime? createdAt,
    String? shuttleBrand,
  }) {
    return CollectionEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      amountPerMember: amountPerMember ?? this.amountPerMember,
      notes: notes ?? this.notes,
      targetMemberIds: targetMemberIds ?? this.targetMemberIds,
      createdAt: createdAt ?? this.createdAt,
      shuttleBrand: shuttleBrand ?? this.shuttleBrand,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amountPerMember': amountPerMember,
      'notes': notes,
      'targetMemberIds': targetMemberIds,
      'createdAt': createdAt.toIso8601String(),
      'shuttleBrand': shuttleBrand,
    };
  }

  factory CollectionEvent.fromMap(Map<String, dynamic> map) {
    return CollectionEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amountPerMember: (map['amountPerMember'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      targetMemberIds: List<String>.from(map['targetMemberIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      shuttleBrand: map['shuttleBrand'] ?? 'Yonex Mavis 350',
    );
  }
}

