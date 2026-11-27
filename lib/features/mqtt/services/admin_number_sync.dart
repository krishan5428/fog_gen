import 'dart:async';

import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/core/logging/app_logger.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_commands.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_service.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';

/// Result of pushing a new admin number to a 4GCOM panel.
class AdminWriteResult {
  final bool isSuccess;

  /// Human-readable reason when [isSuccess] is false.
  final String? failureReason;

  const AdminWriteResult.success() : isSuccess = true, failureReason = null;

  const AdminWriteResult.failure(this.failureReason) : isSuccess = false;
}

/// Keeps a 4GCOM panel's admin number (Telephone Settings slot 0, packet
/// 008) and the server's `admin_mobile_number` in sync.
///
/// The panel is the source of truth — it is the number the panel actually
/// calls/SMSes on an alarm; the server copy is display-only for G4 panels.
/// So every change goes panel first, and the server is only updated once
/// the panel has confirmed it. Both places that can edit the admin number
/// (Device Details and Telephone Settings) go through this class.
class AdminNumberSync {
  AdminNumberSync._();

  static const int slotCount = 11; // Admin + Tel. No. 1-10

  /// What this session last saved to the server per panel (pnlId). Screens
  /// hold PanelData snapshots from when they were opened, so this stops a
  /// stale snapshot from re-triggering the same server update.
  static final Map<int, String> _lastSyncedToServer = {};

  /// The admin number the server is believed to hold for [panel].
  static String knownServerAdmin(PanelData panel) =>
      _lastSyncedToServer[panel.pnlId] ?? panel.adminMobileNumber.trim();

  /// The 11 raw `ABILITY#CC#NUMBER` entries from a packet-008 read
  /// response, or null if the frame is malformed.
  static List<String>? parseSlots(String response) {
    final parts = response.trim().split('\$');
    if (parts.length < 5 + slotCount) return null;
    return [
      for (int i = 0; i < slotCount; i++) parts[i + 5].replaceAll('*ED', ''),
    ];
  }

  /// The number in a raw slot entry ("" when the slot is empty).
  static String numberOf(String slot) {
    final sub = slot.split('#');
    if (sub.length < 3) return "";
    final number = sub[2].trim();
    return number == "0" ? "" : number;
  }

  /// Rewrites a raw slot read from the panel into a form the panel accepts
  /// on write (same rules as the Telephone Settings screen): the panel
  /// echoes "-" for a blank country code but rejects it on write, and an
  /// empty code must go out as the literal "NO CODE".
  static String _normalizeSlotForWrite(String slot) {
    final sub = slot.split('#');
    final ability = sub.isNotEmpty && sub[0].isNotEmpty ? sub[0] : "0";
    var cc = sub.length > 1 ? sub[1].trim() : "+91";
    final number = sub.length > 2 ? sub[2].trim() : "0";
    if (cc == "-") {
      cc = "+91";
    } else if (cc.isEmpty) {
      cc = "NO CODE";
    }
    if (number.isEmpty || number == "0") return "0#$cc#0";
    return "$ability#$cc#$number";
  }

  /// Slot 0 with [adminNumber], keeping the panel's existing alert mode
  /// (SMS / Call / SMS & Call) and country code where they're usable.
  static String _adminSlot(String current, String adminNumber) {
    final sub = current.split('#');
    final ability = sub.isNotEmpty && const {"2", "3", "4"}.contains(sub[0])
        ? sub[0]
        : "4";
    var cc = sub.length > 1 ? sub[1].trim() : "";
    if (cc.isEmpty || cc == "-" || cc == "NO CODE") cc = "+91";
    return "$ability#$cc#$adminNumber";
  }

