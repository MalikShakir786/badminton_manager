class Member {
  final String id;
  final String name;
  final String phone;
  final int colorValue;
  final bool isActive;
  final DateTime joinedAt;
  final int skillLevel; // 1: Regular / Plays Less, 2: Good Player / Plays Well

  Member({
    required this.id,
    required this.name,
    this.phone = '',
    required this.colorValue,
    this.isActive = true,
    DateTime? joinedAt,
    this.skillLevel = 1,
  }) : joinedAt = joinedAt ?? DateTime.now();

  bool get isGoodPlayer => skillLevel >= 2;

  String get skillName => isGoodPlayer ? 'Good Player' : 'Regular Player';
  String get skillBadge => isGoodPlayer ? 'Good Player 🟢' : 'Regular 🟡';

  Member copyWith({
    String? id,
    String? name,
    String? phone,
    int? colorValue,
    bool? isActive,
    DateTime? joinedAt,
    int? skillLevel,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      skillLevel: skillLevel ?? this.skillLevel,
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
      'skillLevel': skillLevel,
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
      skillLevel: map['skillLevel'] ?? 1,
    );
  }
}
