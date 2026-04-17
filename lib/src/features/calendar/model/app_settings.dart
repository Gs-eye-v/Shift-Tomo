import '../model/shift_tag.dart';

class AppSettings {
  final bool useColorEmoji;
  final bool notifyMyShifts;
  final bool notifyPartnerShifts;
  final List<ShiftTagReminder> defaultReminders;

  const AppSettings({
    this.useColorEmoji = true,
    this.notifyMyShifts = true,
    this.notifyPartnerShifts = true,
    this.defaultReminders = const [
      ShiftTagReminder(daysBefore: 1, time: "21:00"),
    ],
  });

  AppSettings copyWith({
    bool? useColorEmoji,
    bool? notifyMyShifts,
    bool? notifyPartnerShifts,
    List<ShiftTagReminder>? defaultReminders,
  }) {
    return AppSettings(
      useColorEmoji: useColorEmoji ?? this.useColorEmoji,
      notifyMyShifts: notifyMyShifts ?? this.notifyMyShifts,
      notifyPartnerShifts: notifyPartnerShifts ?? this.notifyPartnerShifts,
      defaultReminders: defaultReminders ?? this.defaultReminders,
    );
  }
}
