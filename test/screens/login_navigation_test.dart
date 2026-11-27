import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/user_data.dart';
import 'package:fog_gen_new/core/repo/user_repo.dart';
import 'package:fog_gen_new/core/responses/login_response.dart';
import 'package:fog_gen_new/presentation/screens/add_vendor.dart';
import 'package:fog_gen_new/presentation/screens/login.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';

import '../helpers/app_harness.dart';

/// Login returns vendor_added; the screen decides where to go.
class LoginRepo extends Fake implements UserRepo {
  LoginRepo({required this.vendorAdded});
  final bool vendorAdded;

  @override
  Future<LoginResponse> login(
    String mobile,
    String password,
    String fcm,
  ) async => LoginResponse(
    status: true,
    msg: 'Login successful',
    token: 'jwt',
    vendorAdded: vendorAdded,
    data: UserData.fromJson({'usr_id': 1, 'name': 'Test', 'mobile': mobile}),
  );
}

Future<void> logIn(WidgetTester tester, {required bool vendorAdded}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    harness(const LoginScreen(), userRepo: LoginRepo(vendorAdded: vendorAdded)),
  );
  await tester.enterText(find.byType(TextField).at(0), '9899446573');
  await tester.enterText(find.byType(TextField).at(1), '123456');
  await tester.tap(find.text('LOGIN'));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(setUpHarness);

  testWidgets('no vendor yet → Add Vendor page', (tester) async {
    await logIn(tester, vendorAdded: false);
    expect(find.byType(AddVendorPage), findsOneWidget);
    expect(find.byType(PanelListPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('vendor already added → straight to the panel list', (
    tester,
  ) async {
    await logIn(tester, vendorAdded: true);
    expect(find.byType(PanelListPage), findsOneWidget);
    expect(find.byType(AddVendorPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
