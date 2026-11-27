import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fog_gen_new/features/mqtt/screens/add_mqtt_panel.dart';
import 'package:fog_gen_new/presentation/dialog/panel_type.dart';
import 'package:fog_gen_new/presentation/screens/about_us.dart';
import 'package:fog_gen_new/presentation/screens/add_number_solitare.dart';
import 'package:fog_gen_new/presentation/screens/add_panel/add_ip_gprs_panel.dart';
import 'package:fog_gen_new/presentation/screens/add_vendor.dart';
import 'package:fog_gen_new/presentation/screens/edit_panel.dart';
import 'package:fog_gen_new/presentation/screens/login.dart';
import 'package:fog_gen_new/presentation/screens/logs/logs_screen.dart';
import 'package:fog_gen_new/presentation/screens/main/main_screen.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/more_settings.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/telephone_no_settings_page.dart';
import 'package:fog_gen_new/presentation/screens/mqtt_panel_details.dart';
import 'package:fog_gen_new/presentation/screens/panel_details/panel_details.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/presentation/screens/profile.dart';
import 'package:fog_gen_new/presentation/screens/signup.dart';
import 'package:fog_gen_new/presentation/screens/vendor_profile.dart';
import 'package:fog_gen_new/presentation/widgets/panel_item.dart';

import '../helpers/app_harness.dart';

/// Each screen must build inside the app's providers without throwing.
/// Network is disabled and panels point at a closed local port.
void main() {
  setUp(setUpHarness);

  // A small, common Android phone (360 x 800 dp).
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final screens = <String, Widget Function()>{
    'Login': () => const LoginScreen(),
    'Sign up': () => const SignUpScreen(),
    'Panel list': () => const PanelListPage(),
    'Add panel (FogShield)': () => const AddPanelFormScreen(
      panelType: 'FOGGER PANEL',
      panelName: 'FogShield Pro',
    ),
    'Add G4 device': () => const AddMqttPanelPage(
      panelType: 'FIRE PANEL',
      panelName: 'FIRE PANEL-4 ZONE - F04L G4',
    ),
    'Panel details': () => PanelDetailsScreen(panelData: testPanel()),
    'G4 device details': () => MqttPanelDetailsScreen(
      panelData: testPanel(imei: '861919084418721', type: '4GCOM'),
    ),
    'Edit panel': () => EditPanelScreen(panelData: testPanel()),
    'More settings': () => MoreSettingsScreen(panelData: testPanel()),
    'Telephone numbers': () => TelephoneNoSettingsPage(panelData: testPanel()),
    'Add number (Solitare)': () =>
        AddNumberSolitarePage(panelData: testPanel()),
    'Logs': () => LogsScreen(panelData: testPanel()),
    'SR1 control (main)': () => MainScreen(panelData: testPanel()),
    'Profile': () => const ProfilePage(),
    'Vendor profile': () => const VendorProfilePage(),
    'Add vendor': () => const AddVendorPage(),
    'About us': () => const AboutUsPage(),
  };

  screens.forEach((name, make) {
    testWidgets('$name builds', (tester) async {
      phone(tester);
      await tester.pumpWidget(harness(make()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);

      // Unmount and let pending timers run out.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
  });

  // G4 device details read the saved user's role, as in FireNex.
  Future<void> openG4Details(WidgetTester tester, String? role) async {
    phone(tester);
    final user = {
      'usr_id': 3,
      'name': 'Tester',
      'mobile': '9999999999',
      'role': ?role,
    };
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'login_backend': 'fogshield',
      'user_id': 3,
      'user_data': jsonEncode(user),
    });
    await tester.pumpWidget(
      harness(
        MqttPanelDetailsScreen(
          panelData: testPanel(imei: '861919084418721', type: '4GCOM'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(
      find.byIcon(role == null ? Icons.delete : Icons.send),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('G4 details: a customer (FogShield default) sees DELETE DEVICE', (
    tester,
  ) async {
    await openG4Details(tester, null);
    expect(find.text('DELETE DEVICE'), findsOneWidget);
    expect(find.text('RELEASE TO MARKET'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('G4 details: a factory worker sees RELEASE TO MARKET '
      '(FireNex behaviour)', (tester) async {
    await openG4Details(tester, 'factory_worker');
    expect(find.text('RELEASE TO MARKET'), findsOneWidget);
    expect(find.text('DELETE DEVICE'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('Panel type dialog lists FogShield models and the 3 G4 models', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const Scaffold(body: PanelTypeDialog())));
    expect(find.text('FogShield Pro'), findsOneWidget);
    expect(find.text('4G (MQTT) DEVICES'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('FIRE COMMUNICATOR-MX FCOM G4'),
      100,
    );
    expect(find.text('FIRE PANEL-2 ZONE - F02L G4'), findsOneWidget);
    expect(find.text('FIRE COMMUNICATOR-MX FCOM G4'), findsOneWidget);
  });

  testWidgets('Panel card: G4 panel shows CONNECT, FogShield panel shows '
      'TRIGGER FOGGER', (tester) async {
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: ListView(
            children: [
              PanelCard(panelData: testPanel()),
              PanelCard(
                panelData: testPanel(
                  name: 'FIRE PANEL-4 ZONE - F04L G4',
                  type: '4GCOM',
                  imei: '861919084418721',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('TRIGGER FOGGER'), findsOneWidget);
    expect(find.text('CONNECT'), findsOneWidget);
    expect(find.text('EVACUATE'), findsOneWidget);
    expect(find.text('SILENCE'), findsOneWidget);
  });
}
