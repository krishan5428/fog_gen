import 'package:fog_gen_new/core/utils/packets.dart';

class FourGMqttCommands {
  FourGMqttCommands._();

  /// The panel only accepts a 6-digit passcode on the wire (entered "1234"
  /// -> "001234") and rejects anything else with a Wrong Passcode error
  /// frame. Panels store the 4-digit code, so every builder pads it here —
  /// same rule the Securico 4GCOM dashboard applies before sending.
  static String wirePasscode(String passcode) => passcode.padLeft(6, '0');

  static String connect({required String imei, required String passcode}) {
    final body = Packets.buildMqttMessage(
      passcode: passcode,
      isReadPacket: true,
      packetId: '000',
      data: '00',
    );

    return 'ST*$imei\$$body';
  }

  static String disconnect({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$01\$000\$01*ED";
  }

  static String readDashboard({
    required String imei,
    required String passcode,
  }) {
    return "ST*$imei\$${wirePasscode(passcode)}\$01\$001*ED";
  }

  static String panic({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$01*ED";
  }

  static String alarmAbort({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$02*ED";
  }

  // Function IDs per protocol: 04 = DISARM, 05 = ARM.
  static String arm({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$05*ED";
  }

  static String disarm({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$04*ED";
  }

  static String readAlarmLogs({
    required String imei,
    required String passcode,
  }) {
    return "ST*$imei\$${wirePasscode(passcode)}\$01\$015\$01*ED";
  }

  static String readEventLogs({
    required String imei,
    required String passcode,
  }) {
    return "ST*$imei\$${wirePasscode(passcode)}\$01\$016\$01*ED";
  }

  static String queueAbort({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$03*ED";
  }

  static String sounderOff({required String imei, required String passcode}) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$001\$06*ED";
  }

  /// How long Evacuate / Alarm Abort / Sounder Off hold their output ON
  /// before the app switches it back OFF.
  static const outputPulseDuration = Duration(seconds: 9);

  // Packet 012 (Output Control): output 1-4 is sent as 081-084, state
  // 1 = ON, 0 = OFF.
  static String setOutput({
    required String imei,
    required String passcode,
    required int output,
    required bool on,
  }) {
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$012\$08$output\$${on ? 1 : 0}*ED";
  }

  static String readOutputSettings({
    required String imei,
    required String passcode,
    required int output,
  }) {
    return "ST*$imei\$${wirePasscode(passcode)}\$01\$011\$08$output*ED";
  }

  /// Builds the packet-011 write for the record in [readResponse] with only
  /// ENABLED switched to 1; every other field is echoed back unchanged.
  /// Returns null when [readResponse] isn't an Output Settings read reply.
  static String? enableOutputFromSettings({
    required String imei,
    required String passcode,
    required String readResponse,
  }) {
    final body = readResponse.trim().replaceFirst(RegExp(r'\*ED$'), '');
    final parts = body.split('\$');
    if (parts.length < 8 ||
        parts[0] != "ST*$imei" ||
        parts[2] != "03" ||
        parts[3] != "01" ||
        parts[4] != "011") {
      return null;
    }

    final fields = parts.sublist(5);
    fields[1] = "1";
    return "ST*$imei\$${wirePasscode(passcode)}\$02\$011\$${fields.join('\$')}*ED";
  }
}
