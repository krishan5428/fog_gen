import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_commands.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_parser.dart';

void main() {
  const imei = '123456789012345';

  group('FourGMqttCommands', () {
    test('connect builds the packet-000 handshake payload', () {
      final packet = FourGMqttCommands.connect(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$01\$000\$00*ED'));
    });

    test('disconnect builds the packet-000 teardown payload', () {
      final packet = FourGMqttCommands.disconnect(
        imei: imei,
        passcode: '001234',
      );
      expect(packet, equals('ST*$imei\$001234\$01\$000\$01*ED'));
    });

    test('readDashboard builds the packet-001 read payload', () {
      final packet = FourGMqttCommands.readDashboard(
        imei: imei,
        passcode: '001234',
      );
      expect(packet, equals('ST*$imei\$001234\$01\$001*ED'));
    });
  });

  group('FourGMqttCommands passcode padding', () {
    test('wirePasscode pads a 4-digit passcode to 6 digits', () {
      expect(FourGMqttCommands.wirePasscode('1234'), equals('001234'));
    });

    test('wirePasscode leaves a 6-digit passcode unchanged', () {
      expect(FourGMqttCommands.wirePasscode('001234'), equals('001234'));
      expect(FourGMqttCommands.wirePasscode('987654'), equals('987654'));
    });

    test('readDashboard pads a 4-digit stored passcode', () {
      final packet = FourGMqttCommands.readDashboard(
        imei: imei,
        passcode: '1234',
      );
      expect(packet, equals('ST*$imei\$001234\$01\$001*ED'));
    });

    test('disconnect pads a 4-digit stored passcode', () {
      final packet = FourGMqttCommands.disconnect(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$01\$000\$01*ED'));
    });
  });

  group('FourGMqttCommands dashboard commands (packet 001)', () {
    // Same wire bytes the Securico 4GCOM dashboard sends:
    // ST*{IMEI}${6-digit PASSCODE}$02$001${FUNCTION_ID}*ED
    test('panic (Evacuate) sends function 01 with padded passcode', () {
      final packet = FourGMqttCommands.panic(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$01*ED'));
    });

    test('alarmAbort sends function 02 with padded passcode', () {
      final packet = FourGMqttCommands.alarmAbort(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$02*ED'));
    });

    test('queueAbort sends function 03', () {
      final packet = FourGMqttCommands.queueAbort(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$03*ED'));
    });

    test('sounderOff sends function 06', () {
      final packet = FourGMqttCommands.sounderOff(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$06*ED'));
    });

    test('arm sends function 05', () {
      final packet = FourGMqttCommands.arm(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$05*ED'));
    });

    test('disarm sends function 04', () {
      final packet = FourGMqttCommands.disarm(imei: imei, passcode: '1234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$04*ED'));
    });

    test('setOutput turns output 1 (Evacuate) on as 081 via packet 012', () {
      final packet = FourGMqttCommands.setOutput(
        imei: imei,
        passcode: '1234',
        output: 1,
        on: true,
      );
      expect(packet, equals('ST*$imei\$001234\$02\$012\$081\$1*ED'));
    });

    test('setOutput maps outputs 2 and 3 to 082 / 083', () {
      expect(
        FourGMqttCommands.setOutput(
          imei: imei,
          passcode: '1234',
          output: 2,
          on: true,
        ),
        equals('ST*$imei\$001234\$02\$012\$082\$1*ED'),
      );
      expect(
        FourGMqttCommands.setOutput(
          imei: imei,
          passcode: '1234',
          output: 3,
          on: true,
        ),
        equals('ST*$imei\$001234\$02\$012\$083\$1*ED'),
      );
    });

    test('setOutput off sends state 0', () {
      final packet = FourGMqttCommands.setOutput(
        imei: imei,
        passcode: '1234',
        output: 2,
        on: false,
      );
      expect(packet, equals('ST*$imei\$001234\$02\$012\$082\$0*ED'));
    });

    test('enableOutputFromSettings flips only ENABLED and echoes the rest', () {
      final packet = FourGMqttCommands.enableOutputFromSettings(
        imei: imei,
        passcode: '1234',
        readResponse:
            'ST*$imei\$100\$03\$01\$011\$082\$0\$Output 2\$1\$000\$1#08001700\$5*ED',
      );
      expect(
        packet,
        equals(
          'ST*$imei\$001234\$02\$011\$082\$1\$Output 2\$1\$000\$1#08001700\$5*ED',
        ),
      );
    });

    test('enableOutputFromSettings rejects a non-011 frame', () {
      final packet = FourGMqttCommands.enableOutputFromSettings(
        imei: imei,
        passcode: '1234',
        readResponse: 'ST*$imei\$100\$04\$01\$011*ED',
      );
      expect(packet, isNull);
    });

    test('already-padded passcode is not double padded', () {
      final packet = FourGMqttCommands.panic(imei: imei, passcode: '001234');
      expect(packet, equals('ST*$imei\$001234\$02\$001\$01*ED'));
    });
  });

  group('FourGMqttParser.parseCommandResult', () {
    test('write ack 01 on packet 001 is success', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$01\$001*ED',
        imei,
      );
      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
    });

    test('write status 02 (process success) is success', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$02\$001*ED',
        imei,
      );
      expect(result!.isSuccess, isTrue);
    });

    test('write status 04 (processing) on packet 001 is success', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$04\$001*ED',
        imei,
      );
      expect(result!.isSuccess, isTrue);
    });

    test('write ack 01 on packet 012 is success', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$01\$012*ED',
        imei,
      );
      expect(result!.isSuccess, isTrue);
    });

    test('write status 04 on packet 012 is non-terminal (ignored)', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$04\$012*ED',
        imei,
      );
      expect(result, isNull);
    });

    test('read response on packet 012 is not a command result', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$03\$01\$012\$1000*ED',
        imei,
      );
      expect(result, isNull);
    });

    test('write status 04 on packet 000 is non-terminal (ignored)', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$04\$000*ED',
        imei,
      );
      expect(result, isNull);
    });

    test('write ack echoed on packet 000 is success', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$01\$000*ED',
        imei,
      );
      expect(result!.isSuccess, isTrue);
    });

    test('write nack 00 is failure', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$00\$001*ED',
        imei,
      );
      expect(result!.isSuccess, isFalse);
      expect(result.failureReason, equals('Rejected by device'));
    });

    test('write status 03 is process failed', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$03\$001*ED',
        imei,
      );
      expect(result!.isSuccess, isFalse);
      expect(result.failureReason, equals('Process failed'));
    });

    test('error frame 03 reports wrong passcode', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$00\$03*ED',
        imei,
      );
      expect(result!.isSuccess, isFalse);
      expect(result.failureReason, equals('Wrong passcode'));
    });

    test('error frame 05 reports device engaged', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$00\$05*ED',
        imei,
      );
      expect(result!.failureReason, equals('Device engaged, try again'));
    });

    test('unknown error code still reports a failure', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$00\$42*ED',
        imei,
      );
      expect(result!.isSuccess, isFalse);
      expect(result.failureReason, equals('Device error 42'));
    });

    test('dashboard read response confirms the command', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$03\$01\$001\$31000001\$0\$0\$0\$5\$D|0|Zone 1;0|Zone 2*ED',
        imei,
      );
      expect(result!.isSuccess, isTrue);
    });

    test('write ack for another packet ID is ignored', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*$imei\$103\$04\$01\$010*ED',
        imei,
      );
      expect(result, isNull);
    });

    test('frame from a different IMEI is ignored', () {
      final result = FourGMqttParser.parseCommandResult(
        'ST*999999999999999\$103\$04\$01\$001*ED',
        imei,
      );
      expect(result, isNull);
    });

    test('malformed or empty payload is ignored', () {
      expect(FourGMqttParser.parseCommandResult('', imei), isNull);
      expect(FourGMqttParser.parseCommandResult('garbage', imei), isNull);
      expect(
        FourGMqttParser.parseCommandResult('ST*$imei\$103\$04', imei),
        isNull,
      );
    });
  });

  group('FourGMqttParser.parseDashboardOutputStates', () {
    test('reads output states from a real dashboard frame', () {
      final states = FourGMqttParser.parseDashboardOutputStates(
        'ST*$imei\$100\$03\$01\$001\$4\$080\$0\$1\$0\$0\$0\$0\$0'
        '\$1|Input 1;1|Input 2;1|Input 3;1|Input 4;0|Device Tamper;0|Device Panic'
        '\$1|Output 1;0|Output 2;1|Output 3;D|Output 4*ED',
      );
      expect(states, equals(['1', '0', '1', 'D']));
    });

    test('ignores non-dashboard frames', () {
      expect(
        FourGMqttParser.parseDashboardOutputStates(
          'ST*$imei\$100\$04\$01\$012\$081*ED',
        ),
        isNull,
      );
    });
  });

  group('FourGMqttParser handshake detection', () {
    test('isHandshakeSuccess true for an accepted connect response', () {
      final payload = 'ST*$imei\$103\$03\$01\$000\$1.0.0';
      expect(FourGMqttParser.isHandshakeSuccess(payload, imei), isTrue);
      expect(FourGMqttParser.isHandshakeRejected(payload, imei), isFalse);
    });

    test('isHandshakeRejected true for a wrong-passcode response', () {
      final payload = 'ST*$imei\$103\$03\$01\$000\$01';
      expect(FourGMqttParser.isHandshakeRejected(payload, imei), isTrue);
      expect(FourGMqttParser.isHandshakeSuccess(payload, imei), isFalse);
    });

    test('isErrorResponse true for a generic packet-00 error frame', () {
      final payload = 'ST*$imei\$103\$00\$03';
      expect(FourGMqttParser.isErrorResponse(payload, imei), isTrue);
    });
  });
}
