import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../features/calendar/model/shift.dart';
import '../features/calendar/model/shift_tag.dart';
import '../features/calendar/model/app_settings.dart';
import 'notification_scheduler/platform_scheduler.dart'; // 追加

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 保存の最適化用
  String? _lastFingerprint;

  Future<void> init() async {
    if (kIsWeb) return;

    // Timezoneの初期化
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // 通知タップ時の処理（必要に応じて）
      },
    );
  }

  /// 指定期間内の全シフトの通知を同期する
  Future<void> syncAllNotifications({
    required Map<DateTime, List<Shift>> myShifts,
    required List<ShiftTag> tags,
    required AppSettings appSettings,
    Map<String, Map<DateTime, List<Shift>>>? partnerShifts,
    int daysAhead = 30,
    bool force = false,
  }) async {
    if (kIsWeb) return;

    // 指紋（fingerprint）の生成
    final fingerprint = _generateFingerprint(myShifts, tags, partnerShifts, appSettings);
    if (!force && fingerprint == _lastFingerprint) {
      debugPrint('Notification sync skipped: No changes detected.');
      return;
    }
    _lastFingerprint = fingerprint;

    // 一旦全ての通知をキャンセル
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    final end = now.add(Duration(days: daysAhead));

    int notificationId = 0;

    // 自分のシフトの通知予約
    if (appSettings.notifyMyShifts) {
      for (final entry in myShifts.entries) {
        final date = entry.key;
        if (date.isBefore(DateTime(now.year, now.month, now.day)) || date.isAfter(end)) continue;

        for (final shift in entry.value) {
          for (final tagId in shift.tagIds) {
            final tag = tags.where((t) => t.id == tagId).firstOrNull;
            if (tag == null) continue;
            
            // 個別タグで通知が無効ならスキップ
            if (!tag.isNotificationEnabled) continue;

            // リマインダーリストが空ならデフォルトを使用
            final reminders = tag.reminders.isNotEmpty ? tag.reminders : appSettings.defaultReminders;

            for (final reminder in reminders) {
              await _scheduleNotification(
                id: notificationId++,
                title: '今日のシフト: ${tag.title}',
                body: '${tag.startTime ?? ''} から勤務開始です',
                shiftDate: date,
                reminder: reminder,
              );
            }
          }
        }
      }
    }

    // パートナーのシフトの通知予約（任意）
    if (appSettings.notifyPartnerShifts && partnerShifts != null) {
      for (final partnerEntry in partnerShifts.entries) {
        final partnerName = partnerEntry.key;
        for (final shiftEntry in partnerEntry.value.entries) {
          final date = shiftEntry.key;
          if (date.isBefore(DateTime(now.year, now.month, now.day)) || date.isAfter(end)) continue;

          for (final shift in shiftEntry.value) {
            for (final tagId in shift.tagIds) {
              final tag = tags.where((t) => t.id == tagId).firstOrNull;
              if (tag == null) continue;
              
              // 個別タグで通知が無効ならスキップ
              if (!tag.isNotificationEnabled) continue;

              final reminders = tag.reminders.isNotEmpty ? tag.reminders : appSettings.defaultReminders;

              for (final reminder in reminders) {
                await _scheduleNotification(
                  id: notificationId++,
                  title: '【共有】$partnerName さんのシフト',
                  body: '${tag.title} (${tag.startTime ?? ''} 〜)',
                  shiftDate: date,
                  reminder: reminder,
                );
              }
            }
          }
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime shiftDate,
    required ShiftTagReminder reminder,
  }) async {
    final timeParts = reminder.time.split(':');
    if (timeParts.length != 2) return;

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 通知日時を計算
    final scheduledDate = DateTime(
      shiftDate.year,
      shiftDate.month,
      shiftDate.day,
      hour,
      minute,
    ).subtract(Duration(days: reminder.daysBefore));

    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // プラットフォーム固有のスケジューラーに委譲
    await PlatformNotificationScheduler.scheduleZoned(
      plugin: _notificationsPlugin,
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminders',
          'シフト通知',
          channelDescription: 'シフトの開始前通知を行います',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  String _generateFingerprint(
    Map<DateTime, List<Shift>> myShifts,
    List<ShiftTag> tags,
    Map<String, Map<DateTime, List<Shift>>>? partnerShifts,
    AppSettings appSettings, // 追加
  ) {
    // 通知に関係する部分のみを抽出して文字列化
    final sb = StringBuffer();
    
    // 全体設定
    sb.write('${appSettings.notifyMyShifts}:${appSettings.notifyPartnerShifts}:');
    for (final r in appSettings.defaultReminders) {
      sb.write('${r.daysBefore}${r.time}');
    }

    // タグの通知設定
    for (final tag in tags) {
      sb.write('${tag.id}:${tag.isNotificationEnabled}:');
      for (final r in tag.reminders) {
        sb.write('${r.daysBefore}${r.time}');
      }
    }

    // シフトの日付とタグIDの組み合わせ
    myShifts.entries.forEach((e) {
      sb.write(e.key.toIso8601String());
      for (final s in e.value) {
        sb.write(s.tagIds.join(','));
      }
    });

    if (partnerShifts != null) {
      partnerShifts.entries.forEach((pe) {
        sb.write(pe.key);
        pe.value.entries.forEach((e) {
          sb.write(e.key.toIso8601String());
          for (final s in e.value) {
            sb.write(s.tagIds.join(','));
          }
        });
      });
    }

    return sb.toString();
  }
}
