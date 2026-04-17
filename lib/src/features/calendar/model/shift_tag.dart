import 'package:flutter/material.dart';
import 'dart:convert';

class ShiftTagReminder {
  final int daysBefore; // 0=当日, 1=1日前...
  final String time;    // "HH:mm"

  const ShiftTagReminder({
    required this.daysBefore,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'days_before': daysBefore,
      'time': time,
    };
  }

  factory ShiftTagReminder.fromMap(Map<String, dynamic> map) {
    return ShiftTagReminder(
      daysBefore: map['days_before'] as int,
      time: map['time'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftTagReminder &&
          runtimeType == other.runtimeType &&
          daysBefore == other.daysBefore &&
          time == other.time;

  @override
  int get hashCode => daysBefore.hashCode ^ time.hashCode;
}

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
  final bool isNotificationEnabled; // 通知有効フラグ
  final List<ShiftTagReminder> reminders; // 通知スケジュール

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
    this.isNotificationEnabled = false,
    this.reminders = const [],
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
    bool? isNotificationEnabled,
    List<ShiftTagReminder>? reminders,
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
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      reminders: reminders ?? this.reminders,
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
          isDayOff == other.isDayOff &&
          isNotificationEnabled == other.isNotificationEnabled &&
          _listEquals(reminders, other.reminders);

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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
      isDayOff.hashCode ^
      isNotificationEnabled.hashCode ^
      reminders.hashCode;

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
      'is_notification_enabled': isNotificationEnabled ? 1 : 0,
      'reminders': jsonEncode(reminders.map((r) => r.toMap()).toList()),
    };
  }

  factory ShiftTag.fromMap(Map<String, dynamic> map) {
    List<ShiftTagReminder> decodedReminders = [];
    final remindersRaw = map['reminders'];
    if (remindersRaw != null && remindersRaw is String && remindersRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(remindersRaw) as List;
        decodedReminders = decoded.map((r) => ShiftTagReminder.fromMap(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Failed to decode reminders: $e');
      }
    }

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
      isNotificationEnabled: (map['is_notification_enabled'] as int? ?? 0) == 1,
      reminders: decodedReminders,
    );
  }
}
