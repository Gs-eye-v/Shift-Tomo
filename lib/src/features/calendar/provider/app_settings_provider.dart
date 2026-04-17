import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // 追加
import '../model/app_settings.dart';
import '../model/shift_tag.dart'; // 追加

part 'app_settings_provider.g.dart';

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const _keyUseColorEmoji = 'use_color_emoji';
  static const _keyNotifyMyShifts = 'notify_my_shifts';
  static const _keyNotifyPartnerShifts = 'notify_partner_shifts';
  static const _keyDefaultReminders = 'default_reminders';

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useColorEmoji = prefs.getBool(_keyUseColorEmoji) ?? true;
    final notifyMyShifts = prefs.getBool(_keyNotifyMyShifts) ?? true;
    final notifyPartnerShifts = prefs.getBool(_keyNotifyPartnerShifts) ?? true;
    
    final remindersJson = prefs.getString(_keyDefaultReminders);
    List<ShiftTagReminder>? defaultReminders;
    if (remindersJson != null) {
      try {
        final List decoded = jsonDecode(remindersJson);
        defaultReminders = decoded.map((m) => ShiftTagReminder.fromMap(m as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    
    state = state.copyWith(
      useColorEmoji: useColorEmoji,
      notifyMyShifts: notifyMyShifts,
      notifyPartnerShifts: notifyPartnerShifts,
      defaultReminders: defaultReminders,
    );
  }

  Future<void> setUseColorEmoji(bool value) async {
    state = state.copyWith(useColorEmoji: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseColorEmoji, value);
  }

  Future<void> setNotifyMyShifts(bool value) async {
    state = state.copyWith(notifyMyShifts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyMyShifts, value);
  }

  Future<void> setNotifyPartnerShifts(bool value) async {
    state = state.copyWith(notifyPartnerShifts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyPartnerShifts, value);
  }

  Future<void> setDefaultReminders(List<ShiftTagReminder> reminders) async {
    state = state.copyWith(defaultReminders: reminders);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(reminders.map((r) => r.toMap()).toList());
    await prefs.setString(_keyDefaultReminders, json);
  }
}
