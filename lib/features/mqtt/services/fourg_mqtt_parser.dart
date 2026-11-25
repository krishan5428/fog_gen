/// Result of a fast, single-round-trip read of every input's name and
/// enabled state off the packet-001 (Dashboard) summary. Positional index
/// matches Input 1..N — this is only ever used to pre-populate the Zone
/// Mapping browsing UI quickly; the full packet-010 record is always
/// re-read immediately before any write, since 001 doesn't carry every
/// field a write needs to echo back.
class DashboardInputSummary {
  final List<String> names;
  final List<bool> enabled;

  const DashboardInputSummary(this.names, this.enabled);
}

/// Outcome of a packet-001 dashboard command (Panic, Alarm Abort, Queue
/// Abort, Arm, Disarm) or packet-012 Output 1 command (Evacuate) as reported
/// by the panel.
class FourGCommandResult {
  final bool isSuccess;

  /// Human-readable reason when [isSuccess] is false.
  final String? failureReason;

  const FourGCommandResult.success() : isSuccess = true, failureReason = null;

  const FourGCommandResult.failure(this.failureReason) : isSuccess = false;
}

class FourGMqttParser {
  FourGMqttParser._();

  /// Packet-Type-00 error codes (panel rejected the request outright).
  static const Map<String, String> errorCodeMessages = {
    '01': 'Packet type error',
    '02': 'Unknown packet ID',
    '03': 'Wrong passcode',
    '04': 'Wrong IMEI',
    '05': 'Device engaged, try again',
    '06': 'Login required',
  };

  /// Classifies [payload] as the panel's answer to a pending dashboard
  /// command, or returns null when the frame isn't one (other packet IDs,
  /// a non-terminal "Processing" status, another device's IMEI). Mirrors
  /// the Securico 4GCOM dashboard:
  /// - Error Response (00): failure, reason from the error code.
  /// - Write Response (04) on 001/000/012: 01/02 success, 04 on 001 success
  ///   (non-terminal on 000/012), 00/03/99 failure.
  /// - Read Response (03$01) on 001/000: some firmware confirms a command
  ///   this way instead of a write ack, so it counts as success.
  static FourGCommandResult? parseCommandResult(String payload, String imei) {
    final parts = payload.trim().split('\$');
    if (parts.length < 4 || parts[0] != "ST*$imei") return null;

    String field(int i) => parts[i].replaceAll('*ED', '');
    final frameType = parts[2];

    if (frameType == "00") {
      final code = field(3);
      return FourGCommandResult.failure(
        errorCodeMessages[code] ?? 'Device error $code',
      );
    }

    if (parts.length < 5) return null;
    final packetId = field(4);
    if (packetId != "001" && packetId != "000" && packetId != "012") {
      return null;
    }

    if (frameType == "04") {
      switch (field(3)) {
        case "01":
        case "02":
          return const FourGCommandResult.success();
        case "04":
          return packetId == "001" ? const FourGCommandResult.success() : null;
        case "00":
          return const FourGCommandResult.failure('Rejected by device');
        case "03":
          return const FourGCommandResult.failure('Process failed');
        case "99":
          return const FourGCommandResult.failure('Data error');
        default:
          return null;
      }
    }

    // A 012 read response is an output-status read, not a command ack.
    if (frameType == "03" && field(3) == "01" && packetId != "012") {
      return const FourGCommandResult.success();
    }

    return null;
  }

  /// Status of Outputs 1..N from a packet-001 read response's OUTPUT_LIST
  /// (always the last field): "D" = Disabled, "0" = OFF, "1" = ON.
  static List<String>? parseDashboardOutputStates(String response) {
    final parts = response.trim().split('\$');
    if (parts.length < 7 ||
        parts[2] != "03" ||
        parts[3] != "01" ||
        parts[4] != "001" ||
        !parts.last.contains('|')) {
      return null;
    }

    final tokens = parts.last.replaceAll('*ED', '').split(RegExp(r'[|;]'));
    return [for (int i = 0; i + 1 < tokens.length; i += 2) tokens[i].trim()];
  }

  /// ENABLED field of a packet-011 Output Settings read response
  /// (parts[6], right after the echoed output number), or null when the
  /// frame isn't one.
  static bool? isOutputSettingsEnabled(String response) {
    final parts = response.trim().split('\$');
    if (parts.length < 7 ||
        parts[2] != "03" ||
        parts[3] != "01" ||
        parts[4] != "011") {
      return null;
    }
    return parts[6].replaceAll('*ED', '').trim() == "1";
  }

  static bool isHandshakeSuccess(String payload, String imei) {
    final parts = payload.split('\$');

    if (parts.length < 6) {
      return false;
    }

    // Per protocol: any value other than literal "01" is the firmware
    // version string and means the connect was accepted.
    return parts[0] == "ST*$imei" &&
        parts[2] == "03" &&
        parts[3] == "01" &&
        parts[4] == "000" &&
        parts[5] != "01";
  }

  static bool isHandshakeRejected(String payload, String imei) {
    final parts = payload.split('\$');

    if (parts.length < 6) {
      return false;
    }

    // Literal "01" in this position means the device rejected the connect.
    return parts[0] == "ST*$imei" &&
        parts[2] == "03" &&
        parts[3] == "01" &&
        parts[4] == "000" &&
        parts[5] == "01";
  }

  static bool isErrorResponse(String payload, String imei) {
    final parts = payload.split('\$');

    if (parts.length < 3) {
      return false;
    }

    // Frame type "00" is the generic Error Response (wrong passcode,
    // wrong IMEI, device engaged, etc).
    return parts[0] == "ST*$imei" && parts[2] == "00";
  }

  /// Extracts each input's current name and enabled state from a packet-001
  /// (Dashboard) read response, for a fast initial "which name is on this
  /// input" load — one round trip instead of reading each input's full
  /// packet-010 record individually. Per protocol (Section 2): only the
  /// first [zoneCount] parsed pairs are Input 1-N, and position (not name
  /// text) determines the slot. Input status "D" = Disabled; "0"/"1"
  /// (Normal/Alert) both mean enabled — see Section 2 Input status table.
  static DashboardInputSummary? parseDashboardInputSummary(
    String response, {
    int zoneCount = 4,
  }) {
    final parts = response.split('\$');
    if (parts.length < 6 ||
        parts[2] != "03" ||
        parts[3] != "01" ||
        parts[4] != "001") {
      return null;
    }

    String? zoneData;
    for (final part in parts) {
      if (part.startsWith('D|') || part.contains('|')) {
        zoneData = part;
        break;
      }
    }
    if (zoneData == null) return null;

    if (zoneData.startsWith('D|')) {
      zoneData = zoneData.substring(2);
    }

    final names = List<String>.generate(zoneCount, (i) => 'Input ${i + 1}');
    final enabled = List<bool>.filled(zoneCount, true);
    final zones = zoneData.split(';');

    for (int i = 0; i < zones.length && i < zoneCount; i++) {
      final zone = zones[i].trim();
      if (zone.isEmpty) continue;

      final zoneParts = zone.split('|');
      if (zoneParts.length < 2) continue;

      final status = zoneParts[0].trim();
      final rawName = zoneParts[1].trim();

      if (rawName.isNotEmpty) names[i] = rawName;
      enabled[i] = status != 'D';
    }

    return DashboardInputSummary(names, enabled);
  }
}
