import 'package:flutter/material.dart';

class Member {
  static const int skillPlayLess = 1;
  static const int skillPlayMedium = 2;
  static const int skillPlayGood = 3;

  final String id;
  final String name;
  final String phone;
  final int colorValue;
  final bool isActive;
  final DateTime joinedAt;
  final int skillLevel; // 1: Play Less, 2: Play Medium, 3: Play Good

  Member({
    required this.id,
    required this.name,
    this.phone = '',
    required this.colorValue,
    this.isActive = true,
    DateTime? joinedAt,
    this.skillLevel = skillPlayMedium,
  }) : joinedAt = joinedAt ?? DateTime.now();

  bool get isGoodPlayer => skillLevel == skillPlayGood;
  bool get isMediumPlayer => skillLevel == skillPlayMedium;
  bool get isLessPlayer => skillLevel <= skillPlayLess;

  String get skillName {
    switch (skillLevel) {
      case skillPlayGood:
        return 'Play Good';
      case skillPlayMedium:
        return 'Play Medium';
      case skillPlayLess:
      default:
        return 'Play Less';
    }
  }

  String get skillBadge {
    switch (skillLevel) {
      case skillPlayGood:
        return 'Play Good 🟢';
      case skillPlayMedium:
        return 'Play Medium 🔵';
      case skillPlayLess:
      default:
        return 'Play Less 🟡';
    }
  }

  Color get skillColor {
    switch (skillLevel) {
      case skillPlayGood:
        return const Color(0xFF2E7D32); // Green
      case skillPlayMedium:
        return const Color(0xFF1976D2); // Blue
      case skillPlayLess:
      default:
        return const Color(0xFFE65100); // Deep Orange / Amber
    }
  }

  Color get skillBgColor {
    switch (skillLevel) {
      case skillPlayGood:
        return const Color(0xFFE8F5E9); // Light Green
      case skillPlayMedium:
        return const Color(0xFFE3F2FD); // Light Blue
      case skillPlayLess:
      default:
        return const Color(0xFFFFF3E0); // Light Amber
    }
  }

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
      skillLevel: map['skillLevel'] ?? skillPlayMedium,
    );
  }
}
