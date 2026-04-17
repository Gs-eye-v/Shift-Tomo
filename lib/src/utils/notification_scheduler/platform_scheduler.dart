import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'scheduler_stub.dart'
    if (dart.library.io) 'scheduler_native.dart';

abstract class PlatformNotificationScheduler {
  static Future<void> scheduleZoned({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
  }) async {
    // 実際の呼び出しはプラットフォーム別の実装に委譲
    await scheduleZonedImplementation(
      plugin: plugin,
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
    );
  }
}
