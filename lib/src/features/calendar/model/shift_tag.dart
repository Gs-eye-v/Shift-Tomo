import 'package:flutter/material.dart';

class ShiftTag {
  final String id;
  final String title;
  final String watermarkChar;
  final String emoji;
  final Color color;
  
  final String? startTime;     // "09:00" 形式
  final String? endTime;       // "18:00" 形式
  final int breakMinutes;      // 休憩時間 (分)
  final int? hourlyWage;       // 時給
  final bool isDayOff;         // 休日フラグ

  const ShiftTag({
    required this.id,
    required this.title,
    required this.watermarkChar,
    required this.emoji,
    required this.color,
    this.startTime,
    this.endTime,
    this.breakMinutes = 60,
    this.hourlyWage,
    this.isDayOff = false,
  });

  ShiftTag copyWith({
    String? id,
    String? title,
    String? watermarkChar,
    String? emoji,
    Color? color,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    int? hourlyWage,
    bool? isDayOff,
  }) {
    return ShiftTag(
      id: id ?? this.id,
      title: title ?? this.title,
      watermarkChar: watermarkChar ?? this.watermarkChar,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      isDayOff: isDayOff ?? this.isDayOff,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftTag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          watermarkChar == other.watermarkChar &&
          emoji == other.emoji &&
          color.value == other.color.value &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          breakMinutes == other.breakMinutes &&
          hourlyWage == other.hourlyWage &&
          isDayOff == other.isDayOff;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      watermarkChar.hashCode ^
      emoji.hashCode ^
      color.value.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      breakMinutes.hashCode ^
      hourlyWage.hashCode ^
      isDayOff.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'watermark_char': watermarkChar,
      'emoji': emoji,
      'color_code': color.value,
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
      'hourly_wage': hourlyWage,
      'is_day_off': isDayOff ? 1 : 0,
    };
  }

  factory ShiftTag.fromMap(Map<String, dynamic> map) {
    return ShiftTag(
      id: map['id'] as String,
      title: map['title'] as String,
      watermarkChar: map['watermark_char'] as String,
      emoji: map['emoji'] as String,
      color: Color(map['color_code'] as int),
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      breakMinutes: map['break_minutes'] as int? ?? 60,
      hourlyWage: map['hourly_wage'] as int?,
      isDayOff: (map['is_day_off'] as int? ?? 0) == 1,
    );
  }
}
