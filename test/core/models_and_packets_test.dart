import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/data/pojo/user_data.dart';
import 'package:fog_gen_new/core/data/pojo/vendor_data.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/core/utils/packets.dart';

void main() {
  group('Packets (TCP SR1 protocol)', () {
    setUp(() => Application().mPassword = '1234');

    test('read packet joins args with # and skips empty ones', () {
      expect(
        Packets.getPacket(isReadPacket: true, args: ['007', '', '001']),
        'S*1234#R#007#001*E',
      );
    });

    test('write packet', () {
      expect(
        Packets.getPacket(isReadPacket: false, args: ['007', '002', '3']),
        'S*1234#W#007#002#3*E',
      );
    });

    test('connect / disconnect packets', () {
      expect(Packets.connectPacket(), 'S*1234#R#000#1*E');
      expect(Packets.disconnectPacket(), 'S*1234#W#013*E');
    });

    test('getPacketId and splitPacket read a reply', () {
      const reply = 'S*1234#R#007#0*E';
      expect(Packets.getPacketId(reply), '007');
      expect(Packets.splitPacket(reply), ['R', '007', '0']);
      expect(Packets.splitOutputPacket(reply), ['R', '007', '0']);
    });

    test('malformed replies give empty results, not throws', () {
      expect(Packets.getPacketId('garbage'), '');
      expect(Packets.splitPacket('garbage'), isEmpty);
    });

    test('MQTT body pads the passcode to 6 digits', () {
      expect(
        Packets.buildMqttMessage(
          passcode: '1234',
          isReadPacket: true,
          packetId: '000',
          data: '00',
        ),
        r'001234$01$000$00*ED',
      );
      expect(
        Packets.buildMqttMessage(
          passcode: '001234',
          isReadPacket: false,
          packetId: '012',
        ),
        r'001234$02$012*ED',
      );
    });
  });

  test('Application is a singleton', () {
    Application().mSiteName = 'X';
    expect(Application().mSiteName, 'X');
    expect(identical(Application(), Application()), isTrue);
  });

  group('UserData', () {
    test('round-trips through JSON (saved to prefs at login)', () {
      final u = UserData.fromJson({
        'usr_id': 5,
        'name': 'A',
        'email': 'a@b.c',
        'mobile': '9999999999',
        'status': '1',
      });
      final back = UserData.fromJson(u.toJson());
      expect(back.usrId, 5);
      expect(back.email, 'a@b.c');
      expect(back.deviceId, '');
    });

    test('accepts usr_id and status as strings/ints from the server', () {
      final u = UserData.fromJson({'usr_id': '17', 'status': 1});
      expect(u.usrId, 17);
      expect(u.status, '1');
    });
  });

  group('PanelData', () {
    test('missing keys default to empty, booleans parse 1/"1"/"true"', () {
      final p = PanelData.fromJson({
        'pnl_id': '12',
        'is_ip_panel': 1,
        'is_ip_gsm_panel': 'true',
      });
      expect(p.pnlId, 12);
      expect(p.isIpPanel, isTrue);
      expect(p.isIpGsmPanel, isTrue);
      expect(p.siteName, '');
    });

    test('bad pnl_id gives 0, not a throw', () {
      expect(PanelData.fromJson({'pnl_id': 'x'}).pnlId, 0);
    });

    test('toJson → fromJson keeps every field used by the offline cache', () {
      final p = PanelData.fromJson({
        'pnl_id': 3,
        'usr_id': '1',
        'site_name': 'S',
        'panel_sim_number': '9876543210',
        'admin_mobile_number': '9999999999',
        'mobile_number10': '1111111111',
        'is_ip_panel': true,
      });
      final q = PanelData.fromJson(p.toJson());
      expect(q.toJson(), p.toJson());
    });
  });

  test('VendorData keeps fields through JSON', () {
    final v = VendorData.fromJson({
      'user_id': '3',
      'vendor_name': 'V',
      'vendor_mobile': '1',
    });
    expect(VendorData.fromJson(v.toJson()).vendor_name, 'V');
  });
}
