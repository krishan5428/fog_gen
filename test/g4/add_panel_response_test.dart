import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/responses/add_panel_response.dart';

void main() {
  group('AddPanelResponse', () {
    test('reads FogShield "message" key and bool status', () {
      final r = AddPanelResponse.fromJson({'status': true, 'message': 'Saved'});
      expect(r.status, isTrue);
      expect(r.msg, 'Saved');
      expect(r.panelAccNo, isNull);
      expect(r.pnlId, isNull);
    });

    test('reads FireNex "msg" key, pnl_id and panel_acc_no for G4', () {
      final r = AddPanelResponse.fromJson({
        'status': true,
        'msg': 'Added',
        'pnl_id': '200333',
        'panel_acc_no': '004521',
      });
      expect(r.msg, 'Added');
      expect(r.pnlId, 200333);
      expect(r.panelAccNo, '004521');
    });

    test('accepts int pnl_id and pnl_acc_no fallback', () {
      final r = AddPanelResponse.fromJson({
        'status': 1,
        'pnl_id': 42,
        'pnl_acc_no': '000042',
      });
      expect(r.status, isTrue);
      expect(r.pnlId, 42);
      expect(r.panelAccNo, '000042');
    });

    test('JSON string body is decoded', () {
      final r = AddPanelResponse.fromJson('{"status":false,"message":"Dup"}');
      expect(r.status, isFalse);
      expect(r.msg, 'Dup');
    });

    test('missing status and garbage body are failures, not crashes', () {
      expect(AddPanelResponse.fromJson({'message': 'x'}).status, isFalse);
      expect(AddPanelResponse.fromJson('not json').status, isFalse);
      expect(AddPanelResponse.fromJson(null).status, isFalse);
    });
  });

  group('PanelData G4 fields', () {
    Map<String, dynamic> base() => {
      'pnl_id': 7,
      'usr_id': '3',
      'panel_name': 'FIRE PANEL-4 ZONE - F04L G4',
      'pnl_type': '4GCOM',
    };

    test('panel_imei round-trips through fromJson/toJson', () {
      final p = PanelData.fromJson({...base(), 'panel_imei': '861919084418721'});
      expect(p.panelImei, '861919084418721');
      expect(PanelData.fromJson(p.toJson()).panelImei, '861919084418721');
    });

    test('defaults: no IMEI, owner share status (non-G4 panels unchanged)', () {
      final p = PanelData.fromJson(base());
      expect(p.panelImei, '');
      expect(p.shareStatus, 'owner');
      expect(p.sharedBy, '');
    });

    test('copyWith changes only the given field', () {
      final p = PanelData.fromJson({...base(), 'panel_imei': '1'});
      final q = p.copyWith(adminMobileNumber: '9999999999');
      expect(q.adminMobileNumber, '9999999999');
      expect(q.panelImei, '1');
      expect(q.pnlId, 7);
    });
  });
}
