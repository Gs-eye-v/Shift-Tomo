import 'package:flutter/material.dart';

class Shift {
  final String id;
  final String profileId;
  final List<String> tagIds;
  final DateTime date;
  final String title;
  final String watermarkChar;
  final String emoji;
  final Color color;
  final List<String> subTasks;
  final String? memo;

  const Shift({
    required this.id,
    required this.profileId,
    required this.tagIds,
    required this.date,
    this.title = '',
    this.watermarkChar = '',
    this.emoji = '',
    this.color = Colors.grey,
    this.subTasks = const [],
    this.memo,
  });

  bool get hasMemo => memo != null && memo!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'tag_id': tagIds.join(','),
      'date': date.toIso8601String(),
      'memo': memo,
      'sub_tasks': subTasks.join(','),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      tagIds: (map['tag_id'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      date: DateTime.parse(map['date'] as String),
      memo: map['memo'] as String?,
      subTasks: (map['sub_tasks'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
    );
  }
}
