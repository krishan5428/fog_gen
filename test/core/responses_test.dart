import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/responses/add_complaint_response.dart';
import 'package:fog_gen_new/core/responses/add_fire_no.dart';
import 'package:fog_gen_new/core/responses/add_intru_no.dart';
import 'package:fog_gen_new/core/responses/add_vendor_response.dart';
import 'package:fog_gen_new/core/responses/del_user_response.dart';
import 'package:fog_gen_new/core/responses/del_vendor_response.dart';
import 'package:fog_gen_new/core/responses/delete_fire_response.dart';
import 'package:fog_gen_new/core/responses/delete_intru_response.dart';
import 'package:fog_gen_new/core/responses/delete_panel_response.dart';
import 'package:fog_gen_new/core/responses/forgot_pass_response.dart';
import 'package:fog_gen_new/core/responses/get_vendor_response.dart';
import 'package:fog_gen_new/core/responses/login_response.dart';
import 'package:fog_gen_new/core/responses/panel_response.dart';
import 'package:fog_gen_new/core/responses/signup_response.dart';
import 'package:fog_gen_new/core/responses/update_fire_no_response.dart';
import 'package:fog_gen_new/core/responses/update_no_response.dart';
import 'package:fog_gen_new/core/responses/update_panel_response.dart';
import 'package:fog_gen_new/core/responses/update_user_response.dart';
import 'package:fog_gen_new/core/responses/user_response.dart' as basic;

/// Every parser must turn a server reply into a value, never throw: a throw
/// is caught upstream as "no network", which queues the action offline and
/// shows a false success (e.g. a rejected update shows "Updated Offline").
void main() {
  group('happy path', () {
    test('login', () {
      final r = LoginResponse.fromJson({
        'status': true,
        'token': 't',
        'msg': 'ok',
        'data': {'usr_id': 5, 'name': 'A'},
      });
      expect(r.status, isTrue);
      expect(r.token, 't');
      expect(r.data!.usrId, 5);
    });

    test('panels list', () {
      final r = PanelResponse.fromJson({
        'status': true,
        'msg': 'ok',
        'panels': [
          {'pnl_id': 1, 'site_name': 'S1'},
          {'pnl_id': '2', 'site_name': 'S2', 'is_ip_panel': '1'},
        ],
      });
      expect(r.panelsData.map((p) => p.pnlId), [1, 2]);
      expect(r.panelsData[1].isIpPanel, isTrue);
    });

    test('vendor (stored in the user row)', () {
      final r = GetVendorResponse.fromJson({
        'status': true,
        'vendor': {'user_id': 3, 'vendor_name': 'V'},
      });
      expect(r.vendorData.single.user_id, '3');
      expect(r.vendorData.single.vendor_name, 'V');
    });

    test('update panel with data', () {
      final r = UpdatePanelResponse.fromJson({
        'status': true,
        'msg': 'ok',
        'data': {'pnl_id': 9, 'site_name': 'New'},
      });
      expect(r.panelData!.siteName, 'New');
    });

    test('simple status/msg replies', () {
      expect(SignupResponse.fromJson({'status': true, 'msg': 'm'}).msg, 'm');
      expect(DeleteUserResponse.fromJson({'status': true}).status, isTrue);
      expect(DeleteVendorResponse.fromJson({'status': true}).status, isTrue);
      expect(AddIntruNo.fromJson({'status': true, 'msg': 'm'}).msg, 'm');
      expect(AddFireNo.fromJson({'message': 'm'}).msg, 'm');
      expect(UpdateFireNoResponse.fromJson({}).message, 'Unknown error');
      expect(UpdateUserResponse.fromJson({'message': 'm'}).msg, 'm');
      expect(basic.LoginResponse.fromJson({'status': true}).status, isTrue);
      expect(
        AddVendorResponse.fromJson({
          'status': true,
          'msg': 'm',
          'vendor_id': 4,
        }).vendorId,
        4,
      );
    });
  });

  group('vendor reply details', () {
    test('single "vendor" object with vendor_mob_no', () {
      final r = GetVendorResponse.fromJson({
        'status': true,
        'vendor': {
          'vendor_name': 'V',
          'vendor_email': null,
          'vendor_mob_no': '9111111111',
          'vendor_address': 'Addr',
        },
      });
      expect(r.vendorData, hasLength(1));
      expect(r.vendorData.single.vendor_mobile, '9111111111');
      expect(r.vendorData.single.vendor_email, '');
    });

    test('no vendor yet → empty list, not a throw', () {
      final r = GetVendorResponse.fromJson({
        'status': false,
        'msg': 'No vendor details found for this user',
      });
      expect(r.status, isFalse);
      expect(r.vendorData, isEmpty);
    });
  });

  group('server rejects or omits keys → value, not a throw', () {
    test('update panel rejected without data', () {
      final r = UpdatePanelResponse.fromJson({'status': false, 'msg': 'No'});
      expect(r.status, isFalse);
      expect(r.msg, 'No');
      expect(r.panelData, isNull);
    });

    test('delete panel with "message" instead of "msg"', () {
      final r = DeletePanelResponse.fromJson({
        'status': true,
        'message': 'Deleted',
      });
      expect(r.status, isTrue);
      expect(r.msg, 'Deleted');
    });

    test('panels list without msg', () {
      final r = PanelResponse.fromJson({'status': true, 'panels': []});
      expect(r.status, isTrue);
      expect(r.msg, '');
    });

    test('delete fire / intru numbers without msg', () {
      expect(DeleteFireResponse.fromJson({'status': true}).msg, '');
      expect(DeleteIntruResponse.fromJson({'status': true}).msg, '');
    });

    test('forgot password / complaint without status', () {
      expect(ForgotPassResponse.fromJson({'msg': 'x'}).status, isFalse);
      expect(AddComplaintResponse.fromJson({}).status, isFalse);
      expect(AddComplaintResponse.fromJson({}).message, '');
    });

    test('vendors without status', () {
      expect(GetVendorResponse.fromJson({}).status, isFalse);
    });

    test('update number without status', () {
      expect(UpdateNoResponse.fromJson({'msg': 'x'}).status, isFalse);
    });

    test('add vendor with string id or no id', () {
      expect(
        AddVendorResponse.fromJson({'status': true, 'vendor_id': '7'}).vendorId,
        7,
      );
      final r = AddVendorResponse.fromJson({'status': false, 'msg': 'dup'});
      expect(r.status, isFalse);
      expect(r.vendorId, 0);
    });
  });
}
