import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows FogShield alert pushes.
///
/// The backend (common/fcm.php) sends Android pushes as **data-only**: no
/// notification block, so Android shows nothing by itself — the app must.
/// The text is always in `data['title']` / `data['body']` (fcm.php adds
/// them to every message). iOS pushes carry an APNs alert, so iOS shows
/// them without help. Same approach as FireNex's NotificationHelper.
class PushNotification {
  PushNotification._();

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';

  static String _text(dynamic v) => v?.toString().trim() ?? '';

  /// Title: data['title'], else the notification block, else "Alert".
  static String titleOf(
    Map<String, dynamic> data, {
    String? notificationTitle,
  }) {
    final t = _text(data['title']);
    if (t.isNotEmpty) return t;
    final n = _text(notificationTitle);
    return n.isNotEmpty ? n : 'Alert';
  }

  /// Body: data['body']; else built from the SR1 fields (site / event /
  /// time); else the notification block.
  static String bodyOf(Map<String, dynamic> data, {String? notificationBody}) {
    final b = _text(data['body']);
    if (b.isNotEmpty) return b;
    final parts = [
      _text(data['site_name']),
      _text(data['event_name']),
      _text(data['event_time']),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join('\n');
    final n = _text(notificationBody);
    return n.isNotEmpty ? n : 'New alert';
  }

  /// One id per event, so a resent push replaces instead of duplicating.
  static int idOf(Map<String, dynamic> data) {
    final logId = int.tryParse(_text(data['log_id']));
    if (logId != null) return logId & 0x7fffffff;
    final key =
        '${data['panel_id']}|${data['event_code'] ?? data['event']}|'
        '${data['event_time'] ?? data['dt']}';
    return key.hashCode & 0x7fffffff;
  }

  /// Android only: put the alert in the notification tray (works from the
  /// background isolate too — it initialises the plugin itself).
  static Future<void> showOnAndroid(
    FlutterLocalNotificationsPlugin plugin,
    RemoteMessage message,
  ) async {
    if (!Platform.isAndroid) return;
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final title = titleOf(
      message.data,
      notificationTitle: message.notification?.title,
    );
    final body = bodyOf(
      message.data,
      notificationBody: message.notification?.body,
    );
    await plugin.show(
      idOf(message.data),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
      ),
    );
  }
}
