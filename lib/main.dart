import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fog_gen_new/utils/app_info.dart';

import 'app/fogshield_app.dart';

// 1. Background Message Handler (Must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Set Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Request Permissions (Critical for iOS)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // 5. Get Token (Print it to console to test)
  try {
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint("✅ FCM Token: $token");
    } else {
      debugPrint("⚠️ FCM Token is null");
    }
  } catch (e) {
    debugPrint("❌ Error getting FCM Token: $e");
  }

  await AppInfo.instance.init();
  runApp(const FogShieldApp());
}
