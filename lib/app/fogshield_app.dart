import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
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
  // 1. Create a GlobalKey to allow navigation from the notification listener
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();

    // 🆕 LISTEN FOR TOKEN REFRESHES
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint("⚠️ FCM Token Refreshed automatically!");
      // Save to server immediately using your Repo/Cubit
      _updateTokenOnServer(newToken);
    });
  }

  void _updateTokenOnServer(String token) async {
    // You might need a way to get userId here directly since context might be tricky in streams
    // Or just save it to SharedPrefs and let the next Splash screen handle it.
    await SharedPreferenceHelper.saveDeviceToken(""); // Clear old token so Splash forces an update next time
  }

  // 2. Setup listeners for when the user taps a notification
  Future<void> _setupInteractedMessage() async {
    // Case A: App is Terminated (Killed)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Case B: App is in Background (Running but minimized)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("🔔 Notification Clicked: ${message.data}");

    // Example Navigation logic using the GlobalKey:
    // if (message.data['type'] == 'alert') {
    //   _navigatorKey.currentState?.push(
    //     MaterialPageRoute(builder: (_) => const YourAlertScreen()),
    //   );
    // }
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
        child: MaterialApp(
          // 3. Attach the navigatorKey here
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'FogShield',
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}