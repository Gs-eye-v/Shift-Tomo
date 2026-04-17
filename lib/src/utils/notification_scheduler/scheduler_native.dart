import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> scheduleZonedImplementation({
  required FlutterLocalNotificationsPlugin plugin,
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime scheduledDate,
  required NotificationDetails notificationDetails,
}) async {
  await plugin.zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
