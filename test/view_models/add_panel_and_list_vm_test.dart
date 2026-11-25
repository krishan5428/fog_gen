import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/repo/panel_repo.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:fog_gen_new/presentation/screens/add_panel/add_panel_view_model.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

AddPanelViewModel filled({
  String site = 'Site',
  String address = 'Addr',
  String sim = '9876543210',
  String admin = '9999999999',
  String ip = '192.168.1.10',
  String port = '5000',
  String staticIp = '',
  String staticPort = '',
  String pass = '1234',
}) {
  final vm = AddPanelViewModel();
  vm.siteNameController.text = site;
  vm.addressController.text = address;
  vm.panelSimNumberController.text = sim;
  vm.adminNumberController.text = admin;
  vm.ipAddressController.text = ip;
  vm.portNumberController.text = port;
  vm.staticIpController.text = staticIp;
  vm.staticPortController.text = staticPort;
  vm.passwordController.text = pass;
  return vm;
}

String? validate(AddPanelViewModel vm, {List<String> sites = const []}) =>
    vm.validateForm(existingSiteNames: sites, existingPanelSims: ['1111111111']);

/// Local SR1 panel that answers the connect packet with [reply].
Future<ServerSocket> sr1(String reply) async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  s.listen((c) {
    c.done.catchError((_) => c);
    c.listen((_) => c.write(reply), onError: (_) {});
  });
  return s;
}

class NoServer extends Fake implements PanelRepo {}

void main() {
  group('AddPanelViewModel.validateForm', () {
    test('valid form → null', () => expect(validate(filled()), isNull));

    final cases = <String, AddPanelViewModel Function()>{
      'Site Name cannot be empty': () => filled(site: ' '),
      'Site Address cannot be empty': () => filled(address: ''),
      'Panel sim number already exists.': () => filled(sim: '1111111111'),
      'Enter a valid IP Address (e.g., 192.168.1.1)': () => filled(ip: 'abc'),
      'Enter a valid Static IP Address': () => filled(staticIp: '1.2.3'),
      'Panel SIM Number cannot be empty': () => filled(sim: ''),
      'Panel SIM Number must be 10 or 13 digits': () => filled(sim: '12345'),
      'Admin SIM Number cannot be empty': () => filled(admin: ''),
      'Enter a valid Port Number': () => filled(port: '0'),
      'Enter a valid Static Port Number': () => filled(staticPort: 'x'),
      'Password must be 4 digits': () => filled(pass: '12a4'),
    };
    cases.forEach((msg, make) {
      test(msg, () => expect(validate(make()), msg));
    });

    test('duplicate site name', () {
      expect(
        validate(filled(site: 'Home'), sites: ['Home']),
        'Site name "Home" already exists.',
      );
    });
  });

  group('AddPanelViewModel.connectToPanel (local SR1 stand-in)', () {
    test('connected: parses MAC, version and account no. into save data',
        () async {
      SharedPreferences.setMockInitialValues({'user_id': 3});
      final s = await sr1(
        'S*000#1#004145098123236254#123456789123456#0#V0.1.1C#999999*E',
      );
      final vm = filled(port: '${s.port}', ip: '127.0.0.1');

      expect(await vm.connectToPanel(), ConnectionStatus.connected);
      expect(Application().mPassword, '1234');
      final data = (await vm.prepareSaveData(
        panelType: 'FOGGER PANEL',
        panelName: 'FogShield Pro',
      ))!;
      expect(data['pnl_mac'], '004145098123236254');
      expect(data['pnl_ver'], 'V0.1.1C');
      expect(data['pnl_acc_no'], '999999');
      expect(data['usr_id'], '3');
      expect(data['pnl_type'], 'FOGGER PANEL');
      await s.close();
    });

    test('already connected elsewhere', () async {
      final s = await sr1('S*000#3#*E');
      final vm = filled(port: '${s.port}', ip: '127.0.0.1');
      expect(await vm.connectToPanel(), ConnectionStatus.alreadyConnected);
      await s.close();
    });

    test('unexpected reply → failed', () async {
      final s = await sr1('S*000#0#*E');
      final vm = filled(port: '${s.port}', ip: '127.0.0.1');
      expect(await vm.connectToPanel(), ConnectionStatus.failed);
      expect(vm.isLoading, isFalse);
      await s.close();
    });

    test('no user logged in → no save data', () async {
      SharedPreferences.setMockInitialValues({});
      expect(
        await filled().prepareSaveData(panelType: 'x', panelName: 'y'),
        isNull,
      );
    });
  });

  group('PanelListViewModel', () {
    PanelData p(String site, String type, String sim) => PanelData.fromJson({
      'pnl_id': site.hashCode,
      'site_name': site,
      'pnl_type': type,
      'panel_sim_number': sim,
    });

    testWidgets('success fills the list, filter by type, feeds the mapping '
        'cubits with sorted unique site names and SIMs', (tester) async {
      final sites = SiteCubit();
      final sims = PanelSimNumberCubit();
      final vm = PanelListViewModel();
      late BuildContext ctx;
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sites),
            BlocProvider.value(value: sims),
            BlocProvider(create: (_) => PanelCubit(NoServer())),
          ],
          child: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );

      vm.handleSuccess(ctx, [
        p('B', 'FOGGER PANEL', '2'),
        p('A', '4GCOM', '1'),
        p(' ', 'FOGGER PANEL', ''),
        p('B', 'fogger panel', '2'),
      ]);
      expect(vm.filteredPanelList, hasLength(4));
      expect(sites.state, ['A', 'B']);
      expect(sims.state, ['1', '2']);

      vm.setFilter('FOGGER PANEL');
      expect(vm.filteredPanelList, hasLength(3));
      vm.setFilter('ALL');
      expect(vm.filteredPanelList, hasLength(4));

      vm.handleFailure();
      expect(vm.loadFailed, isTrue);
      vm.handleLoading();
      expect(vm.loadFailed, isFalse);
    });
  });

}
