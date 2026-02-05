import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart'; // 1. Import this

import '../core/repo/user_repo.dart';
import '../presentation/screens/splash.dart';
import '../presentation/cubit/user/user_cubit.dart';
import '../presentation/cubit/panel/panel_cubit.dart';
import '../presentation/cubit/vendor/vendor_cubit.dart';
import '../presentation/cubit/mappings/site_cubit.dart';
import '../presentation/cubit/mappings/panel_sim_number_cubit.dart';
import '../core/data/repo_impl/user_repository_impl.dart';
import '../core/data/repo_impl/panel_repository_impl.dart';
import '../core/data/repo_impl/vendor_repo_impl.dart';

import '../utils/auth_helper.dart';
import 'app_theme.dart';

class FogShieldApp extends StatefulWidget {
  const FogShieldApp({super.key});

  @override
  State<FogShieldApp> createState() => _FogShieldAppState();
}

class _FogShieldAppState extends State<FogShieldApp> {
  // GlobalKey allows us to access Context from anywhere (even inside listeners)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
    _setupForegroundToast(); // 2. Call the new setup method

    // Listen for Token Refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("⚠️ FCM Token Refreshed automatically!");
      _updateTokenOnServer(newToken);
    });
  }

  void _updateTokenOnServer(String token) async {
    await SharedPreferenceHelper.saveDeviceToken("");
  }

  // 3. LISTEN FOR NOTIFICATIONS WHILE APP IS OPEN
  // 3. LISTEN FOR NOTIFICATIONS WHILE APP IS OPEN
  void _setupForegroundToast() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("☀️ Foreground Notification Data: ${message.data}");

      // 1. Format the Body & Title based on your requirement
      final String body = message.data.isNotEmpty
          ? "Site: ${message.data["site_name"] ?? 'N/A'}\n"
                "Event: ${message.data["event_name"] ?? 'N/A'}\n"
                "Time: ${message.data["event_time"] ?? 'N/A'}"
          : message.notification?.body ?? "New Alert";

      final String title = message.notification?.title ?? "Security Alert";

      // We use the Navigator Key to get the current context safely
      final context = _navigatorKey.currentContext;

      if (context != null) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          // 2. Use the formatted variables here
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          description: Text(
            body,
            maxLines: 4,
          ), // Allow more lines for the details
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 5),
          animationDuration: const Duration(milliseconds: 300),
          icon: const Icon(
            Icons.info_outline,
            color: AppColors.colorPrimary,
          ),
          primaryColor: AppColors.colorPrimary,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: BorderRadius.circular(12),
          showProgressBar: true,
          closeButtonShowType: CloseButtonShowType.onHover,
          callbacks: ToastificationCallbacks(
            onTap: (toastItem) {
              debugPrint("Toast clicked!");
              // Add navigation logic here if needed
            },
          ),
        );
      }
    });
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("🔔 Notification Clicked: ${message.data}");
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<UserRepo>(create: (_) => UserRepoImpl())],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UserCubit>(
            create: (context) => UserCubit(context.read<UserRepo>()),
          ),
          BlocProvider<PanelCubit>(
            create: (_) => PanelCubit(PanelRepositoryImpl()),
          ),
          BlocProvider<VendorCubit>(
            create: (_) => VendorCubit(VendorRepoImpl()),
          ),
          BlocProvider<SiteCubit>(create: (_) => SiteCubit()),
          BlocProvider<PanelSimNumberCubit>(
            create: (_) => PanelSimNumberCubit(),
          ),
        ],
        // 4. Wrap MaterialApp with ToastificationWrapper
        child: ToastificationWrapper(
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'FogShield',
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