  /// Publishes via [send] and waits for the panel's packet-008 write ack.
  /// Subscribes before sending so a fast ack can't be missed. Returns null
  /// when no definitive ack arrived within [timeout].
  static Future<bool?> sendAndAwaitWriteAck({
    required MqttRepository mqttRepository,
    required String imei,
    required Future<bool> Function() send,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final completer = Completer<bool?>();
    final sub = mqttRepository.messageStream.listen((response) {
      final parts = response.trim().split('\$');
      if (parts.length < 5 || parts[0] != "ST*$imei") return;
      if (parts[2] != "04" || !parts[4].startsWith("008")) return;

      // 01/02 = success, 04 = processing (keep waiting), else failure.
      final status = parts[3];
      if (status == "01" || status == "02") {
        if (!completer.isCompleted) completer.complete(true);
      } else if (status != "04") {
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    try {
      final sent = await send();
      if (!sent) return false;
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  /// Sets slot 0 (Admin) on the panel to [adminNumber] without touching
  /// Tel. No. 1-10: reads the current list, replaces only the admin slot,
  /// writes it back, waits for the ack, then re-reads to confirm. [fourGRepository]
  /// must already be connected and handshaken to the panel.
  static Future<AdminWriteResult> writeToPanel({
    required FourGRepository fourGRepository,
    required String imei,
    required String passcode,
    required String adminNumber,
  }) async {
    final wirePasscode = FourGMqttCommands.wirePasscode(passcode);

    final readBefore = await fourGRepository.readTelephoneSettings(
      imei: imei,
      passcode: wirePasscode,
    );
    final slots = readBefore == null ? null : parseSlots(readBefore);
    if (slots == null) {
      return const AdminWriteResult.failure(
        "Could not read the device's telephone numbers",
      );
    }

    for (int i = 1; i < slotCount; i++) {
      if (numberOf(slots[i]) == adminNumber) {
        return AdminWriteResult.failure(
          "This number is already set as Tel. No. "
          "${i.toString().padLeft(2, '0')} on the device",
        );
      }
    }

    final updated = [
      _adminSlot(slots[0], adminNumber),
      for (int i = 1; i < slotCount; i++) _normalizeSlotForWrite(slots[i]),
    ];
    AppLogger.d("ADMIN SYNC | writing slot 0 = ${updated[0]}");

    final mqttService = fourGRepository.mqttService;
    final ack = await sendAndAwaitWriteAck(
      mqttRepository: mqttService.mqttRepository,
      imei: imei,
      send: () => fourGRepository.assignAdminNumbers(
        imei: imei,
        passcode: wirePasscode,
        formattedNumbers: updated,
      ),
    );
    if (ack == false) {
      return const AdminWriteResult.failure("Device rejected the update");
    }

    // Confirm by reading back — also covers an ack that never arrived.
    final readAfter = await fourGRepository.readTelephoneSettings(
      imei: imei,
      passcode: wirePasscode,
    );
    final after = readAfter == null ? null : parseSlots(readAfter);
    if (after != null && numberOf(after[0]) == adminNumber) {
      return const AdminWriteResult.success();
    }
    return const AdminWriteResult.failure(
      "Device did not confirm the new admin number",
    );
  }

  /// Device Details path: opens a short-lived connection of its own (no
  /// dashboard session is open there), writes the admin number, and closes
  /// the connection again whatever the outcome.
  static Future<AdminWriteResult> connectAndWriteToPanel({
    required String imei,
    required String passcode,
    required String adminNumber,
  }) async {
    final mqttRepository = MqttRepository();
    final fourGRepository = FourGRepository(FourGMqttService(mqttRepository));
    var connected = false;
    try {
      try {
        // Longer than the service's own 20s handshake timeout, so the
        // handshake always settles (and cleans up) before we dispose.
        connected = await fourGRepository
            .connectPanel(imei: imei, passcode: passcode)
            .timeout(const Duration(seconds: 25), onTimeout: () => false);
      } catch (e) {
        AppLogger.d("ADMIN SYNC | connect failed: $e");
        connected = false;
      }
      if (!connected) {
        return const AdminWriteResult.failure("Device not reachable");
      }

      return await writeToPanel(
        fourGRepository: fourGRepository,
        imei: imei,
        passcode: passcode,
        adminNumber: adminNumber,
      );
    } catch (e) {
      AppLogger.d("ADMIN SYNC | write failed: $e");
      return const AdminWriteResult.failure("Something went wrong");
    } finally {
      if (connected) {
        try {
          await fourGRepository.disconnectPanel(imei: imei, passcode: passcode);
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (_) {}
      }
      mqttRepository.disconnect();
      mqttRepository.dispose();
    }
  }

  /// Saves [adminNumber] as the panel's server-side `admin_mobile_number`
  /// (offline-first: queued and retried if the network is down) and
  /// updates the cached panel list. No-op if the server already has it.
  static void syncToServer({
    required PanelCubit panelCubit,
    required PanelData panel,
    required String adminNumber,
  }) {
    if (panel.usrId.isEmpty || panel.pnlId <= 0) return;
    if (adminNumber == knownServerAdmin(panel)) return;

    AppLogger.d(
      "ADMIN SYNC | server ${knownServerAdmin(panel)} -> $adminNumber "
      "(pnl ${panel.pnlId})",
    );
    _lastSyncedToServer[panel.pnlId] = adminNumber;
    panelCubit.updatePanelDataList(
      userId: panel.usrId,
      panelId: panel.pnlId,
      keys: const ['admin_mobile_number'],
      values: [adminNumber],
    );
  }

  /// Records that the server now holds [adminNumber] for [panel] (e.g. when
  /// the caller saved it itself as part of a larger update).
  static void markSyncedToServer(PanelData panel, String adminNumber) {
    _lastSyncedToServer[panel.pnlId] = adminNumber;
  }
}
