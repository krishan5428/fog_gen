import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/utils/push_notification.dart';

void main() {
  group('PushNotification text', () {
    test('uses the title/body the server put in data (SR1 and G4)', () {
      final d = {
        'title': 'Alert!',
        'body': 'Lab\nFog Triggered\nActive On 25-11-2026 10:09:15',
      };
      expect(PushNotification.titleOf(d), 'Alert!');
      expect(
        PushNotification.bodyOf(d),
        'Lab\nFog Triggered\nActive On 25-11-2026 10:09:15',
      );
    });

    test('G4 push (event code, no event_name) still has a body', () {
      final d = {
        'title': 'Lab',
        'body': 'Evacuation triggered',
        'event': 'PKT012_OUT1',
        'site_name': 'Lab',
      };
      expect(PushNotification.bodyOf(d), 'Evacuation triggered');
    });

    test('no title/body in data → SR1 fields, then notification block', () {
      expect(
        PushNotification.bodyOf({
          'site_name': 'Lab',
          'event_name': 'Fire',
          'event_time': 't',
        }),
        'Lab\nFire\nt',
      );
      expect(
        PushNotification.bodyOf({}, notificationBody: 'from APNs'),
        'from APNs',
      );
      expect(PushNotification.titleOf({}, notificationTitle: 'T'), 'T');
      expect(PushNotification.titleOf({}), 'Alert');
      expect(PushNotification.bodyOf({}), 'New alert');
    });

    test('id: log_id when present, else stable per event', () {
      expect(PushNotification.idOf({'log_id': '42'}), 42);
      final a = PushNotification.idOf({
        'panel_id': '1',
        'event_code': 'FG1',
        'event_time': 't',
      });
      final b = PushNotification.idOf({
        'panel_id': '1',
        'event_code': 'FG1',
        'event_time': 't',
      });
      final c = PushNotification.idOf({
        'panel_id': '1',
        'event_code': 'FG2',
        'event_time': 't',
      });
      expect(a, b);
      expect(a, isNot(c));
      expect(a, greaterThanOrEqualTo(0));
    });
  });
}
