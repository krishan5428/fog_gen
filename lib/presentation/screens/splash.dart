import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import '../../main.dart';
import '../../utils/app_info.dart';
import '../cubit/user/user_cubit.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false;
  final Duration maxSplashDuration = const Duration(seconds: 6);

  @override
  void initState() {
    super.initState();

    // 1. Initialize Firebase Listeners and Notification Channels
    // initializeFirebaseAndNotifications(
    //   onForegroundMessage: (title, body) {
    //     // Logic for when a notification arrives while app is open
    //     logger.i("Foreground notification received: $title");
    //     // You could use a global key to show a dialog or snackbar here
    //   },
    // );

    _controller = VideoPlayerController.asset('assets/images/logo_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (_controller.value.position >= maxSplashDuration && !_navigated) {
      _navigated = true;
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    bool isLoggedIn = await SharedPreferenceHelper.getLoginState();

    // 🆕 NEW: Sync Token if already logged in
    if (isLoggedIn) {
      _syncTokenInBackground();
    }

    if (!mounted) return;

    CustomNavigation.instance.pushReplace(
      context: context,
      screen: isLoggedIn ? const PanelListPage() : const LoginScreen(),
    );
  }

  Future<void> _syncTokenInBackground() async {
    try {
      String? freshToken = await FirebaseMessaging.instance.getToken();
      String? lastSavedToken = await SharedPreferenceHelper.getDeviceToken();
      int? userId = (await SharedPreferenceHelper.getUserData())?.usrId;

      if (freshToken != null && userId != null && freshToken != lastSavedToken) {
        debugPrint("🔄 Token changed. Syncing with server...");

        if (mounted) {
          context.read<UserCubit>().updateUser(
            userId: userId.toString(),
            key: "device_id", // Must match the DB column name exactly
            value: freshToken,
          );

          await SharedPreferenceHelper.saveDeviceToken(freshToken);
        }
      }
    } catch (e) {
      debugPrint("Token Sync Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_controller.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),

            // Version
            Positioned(
              top: 10,
              right: 20,
              child: Text(
                'Version ${AppInfo.instance.version}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Loader
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

            // Footer
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '2026 © All rights reserved by ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'Securico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }
}
