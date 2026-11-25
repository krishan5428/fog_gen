/// Typed representation of the packet-010 (Input Settings) record.
///
/// Field order matches SECTION 11 of the 4G-COM protocol doc for both the
/// Read Response and the Write Request (31 fields after the two keying
/// fields, INPUT_OF_PRODUCT and INPUT_PACKET_ID).
class InputSettings {
  final String imei;
  final String productId;
  final String inputOfProduct;
  final String inputPacketId;

  final String enabled;
  final String name;
  final String zoneType;
  final String sensorType;
  final String eventId;
  final String alertEn;
  final String alertCode;
  final String restoralEn;
  final String restoralCode;
  final String armEn;
  final String armCode;
  final String disarmEn;
  final String disarmCode;
  final String cms1;
  final String cms2;
  final String failover;
  final String pendingQueue;
  final String sms;
  final String call;
  final String alarmLog;
  final String outputEn;
  final String outputMapping;
  final String outputControlMode;
  final String pulseDuration;
  final String audioCallEn;
  final String audioCallFile;
  final String announceEn;
  final String announceFile;
  final String announceCount;
  final String teleNoMapping;

  const InputSettings({
    required this.imei,
    required this.productId,
    required this.inputOfProduct,
    required this.inputPacketId,
    required this.enabled,
    required this.name,
    required this.zoneType,
    required this.sensorType,
    required this.eventId,
    required this.alertEn,
    required this.alertCode,
    required this.restoralEn,
    required this.restoralCode,
    required this.armEn,
    required this.armCode,
    required this.disarmEn,
    required this.disarmCode,
    required this.cms1,
    required this.cms2,
    required this.failover,
    required this.pendingQueue,
    required this.sms,
    required this.call,
    required this.alarmLog,
    required this.outputEn,
    required this.outputMapping,
    required this.outputControlMode,
    required this.pulseDuration,
    required this.audioCallEn,
    required this.audioCallFile,
    required this.announceEn,
    required this.announceFile,
    required this.announceCount,
    required this.teleNoMapping,
  });

  static const _endMarker = '*ED';

  /// Parses a full packet-010 Read Response. Returns null if the frame is
  /// too short to contain the header + all 31 data fields (indices 0-37,
  /// 38 elements total when split on '$').
  static InputSettings? fromReadResponse(String response) {
    final parts = response.trim().split('\$');
    if (parts.length < 38) return null;

    // TELE_NO_MAPPING is the last field and isn't '$'-delimited from the
    // trailing "*ED" frame terminator, so it arrives glued together.
    var teleNoMapping = parts[37];
    if (teleNoMapping.endsWith(_endMarker)) {
      teleNoMapping = teleNoMapping.substring(
        0,
        teleNoMapping.length - _endMarker.length,
      );
    }

    // parts[0] is "ST*{IMEI}" — strip the frame prefix so `imei` holds the
    // bare IMEI, matching every other IMEI field in this codebase.
    // buildWriteRequest() re-adds "ST*" when composing the write payload.
    var imei = parts[0];
    if (imei.startsWith('ST*')) {
      imei = imei.substring(3);
    }

    return InputSettings(
      imei: imei,
      productId: parts[1],
      inputOfProduct: parts[5],
      inputPacketId: parts[6],
      enabled: parts[7],
      name: parts[8],
      zoneType: parts[9],
      sensorType: parts[10],
      eventId: parts[11],
      alertEn: parts[12],
      alertCode: parts[13],
      restoralEn: parts[14],
      restoralCode: parts[15],
      armEn: parts[16],
      armCode: parts[17],
      disarmEn: parts[18],
      disarmCode: parts[19],
      cms1: parts[20],
      cms2: parts[21],
      failover: parts[22],
      pendingQueue: parts[23],
      sms: parts[24],
      call: parts[25],
      alarmLog: parts[26],
      // parts[27] is EVENT_LOG. Per spec it is never populated from a read
      // response and has no UI toggle, so it is intentionally not stored.
      outputEn: parts[28],
      outputMapping: parts[29],
      outputControlMode: parts[30],
      pulseDuration: parts[31],
      audioCallEn: parts[32],
      audioCallFile: parts[33],
      announceEn: parts[34],
      announceFile: parts[35],
      announceCount: parts[36],
      teleNoMapping: teleNoMapping,
    );
  }

  InputSettings copyWith({String? name, String? enabled}) {
    return InputSettings(
      imei: imei,
      productId: productId,
      inputOfProduct: inputOfProduct,
      inputPacketId: inputPacketId,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      zoneType: zoneType,
      sensorType: sensorType,
      eventId: eventId,
      alertEn: alertEn,
      alertCode: alertCode,
      restoralEn: restoralEn,
      restoralCode: restoralCode,
      armEn: armEn,
      armCode: armCode,
      disarmEn: disarmEn,
      disarmCode: disarmCode,
      cms1: cms1,
      cms2: cms2,
      failover: failover,
      pendingQueue: pendingQueue,
      sms: sms,
      call: call,
      alarmLog: alarmLog,
      outputEn: outputEn,
      outputMapping: outputMapping,
      outputControlMode: outputControlMode,
      pulseDuration: pulseDuration,
      audioCallEn: audioCallEn,
      audioCallFile: audioCallFile,
      announceEn: announceEn,
      announceFile: announceFile,
      announceCount: announceCount,
      teleNoMapping: teleNoMapping,
    );
  }

  /// Builds the packet-010 Write Request payload for this record.
  /// EVENT_LOG is always sent as "0" (disabled) — see field note above.
  String buildWriteRequest({required String passcode}) {
    final passcodePadded = passcode.padLeft(6, '0');
    final fields = [
      enabled,
      name,
      zoneType,
      sensorType,
      eventId,
      alertEn,
      alertCode,
      restoralEn,
      restoralCode,
      armEn,
      armCode,
      disarmEn,
      disarmCode,
      cms1,
      cms2,
      failover,
      pendingQueue,
      sms,
      call,
      alarmLog,
      '0', // EVENT_LOG
      outputEn,
      outputMapping,
      outputControlMode,
      pulseDuration,
      audioCallEn,
      audioCallFile,
      announceEn,
      announceFile,
      announceCount,
      teleNoMapping,
    ];

    return 'ST*$imei\$$passcodePadded\$02\$010\$$inputOfProduct\$$inputPacketId\$'
        '${fields.join('\$')}$_endMarker';
  }
}
