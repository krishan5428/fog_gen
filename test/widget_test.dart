import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/presentation/screens/splash.dart';
import 'package:fog_gen_new/utils/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'helpers/fake_video_player.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // main() does both of these before runApp; the test must too.
    PackageInfo.setMockInitialValues(
      appName: 'FogShield',
      packageName: 'com.securico.fogshield',
      version: '1.1.0',
      buildNumber: '14',
      buildSignature: '',
    );
    await AppInfo.instance.init();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  testWidgets('Splash screen loads without crash and shows the version', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Version 1.1.0'), findsOneWidget);
  });
}
