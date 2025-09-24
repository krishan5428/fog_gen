import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:fire_nex/utils/navigation.dart';

import '../../utils/app_info.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String version = '';

  @override
  void initState() {
    super.initState();
    version = AppInfo.instance.version;

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    print('Waiting...');
    await Future.delayed(const Duration(milliseconds: 1200));

    print("Checking login state...");
    bool isLoggedIn = await SharedPreferenceHelper.getLoginState();
    print("Login state: $isLoggedIn");

    if (!mounted) return;

    print("Navigating...");
    CustomNavigation.instance.pushReplace(
      context: context,
      screen: isLoggedIn ? const PanelListPage() : const LoginScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/top_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Text(
              'Version ${AppInfo.instance.version}',
              style: TextStyle(
                color: AppColors.colorPrimaryDark,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 150,
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.colorPrimary),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '2025 © All rights reserved by ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                Text(
                  'Securico',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppColors.colorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
