// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app/fogshield_app.dart';
import 'utils/app_info.dart';

// 1. Define Local Notifications Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🌙 Background Message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppInfo.instance.init();

  // 3. Set Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Setup Local Notifications (Android Channel)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // =======================================================
  // 🔴 FIX: Define iOS (Darwin) Settings
  // =======================================================
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // 5. Initialize with BOTH Android and iOS settings
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin, // 👈 This was missing causing the crash
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      debugPrint("Local Notification Tapped: ${details.payload}");
    },
  );

  // 6. Foreground Notification Listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("☀️ Foreground Message: ${message.notification?.title}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // For iOS, the system handles foreground heads-up alerts if set in Info.plist
    // For Android, we manually show it.
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          // iOS automatically handles heads-up notifications if foreground presentation options are set
        ),
      );
    }
  });

  runApp(const FogShieldApp());
}
