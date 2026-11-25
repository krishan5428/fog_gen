import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/more_settings_view_model.dart';

import '../helpers/app_harness.dart';

class FakeSr1 extends Fake implements SocketRepository {
  FakeSr1(this.reply);
  final String reply;
  final List<String> sent = [];

  @override
  Future<String> sendPacketSR1(String packet, {bool isPriority = false}) async {
    sent.add(packet);
    return reply;
  }
}

void main() {
  setUp(setUpHarness);

  testWidgets('Panel ID not read over IP → explains it, offers no SMS '
      '(SMS cannot read a Panel ID)', (tester) async {
    final repo = FakeSr1('S*000#0*E'); // not a 001 reply
    final vm = MoreSettingsViewModel(
      panelData: testPanel(ipGsm: true),
      socketRepository: repo,
    );
    late BuildContext ctx;
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    vm.fetchPanelID(ctx);
    await tester.pumpAndSettle();

    expect(repo.sent.single, 'S*1234#R#001*E');
    expect(find.textContaining('SMS'), findsNothing);
    expect(
      find.textContaining('Panel ID can only be read over IP'),
      findsOneWidget,
    );
  });
}
