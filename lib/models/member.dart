class Member {
  final String id;
  final String name;
  final String phone;
  final int colorValue;
  final bool isActive;
  final DateTime joinedAt;

  Member({
    required this.id,
    required this.name,
    this.phone = '',
    required this.colorValue,
    this.isActive = true,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Member copyWith({
    String? id,
    String? name,
    String? phone,
    int? colorValue,
    bool? isActive,
    DateTime? joinedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'colorValue': colorValue,
      'isActive': isActive,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF1B5E20,
      isActive: map['isActive'] ?? true,
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'])
          : DateTime.now(),
    );
  }
}

