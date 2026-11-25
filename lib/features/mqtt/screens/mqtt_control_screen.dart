// ignore_for_file: deprecated_member_use, unused_element, unused_field, unused_local_variable
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:flutter/material.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_service.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_parser.dart';
import 'package:fog_gen_new/features/mqtt/services/fourg_mqtt_commands.dart';
import 'package:fog_gen_new/core/repo/mqtt_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/presentation/screens/logs/logs_screen.dart';
import 'package:fog_gen_new/features/mqtt/screens/fourg_mqtt_settings_screen.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:logger/logger.dart';
import 'package:toastification/toastification.dart';

class MqttControlScreen extends StatefulWidget {
  final String panelName;
  final String panelId;
  final String imei;
  final String passcode;
  final String siteName;
  final PanelData? panelData;

  const MqttControlScreen({
    super.key,
    required this.panelName,
    required this.panelId,
    required this.imei,
    required this.passcode,
    required this.siteName,
    this.panelData,
  });

  @override
  State<MqttControlScreen> createState() => _MqttControlScreenState();
}

class _MqttControlScreenState extends State<MqttControlScreen>
    with WidgetsBindingObserver {
  final _logger = Logger();
  Timer? _timer;
  Timer? dashboardTimer;
  Timer? _connectionTimeoutTimer;
  Timer? _refreshTimeoutTimer;
  Timer? _settingsLockTimer;
  Timer? _commandTimeoutTimer;
  Timer? _outputOffTimer;
  int? _pendingOffOutput;
  int? _lastSentOutput;
  bool _outputsSyncing = false;
  final bool _isSettingsLocked = false;
  late DateTime _currentTime;
  late FourGRepository fourGRepository;
  bool _isConnected = false;
  bool _isConnecting = true;
  bool _connectionFailed = false;
  bool _hasDashboardData = false;
  bool _isRefreshing = false;
  bool _cleanupDone = false;
  int _connectAttemptId = 0;
  // True from a successful handshake until the user disconnects or leaves —
  // i.e. while a dropped link should be recovered automatically.
  bool _wantConnected = false;
  bool _isRecovering = false;
  int _recoveryId = 0;
  // Shown as RECONNECTING (not DISCONNECTED) while the session is restored
  // in the background after minimising or a dropped link.
  bool _isReconnecting = false;
  bool _wasBackgrounded = false;
  DateTime? _backgroundedAt;
  Timer? _backgroundTimer;
  // Short app switches keep the link and only re-verify on return; longer
  // ones release it and reconnect from scratch.
  static const _backgroundGrace = Duration(seconds: 30);
  bool panicTriggered = false;
  String lastResponse = '';
  String? _lastSentCommand;
  StreamSubscription? mqttSub;
  StreamSubscription? _connectionStatusSub;
  late MqttRepository mqttRepository;
  String signalStatus = "NO SIGNAL";
  int signalValue = 0;
  int signalPercentage = 0;
  String mainsStatus = "MAINS ON";
  String systemStatus = "NORMAL";
  String batteryPercent = "100";

  List<String> zoneStatus = ["NORMAL", "NORMAL", "NORMAL", "NORMAL"];

  List<String> zoneNames = ["Zone 1", "Zone 2", "Zone 3", "Zone 4"];

  bool get _isCommunicatorOrDialer {
    final panelTypeUpper = widget.panelData?.panelType.toUpperCase() ?? "";
    final nameUpper = widget.panelName.toUpperCase();
    return panelTypeUpper == 'FIRE COMMUNICATOR' ||
        panelTypeUpper == 'FIRE DIALERS' ||
        nameUpper.contains('FIRE COMMUNICATOR') ||
        nameUpper.contains('FIRE DIALERS');
  }

  IconData getSignalIcon() {
    switch (signalValue) {
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 3:
        return Icons.signal_cellular_alt;
      case 4:
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_connected_no_internet_0_bar;
    }
  }

  void _handleMqttResponse(String response) {
    try {
      _logger.d("FULL MQTT RESPONSE => $response");
      final parts = response.split('\$');
      _logger.d(
        "RAW RESPONSE TYPE => ${parts.length > 4 ? parts[4] : 'UNKNOWN'}",
      );

      if (parts.length > 4) {
        _logger.d("PACKET ID => ${parts[4]}");
      }
      for (int i = 0; i < parts.length; i++) {
        _logger.d("PART[$i] => ${parts[i]}");
      }

      _logger.d("PARSING RESPONSE => $parts");

      // Dashboard Response
      if (parts.length >= 6 &&
          parts[2] == "03" &&
          parts[3] == "01" &&
          parts[4] == "001") {
        String rawSignalBars = "0";
        String rawPowerStatus = "0";
        String rawBatteryStatus = "0";
        String rawPanicState = "0";
        String rawSecurityState = "5";

        String rawSignalPct = "0";

        // Check if status fields are concatenated in parts[5] (as documented)
        if (parts[5].length >= 8 && !parts[5].contains('\$')) {
          final statusStr = parts[5];
          rawSignalBars = statusStr.substring(0, 1);
          if (statusStr.length >= 4) {
            rawSignalPct = statusStr.substring(1, 4);
          }
          // networkMode is statusStr.substring(4, 5)
          // deviceMode is statusStr.substring(5, 6)
          rawPowerStatus = statusStr.substring(6, 7);
          rawBatteryStatus = statusStr.substring(7, 8);
          rawPanicState = statusStr.substring(8, 9);
          if (statusStr.length > 9) {
            rawSecurityState = statusStr.substring(9, 10);
          }
        } else {
          // Fallback to original dollar-separated parsing (based on document Section 2 indices)
          rawSignalBars = parts[5];
          rawSignalPct = parts.length > 6 ? parts[6] : "0";
          rawPowerStatus = parts.length > 9 ? parts[9] : "0";
          rawBatteryStatus = parts.length > 10 ? parts[10] : "0";
          rawPanicState = parts.length > 11 ? parts[11] : "0";
          rawSecurityState = parts.length > 12 ? parts[12] : "5";
        }

        signalValue = int.tryParse(rawSignalBars) ?? 0;
        signalPercentage = int.tryParse(rawSignalPct) ?? 0;

        _logger.d("SIGNAL BARS => $rawSignalBars");
        _logger.d("BATTERY STATUS => $rawBatteryStatus");
        _logger.d("POWER STATUS => $rawPowerStatus");
        _logger.d("PANIC STATE => $rawPanicState");
        _logger.d("SECURITY STATE => $rawSecurityState");

        _refreshTimeoutTimer?.cancel();

        setState(() {
          _hasDashboardData = true;
          _isConnected = true;
          _isConnecting = false;
          _isRefreshing = false;
          _connectionFailed = false;
          switch (signalValue.toString()) {
            case "0":
              signalStatus = "NO SIGNAL";
              break;
            case "1":
              signalStatus = "MARGINAL";
              break;
            case "2":
              signalStatus = "OK";
              break;
            case "3":
              signalStatus = "GOOD";
              break;
            case "4":
              signalStatus = "EXCELLENT";
              break;
            default:
              signalStatus = "NO SIGNAL";
          }

          final panelTypeUpper =
              widget.panelData?.panelType.toUpperCase() ?? "";
          final nameUpper = widget.panelName.toUpperCase();
          final isCommunicatorType =
              panelTypeUpper == 'FIRE COMMUNICATOR' ||
              panelTypeUpper == 'FIRE DIALERS' ||
              nameUpper.contains('FIRE COMMUNICATOR') ||
              nameUpper.contains('FIRE DIALERS');
          _logger.d(
            "DEBUG MAINS INVERSION: panelTypeUpper='$panelTypeUpper', panelName='$nameUpper', isCommunicatorType=$isCommunicatorType, rawPowerStatus='$rawPowerStatus'",
          );
          mainsStatus =
              isCommunicatorType
                  ? (rawPowerStatus == "1" ? "MAINS ON" : "MAINS OFF")
                  : (rawPowerStatus == "0" ? "MAINS ON" : "MAINS OFF");

          // Battery Status: 0 = Normal (100%), 1 = Low
          batteryPercent = rawBatteryStatus == "1" ? "Low" : "100";

          if (!panicTriggered) {
            if (rawPanicState == "1") {
              systemStatus = "PANIC";
            } else if (rawSecurityState == "4") {
              systemStatus = "ARMED";
            } else if (rawSecurityState == "5") {
              systemStatus = "DISARMED";
            } else {
              systemStatus = "NORMAL";
            }
          }

          // Zone Parsing: Find zone status entry (starts with D| or contains '|')
          String? zoneData;
          for (final part in parts) {
            if (part.startsWith('D|') || part.contains('|')) {
              zoneData = part;
              break;
            }
          }

          if (zoneData != null) {
            if (zoneData.startsWith('D|')) {
              zoneData = zoneData.substring(2);
            }
            final zones = zoneData.split(';');
            // Per protocol (Section 2): only the first 4 parsed pairs are
            // Input 1-4 — position determines the slot, not the name text
            // (a renamed input can contain any characters).
            for (int i = 0; i < zones.length && i < zoneStatus.length; i++) {
              final zone = zones[i].trim();
              if (zone.isEmpty) continue;
              _logger.d("APP Zone ${i + 1} <-- $zone");

              final zoneParts = zone.split('|');
              if (zoneParts.length >= 2) {
                final status = zoneParts[0] == "1" ? "FIRE" : "NORMAL";
                final rawName = zoneParts[1].trim();

                zoneStatus[i] = status;
                if (rawName.isNotEmpty) {
                  zoneNames[i] = rawName;
                }
              }
            }
          }
        });

        _logger.d("ZONE1 => ${zoneStatus[0]}");
        _logger.d("ZONE2 => ${zoneStatus[1]}");
        _logger.d("ZONE3 => ${zoneStatus[2]}");
        _logger.d("ZONE4 => ${zoneStatus[3]}");

        _logger.d(
          "UPDATED VALUES | signalStatus => $signalStatus | "
          "mainsStatus => $mainsStatus | systemStatus => $systemStatus | "
          "zone1 => ${zoneStatus[0]}",
        );
      }

      // ARM RESPONSE
      if (response.contains(r'$04$01$001$04')) {
        setState(() {
          systemStatus = "ARMED";
        });
      }
      _logger.d("CONTROL RESPONSE => $response");

      // DISARM RESPONSE
      if (response.contains(r'$04$01$001$05')) {
        setState(() {
          systemStatus = "DISARMED";
        });
      }
      _logger.d("CONTROL RESPONSE => $response");

      // Dashboard command acknowledgment (write ack, error frame, or a
      // read-shaped confirmation from some firmware)
      final ackParts = response.trim().split('\$');
      final isOtherOutputAck =
          ackParts.length > 5 &&
          ackParts[4] == "012" &&
          ackParts[5].replaceAll('*ED', '') != "08$_lastSentOutput";
      if (_lastSentCommand != null && !isOtherOutputAck) {
        final result = FourGMqttParser.parseCommandResult(
          response,
          widget.imei,
        );
        if (result != null) _onCommandResult(result);
      }
    } catch (e) {
      _logger.e("PARSE ERROR => $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    mqttRepository = MqttRepository();

    fourGRepository = FourGRepository(FourGMqttService(mqttRepository));

    mqttSub = mqttRepository.messageStream.listen((message) {
      _logger.d("MQTT SCREEN RESPONSE: $message");

      setState(() {
        lastResponse = message;
      });
      _handleMqttResponse(message);
    });

    // Catches a mid-session broker drop, not just a timed-out request —
    // including the OS cutting the socket while the app is minimised.
    _connectionStatusSub = mqttRepository.connectionStatusStream.listen((
      connected,
    ) {
      if (connected ||
          !mounted ||
          !_wantConnected ||
          _isConnecting ||
          _isRecovering) {
        return;
      }
      if (_wasBackgrounded) {
        // The resume handler recovers it — the OS usually blocks network
        // until then anyway.
        setState(() {
          _isConnected = false;
          _isReconnecting = true;
          _isRefreshing = false;
        });
        return;
      }
      _recoverSession(forceReconnect: true);
    });

    _connectPanel();

    _currentTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _sendDisconnectAndCleanup() async {
    if (_cleanupDone) return;
    _cleanupDone = true;
    // Don't leave a pulsed output stuck ON when disconnecting mid-pulse.
    _flushPendingOutputOff();
    dashboardTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    final attemptId = _connectAttemptId;
    await fourGRepository.disconnectPanel(
      imei: widget.imei,
      passcode: widget.passcode,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    // A reconnect started meanwhile (e.g. app resumed) owns the link now.
    if (attemptId != _connectAttemptId) return;
    mqttRepository.disconnect();
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14.sp,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text(
                "YES, PROCEED",
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Exit Device Control?",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          content: Text(
            "Going back will disconnect your active session with the device. Are you sure you want to exit?",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14.sp,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, "disconnected");
              },
              child: const Text(
                "YES, EXIT",
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectPanel() async {
    _connectionTimeoutTimer?.cancel();
    final int attemptId = ++_connectAttemptId;
    _cleanupDone = false;
    setState(() {
      _isConnecting = true;
      _isConnected = false;
      _connectionFailed = false;
      _hasDashboardData = false;
      _isRefreshing = false;
      _isReconnecting = false;
    });

    // Kept as a fallback safety net beyond the service's own ~20s handshake
    // timeout (fourg_mqtt_service.dart), so it never preempts a real result.
    _connectionTimeoutTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && attemptId == _connectAttemptId && !_hasDashboardData) {
        setState(() {
          _isConnecting = false;
          _connectionFailed = true;
          _isConnected = false;
          _hasDashboardData = false;
        });
        _sendDisconnectAndCleanup();
        _showFeedback("Connection timeout");
      }
    });

    try {
      final success = await fourGRepository.connectPanel(
        imei: widget.imei,
        passcode: widget.passcode,
      );

      if (success && mounted && attemptId == _connectAttemptId) {
        _wantConnected = true;
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });

        await Future.delayed(const Duration(seconds: 1));

        if (mounted && _isConnected && attemptId == _connectAttemptId) {
          await _syncOutputs();
        }

        //--------- Polling -----------------------------------
        // dashboardTimer?.cancel();
        // dashboardTimer = Timer.periodic(
        //   const Duration(seconds: 5),
        //   (_) async {
        //     if (_isConnected) {
        //       await fourGRepository.readDashboard(
        //         imei: widget.imei,
        //         passcode: widget.passcode,
        //       );
        //     }
        //   },
        // );
      }
    } catch (e) {
      if (mounted && attemptId == _connectAttemptId) {
        _connectionTimeoutTimer?.cancel();
        setState(() {
          _isConnected = false;
          _isConnecting = false;
          _connectionFailed = true;
          _hasDashboardData = false;
        });
        _sendDisconnectAndCleanup();

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains("socketexception") ||
            errorStr.contains("failed host lookup") ||
            errorStr.contains("connection error") ||
            errorStr.contains("network")) {
          _showFeedback(
            "Network error: Please check your internet connection.",
          );
        } else if (errorStr.contains("password") ||
            errorStr.contains("handshake failed")) {
          _showFeedback(
            "Connection failed: Invalid device password or handshake failed.",
          );
        } else {
          _showFeedback("Connection error: $e");
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_wasBackgrounded) return;
      _wasBackgrounded = true;
      _backgroundedAt = DateTime.now();
      _abandonInFlightConnect();
      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(_backgroundGrace, _releaseForBackground);
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _backgroundTimer?.cancel();
      final away = DateTime.now().difference(_backgroundedAt!);
      // The OS may have frozen the app before the timer fired, so judge by
      // elapsed time too — never trust a link that sat idle past the grace.
      // A connect abandoned on the way out also left the link state
      // unknown, so start that one over from scratch as well.
      _recoverSession(
        forceReconnect: away >= _backgroundGrace || _isReconnecting,
      );
    }
  }

  /// A connect/reconnect still running when the app is minimised would keep
  /// trying while the OS blocks the network, fail, and greet the user with
  /// "Device Disconnected" on return — while also blocking resume from
  /// starting a fresh one. Cancel it here; resume starts over.
  void _abandonInFlightConnect() {
    if (!_isRecovering && !_isConnecting) return;
    _logger.i("Minimised mid-connect — abandoning attempt, resume retries");
    _recoveryId++; // stops the running _recoverSession at its next step
    _connectAttemptId++; // its in-flight handshake result is ignored
    _isRecovering = false;
    _connectionTimeoutTimer?.cancel();
    // A first connect the user started counts as wanting a session too.
    _wantConnected = true;
    setState(() {
      _isConnecting = false;
      _isConnected = false;
      _isRefreshing = false;
      _isReconnecting = true;
      _connectionFailed = false;
    });
  }

  /// Drops the link after the app has been in the background past the
  /// grace period. [_wantConnected] stays true so resume reconnects, and the
  /// last dashboard stays on screen marked RECONNECTING until it does.
  void _releaseForBackground() {
    if (!mounted || !_wasBackgrounded || !_wantConnected) return;
    _logger.i("Backgrounded past grace period — releasing MQTT link");
    _connectAttemptId++; // ignore any connect still in flight
    _connectionTimeoutTimer?.cancel();
    _refreshTimeoutTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    _lastSentCommand = null;
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _isRefreshing = false;
      _isReconnecting = true;
      _connectionFailed = false;
    });
    _sendDisconnectAndCleanup();
  }

  /// Brings the session back after the app was minimised or the link
  /// dropped, without presenting it as a disconnect. A link that is still up
  /// is verified silently with a real round trip (the panel may have stopped
  /// answering); otherwise, or on [forceReconnect], it reconnects with a
  /// fresh handshake. Only a failed reconnect shows the disconnected state.
  Future<void> _recoverSession({bool forceReconnect = false}) async {
    if (!mounted || !_wantConnected || _isConnecting || _isRecovering) return;
    final recoveryId = ++_recoveryId;
    // False once _abandonInFlightConnect (or a newer recovery) took over.
    bool isCurrent() => recoveryId == _recoveryId;
    _isRecovering = true;
    try {
      if (!forceReconnect &&
          mqttRepository.isConnected &&
          await _panelResponds()) {
        if (mounted && isCurrent() && _isReconnecting) {
          setState(() => _isReconnecting = false);
        }
        return;
      }
      if (!mounted || !_wantConnected || !isCurrent()) return;

      setState(() {
        _isReconnecting = true;
        _isConnected = false;
        _isRefreshing = false;
        _connectionFailed = false;
      });

      // Network is often not up yet in the first moment after the OS
      // unfreezes the app, so allow one retry before giving up.
      var ok = await _reconnectSilently();
      if (!ok && mounted && _wantConnected && isCurrent()) {
        await Future.delayed(const Duration(seconds: 2));
        if (isCurrent()) ok = await _reconnectSilently();
      }

      // Abandoned while minimised — resume owns the session now.
      if (!isCurrent()) return;

      if (!mounted || !_wantConnected) {
        // Screen closed mid-reconnect — don't leave the new link open.
        if (ok) mqttRepository.disconnect();
        return;
      }

      if (ok) {
        setState(() {
          _isReconnecting = false;
          _isConnected = true;
          _connectionFailed = false;
        });
      } else {
        setState(() {
          _isReconnecting = false;
          _isConnected = false;
          _hasDashboardData = false;
          _connectionFailed = true;
        });
        _sendDisconnectAndCleanup();
        _showFeedback("Reconnect failed: device not reachable");
      }
    } finally {
      if (isCurrent()) _isRecovering = false;
    }
  }

  /// Reconnect + handshake + dashboard read, without touching the on-screen
  /// state the way [_connectPanel] does. True once the panel has answered.
  Future<bool> _reconnectSilently() async {
    final attemptId = ++_connectAttemptId;
    _cleanupDone = false;
    _connectionTimeoutTimer?.cancel();
    try {
      final connected = await fourGRepository.connectPanel(
        imei: widget.imei,
        passcode: widget.passcode,
      );
      if (!connected || attemptId != _connectAttemptId) return false;

      await Future.delayed(const Duration(seconds: 1));
      final summary = await fourGRepository.readDashboardInputSummary(
        imei: widget.imei,
        passcode: widget.passcode,
      );
      return summary != null && attemptId == _connectAttemptId;
    } catch (e) {
      _logger.w("SILENT RECONNECT FAILED => $e");
      return false;
    }
  }

  bool _checkConnected() {
    if (_isConnected) return true;
    _showFeedback(
      _isReconnecting
          ? "Reconnecting to device, please wait..."
          : "Device not connected",
    );
    return false;
  }

  /// Re-sends the connect packet (the panel session may have lapsed while
  /// idle) and waits for a dashboard reply. The reply also reaches
  /// [_handleMqttResponse], which refreshes the screen.
  Future<bool> _panelResponds() async {
    try {
      fourGRepository.sendSilentConnectPing(
        imei: widget.imei,
        passcode: widget.passcode,
      );
      await Future.delayed(const Duration(seconds: 1));
      final summary = await fourGRepository.readDashboardInputSummary(
        imei: widget.imei,
        passcode: widget.passcode,
      );
      return summary != null;
    } catch (e) {
      _logger.e("RESUME CHECK ERROR => $e");
      return false;
    }
  }

  String _commandLabel(String command) {
    switch (command) {
      case "EVACUATE":
        return "evacuation";
      case "ALARM_RESET":
        return "alarm reset";
      default:
        return "silence sounder";
    }
  }

  /// Sends a packet-001 dashboard command and tracks it until the panel
  /// answers (see [_onCommandResult]) or 10 s pass with no answer.
  Future<void> _sendDashboardCommand(
    String command,
    Future<bool> Function() send,
  ) async {
    _lastSentCommand = command;
    _commandTimeoutTimer?.cancel();
    _commandTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _lastSentCommand != command) return;
      _lastSentCommand = null;
      _showFeedback(
        "Device not responding - ${_commandLabel(command)} timeout",
      );
    });

    bool sent;
    try {
      sent = await send();
    } catch (e) {
      _logger.e("COMMAND PUBLISH ERROR => $e");
      sent = false;
    }
    if (!sent && _lastSentCommand == command) {
      _commandTimeoutTimer?.cancel();
      _lastSentCommand = null;
      _showFeedback("Failed to send ${_commandLabel(command)} command");
    }
  }

  /// Enables any disabled Output 1-3 on the panel; the dashboard read this
  /// does also refreshes the screen through the message listener.
  Future<void> _syncOutputs() async {
    setState(() => _outputsSyncing = true);
    try {
      final enabled = await fourGRepository.ensureOutputsEnabled(
        imei: widget.imei,
        passcode: widget.passcode,
      );
      if (enabled.isNotEmpty && mounted && _isConnected) {
        _showFeedback(
          "Enabled ${enabled.map((o) => 'Output $o').join(', ')} successfully",
        );
        await fourGRepository.readDashboard(
          imei: widget.imei,
          passcode: widget.passcode,
        );
      }
    } catch (e) {
      _logger.e("OUTPUT SYNC ERROR => $e");
    } finally {
      if (mounted) setState(() => _outputsSyncing = false);
    }
  }

  /// Switches [output] ON as [command], then back OFF after
  /// [FourGMqttCommands.outputPulseDuration]. Only the ON write is tracked
  /// for feedback; the OFF write is fire-and-forget.
  Future<void> _pulseOutput(String command, int output) async {
    if (_outputsSyncing) {
      _showFeedback("Preparing outputs, please try again in a moment");
      return;
    }

    // A previous pulse still holding its output ON gets switched OFF now.
    _flushPendingOutputOff();

    _lastSentOutput = output;
    await _sendDashboardCommand(command, () async {
      final sent = await fourGRepository.setOutput(
        imei: widget.imei,
        passcode: widget.passcode,
        output: output,
        on: true,
      );
      if (sent) {
        _pendingOffOutput = output;
        _outputOffTimer = Timer(
          FourGMqttCommands.outputPulseDuration,
          _flushPendingOutputOff,
        );
      }
      return sent;
    });
  }

  void _flushPendingOutputOff() {
    _outputOffTimer?.cancel();
    _outputOffTimer = null;
    final output = _pendingOffOutput;
    if (output == null) return;
    _pendingOffOutput = null;
    fourGRepository
        .setOutput(
          imei: widget.imei,
          passcode: widget.passcode,
          output: output,
          on: false,
        )
        .catchError((e) {
          _logger.e("OUTPUT $output OFF ERROR => $e");
          return false;
        });
    // Queued behind the OFF, so it shows the output's final state.
    if (!_cleanupDone) {
      fourGRepository
          .readDashboard(imei: widget.imei, passcode: widget.passcode)
          .catchError((e) => _logger.e("POST-OFF READ ERROR => $e"));
    }
  }

  void _onCommandResult(FourGCommandResult result) {
    final command = _lastSentCommand;
    if (command == null) return;
    _lastSentCommand = null;
    _commandTimeoutTimer?.cancel();

    if (!result.isSuccess) {
      final reason = result.failureReason;
      switch (command) {
        case "SOUNDER_OFF":
          _showFeedback("Failed to silence sounder: $reason");
          break;
        case "ALARM_RESET":
          _showFeedback("Failed to reset alarm: $reason");
          break;
        case "EVACUATE":
          _showFeedback("Failed to trigger evacuation: $reason");
          break;
      }
      return;
    }

    switch (command) {
      case "SOUNDER_OFF":
        _showFeedback("Sounder Silenced successfully");
        break;
      case "ALARM_RESET":
        // Let the follow-up dashboard read drive systemStatus again.
        setState(() => panicTriggered = false);
        _showFeedback("Alarm Reset successfully");
        break;
      case "EVACUATE":
        _showFeedback("Evacuation Alert active");
        break;
    }
  }

  Future<void> _onRefresh() async {
    if (!_isConnected || _isRefreshing) return;

    setState(() => _isRefreshing = true);

    _refreshTimeoutTimer?.cancel();
    _refreshTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isRefreshing) {
        // Drop stale data too, else the chain below falls into the old
        // dashboard branch instead of the disconnected one.
        setState(() {
          _isRefreshing = false;
          _hasDashboardData = false;
          _isConnected = false;
          _connectionFailed = true;
        });
        _showFeedback("Device not responding");
      }
    });

    try {
      await fourGRepository.readDashboard(
        imei: widget.imei,
        passcode: widget.passcode,
      );
    } catch (e) {
      _refreshTimeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _hasDashboardData = false;
          _isConnected = false;
          _connectionFailed = true;
        });
        _showFeedback("Failed to refresh");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wantConnected = false;
    _backgroundTimer?.cancel();
    _timer?.cancel();
    dashboardTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    _refreshTimeoutTimer?.cancel();
    _settingsLockTimer?.cancel();
    _commandTimeoutTimer?.cancel();
    mqttSub?.cancel();
    _connectionStatusSub?.cancel();
    _sendDisconnectAndCleanup();
    super.dispose();
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  void _showFeedback(String message) {
    if (!mounted) return;

    ToastificationType toastType = ToastificationType.info;
    String toastTitle = "Info";
    Color toastColor = AppColors.colorPrimary;
    IconData toastIcon = Icons.info_outline;

    final lowerMsg = message.toLowerCase();
    if (lowerMsg.contains("success") ||
        lowerMsg.contains("verified") ||
        lowerMsg.contains("saved")) {
      toastType = ToastificationType.success;
      toastTitle = "Success";
      toastColor = const Color(0xFF2ECC71);
      toastIcon = Icons.check_circle_outline;
    } else if (lowerMsg.contains("failed") ||
        lowerMsg.contains("timeout") ||
        lowerMsg.contains("error") ||
        lowerMsg.contains("not connected")) {
      toastType = ToastificationType.error;
      toastTitle = "Error";
      toastColor = const Color(0xFFD32F2F);
      toastIcon = Icons.error_outline;
    } else if (lowerMsg.contains("disconnect")) {
      toastType = ToastificationType.info;
      toastTitle = "Disconnected";
      toastColor = Colors.grey.shade700;
      toastIcon = Icons.link_off;
    } else if (lowerMsg.contains("reset")) {
      toastType = ToastificationType.success;
      toastTitle = "Reset Command";
      toastColor = const Color(0xFF27AE60);
      toastIcon = Icons.refresh;
    } else if (lowerMsg.contains("evacuation") || lowerMsg.contains("panic")) {
      toastType = ToastificationType.warning;
      toastTitle = "Evacuation";
      toastColor = const Color(0xFFD32F2F);
      toastIcon = Icons.warning_amber_outlined;
    } else if (lowerMsg.contains("sounder off") ||
        lowerMsg.contains("silence")) {
      toastType = ToastificationType.info;
      toastTitle = "Sounder Silenced";
      toastColor = const Color(0xFFF2994A);
      toastIcon = Icons.volume_off;
    }

    toastification.show(
      context: context,
      type: toastType,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        toastTitle,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          fontSize: 12.sp,
          color: Colors.white,
        ),
      ),
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: false,
      primaryColor: toastColor,
      foregroundColor: Colors.white,
      icon: Icon(toastIcon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format live time elements
    // final int hour = _currentTime.hour;
    // final bool isAm = hour < 12;
    // final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    // final String timeString =
    //     "${_formatTwoDigits(displayHour)}:${_formatTwoDigits(_currentTime.minute)}:${_formatTwoDigits(_currentTime.second)}";
    // final String dateString =
    //     "${_formatTwoDigits(_currentTime.day)}-${_formatTwoDigits(_currentTime.month)}-${_currentTime.year}";

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isConnected) {
          _showExitConfirmationDialog();
        } else {
          Navigator.pop(context, "disconnected");
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF3F3F3),
        appBar: CustomAppBar(
          pageName: "Dashboard",
          isFilter: false,
          isDash: false,
          onBack: () {
            if (_isConnected) {
              _showExitConfirmationDialog();
            } else {
              Navigator.pop(context, "disconnected");
            }
          },
          extraActions:
              _isConnected
                  ? [
                    IconButton(
                      icon:
                          _isRefreshing
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.refresh),
                      color: AppColors.colorPrimary,
                      onPressed: _isRefreshing ? null : _onRefresh,
                    ),
                  ]
                  : null,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Column(
            children: [
              /// SELECTED PANEL CARD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Circular Icon + Site Name & Panel Name Column
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.router,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.siteName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.panelName.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Middle Row: Buttons side-by-side
                    Row(
                      children: [
                        // Sounder Off Button
                        if (!_isCommunicatorOrDialer) ...[
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (!_checkConnected()) return;
                                _showConfirmationDialog(
                                  title: "Silence Sounder",
                                  message:
                                      "Are you sure you want to silence the sounder?",
                                  onConfirm: () async {
                                    await _pulseOutput("SOUNDER_OFF", 3);
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.volume_off,
                                      color: Color(0xFF616161),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "SOUNDER OFF",
                                      style: GoogleFonts.montserrat(
                                        color: const Color(0xFF616161),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5.sp,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Disconnect Button
                        Expanded(
                          child: InkWell(
                            onTap:
                                _isConnecting || _isReconnecting
                                    ? null
                                    : () async {
                                      if (_isConnected) {
                                        _showConfirmationDialog(
                                          title: "Disconnect Device",
                                          message:
                                              "Are you sure you want to disconnect from this device?",
                                          onConfirm: () async {
                                            _connectAttemptId++;
                                            _wantConnected = false;
                                            await _sendDisconnectAndCleanup();
                                            if (!mounted) return;
                                            setState(() {
                                              _isConnected = false;
                                              _isConnecting = false;
                                              _connectionFailed = true;
                                              _hasDashboardData = false;
                                            });
                                            _showFeedback(
                                              "Device Disconnected",
                                            );
                                          },
                                        );
                                      } else {
                                        _connectPanel();
                                      }
                                    },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    _isConnected
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF757575),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child:
                                  _isConnecting || _isReconnecting
                                      ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _isReconnecting
                                                ? "RECONNECTING..."
                                                : "CONNECTING...",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10.5.sp,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isConnected
                                                ? Icons.link_off
                                                : Icons.link,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isConnected
                                                ? "DISCONNECT"
                                                : "CONNECT",
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10.5.sp,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Bottom Row: Status Dot + Connection text
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulsingStatusDot(
                          isConnected: _isConnected,
                          color:
                              _isReconnecting ? const Color(0xFFF2994A) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isReconnecting
                              ? "RECONNECTING"
                              : _isConnected
                              ? "CONNECTED"
                              : "DISCONNECTED",
                          style: GoogleFonts.montserrat(
                            color:
                                _isReconnecting
                                    ? const Color(0xFFF2994A)
                                    : _isConnected
                                    ? const Color(0xFF2ECC71)
                                    : const Color(0xFFD32F2F),
                            fontWeight: FontWeight.w900,
                            fontSize: 11.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_isRefreshing) ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF27AE60),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Refreshing dashboard...",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_hasDashboardData) ...[
                const SizedBox(height: 10),

                /// SIGNAL STRENGTH & MAINS SIDE-BY-SIDE CARDS
                Row(
                  children: [
                    // Left: Signal Strength Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        height: 110,
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "SIGNAL STRENGTH",
                                    style: TextStyle(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sensors,
                                      size: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "$signalPercentage%",
                                      style: TextStyle(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Center(child: buildSignalBars()),
                            Center(
                              child: Text(
                                signalStatus,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      signalValue > 0
                                          ? const Color(0xFF27AE60)
                                          : const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: Mains Status Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        height: 110,
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "POWER",
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Centered colored glow shadow (blurRadius: 6.0, color opacity: 0.28)
                                  ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                      sigmaX: 3.0,
                                      sigmaY: 3.0,
                                    ),
                                    child: Icon(
                                      mainsStatus == "MAINS ON"
                                          ? Icons.power
                                          : Icons.battery_alert,
                                      color:
                                          mainsStatus == "MAINS ON"
                                              ? const Color(
                                                0xFF27AE60,
                                              ).withOpacity(0.28)
                                              : const Color(
                                                0xFFF2994A,
                                              ).withOpacity(0.28),
                                      size: 30,
                                    ),
                                  ),
                                  // 2. Offset black drop shadow (offset: (0, 2.0), blurRadius: 4.0, color opacity: 0.18)
                                  Transform.translate(
                                    offset: const Offset(0, 2.0),
                                    child: ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                        sigmaX: 2.0,
                                        sigmaY: 2.0,
                                      ),
                                      child: Icon(
                                        mainsStatus == "MAINS ON"
                                            ? Icons.power
                                            : Icons.battery_alert,
                                        color: Colors.black.withOpacity(0.18),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  // 3. Foreground main Icon
                                  Icon(
                                    mainsStatus == "MAINS ON"
                                        ? Icons.power
                                        : Icons.battery_alert,
                                    color:
                                        mainsStatus == "MAINS ON"
                                            ? const Color(0xFF27AE60)
                                            : const Color(0xFFF2994A),
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Text(
                                mainsStatus == "MAINS ON"
                                    ? "Mains ON"
                                    : "Mains OFF",
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      mainsStatus == "MAINS ON"
                                          ? const Color(0xFF27AE60)
                                          : const Color(0xFFF2994A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// ZONE STATUS CARD
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Zone Status",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildZoneCard(zoneNames[0], zoneStatus[0]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildZoneCard(zoneNames[1], zoneStatus[1]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildZoneCard(zoneNames[2], zoneStatus[2]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildZoneCard(zoneNames[3], zoneStatus[3]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                if (!_isCommunicatorOrDialer) ...[
                  /// OUTPUT CONTROLS CARD
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Output Controls",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (!_checkConnected()) return;
                                  _showConfirmationDialog(
                                    title: "Alarm Reset",
                                    message:
                                        "Are you sure you want to reset the alarm?",
                                    onConfirm: () async {
                                      await _pulseOutput("ALARM_RESET", 2);
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E824C),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    "ALARM RESET",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (!_checkConnected()) return;
                                  _showConfirmationDialog(
                                    title: "Trigger Evacuation",
                                    message:
                                        "WARNING: This will trigger the evacuation alarm on the device. Are you sure you want to proceed?",
                                    onConfirm: () async {
                                      await _pulseOutput("EVACUATE", 1);
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    "EVACUATE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                /// LOGS & SETTINGS BOTTOM BUTTONS (Outside Card)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!_checkConnected()) return;
                          final PanelData logsPanelData =
                              widget.panelData ??
                              PanelData(
                                pnlId: int.tryParse(widget.panelId) ?? 0,
                                usrId: "",
                                appType: "",
                                pnlAccNo: widget.panelId,
                                panelName: widget.panelName,
                                panelType: "",
                                siteName: widget.siteName,
                                siteAddress: "",
                                pnlMac: "",
                                pnlVer: "",
                                pnlLineNo: "",
                                pnlRcvrNo: "",
                                ipAdd: "",
                                portNo: "",
                                staticIp: "",
                                staticPort: "",
                                pass: widget.passcode,
                                adminCode: "",
                                cOn: "",
                                usr1: "",
                                usr2: "",
                                usr3: "",
                                usr4: "",
                                panelSimNumber: "",
                                adminMobileNumber: "",
                                mobileNumberSubId: "",
                                mobileNumber1: "",
                                mobileNumber2: "",
                                mobileNumber3: "",
                                mobileNumber4: "",
                                mobileNumber5: "",
                                mobileNumber6: "",
                                mobileNumber7: "",
                                mobileNumber8: "",
                                mobileNumber9: "",
                                mobileNumber10: "",
                                isIpPanel: false,
                                panelImei: widget.imei,
                                isIpGsmPanel: false,
                              );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      LogsScreen(panelData: logsPanelData),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1F24),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "LOGS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final isGuest =
                              widget.panelData?.shareStatus.toLowerCase() ==
                              'accepted';
                          if (isGuest) {
                            toastification.show(
                              context: context,
                              type: ToastificationType.warning,
                              style: ToastificationStyle.fillColored,
                              alignment: Alignment.bottomCenter,
                              title: Text(
                                'Permission Denied',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                ),
                              ),
                              description: Text(
                                'You do not have permission to view device settings. Please contact the owner/admin.',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                ),
                              ),
                              autoCloseDuration: const Duration(seconds: 4),
                            );
                            return;
                          }

                          if (!_checkConnected()) return;
                          final PanelData settingsPanelData =
                              widget.panelData ??
                              PanelData(
                                pnlId: int.tryParse(widget.panelId) ?? 0,
                                usrId: "",
                                appType: "",
                                pnlAccNo: widget.panelId,
                                panelName: widget.panelName,
                                panelType: "",
                                siteName: widget.siteName,
                                siteAddress: "",
                                pnlMac: "",
                                pnlVer: "",
                                pnlLineNo: "",
                                pnlRcvrNo: "",
                                ipAdd: "",
                                portNo: "",
                                staticIp: "",
                                staticPort: "",
                                pass: widget.passcode,
                                adminCode: "",
                                cOn: "",
                                usr1: "",
                                usr2: "",
                                usr3: "",
                                usr4: "",
                                panelSimNumber: "",
                                adminMobileNumber: "",
                                mobileNumberSubId: "",
                                mobileNumber1: "",
                                mobileNumber2: "",
                                mobileNumber3: "",
                                mobileNumber4: "",
                                mobileNumber5: "",
                                mobileNumber6: "",
                                mobileNumber7: "",
                                mobileNumber8: "",
                                mobileNumber9: "",
                                mobileNumber10: "",
                                isIpPanel: false,
                                panelImei: widget.imei,
                                isIpGsmPanel: false,
                              );

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FourGMqttSettingsScreen(
                                    panelData: settingsPanelData,
                                    fourGRepository: fourGRepository,
                                  ),
                            ),
                          );

                          // Settings (e.g. renaming a zone/input) writes changes
                          // straight to the panel, so pull fresh dashboard data
                          // on return instead of leaving stale values on screen.
                          if (mounted && _isConnected) {
                            _onRefresh();
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1F24),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "SETTINGS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else if (!_hasDashboardData && !_connectionFailed) ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF27AE60),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isConnected
                              ? "Fetching data from device..."
                              : "Connecting to device...",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_connectionFailed) ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          color: Color(0xFFD32F2F),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Device Disconnected",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Unable to establish connection with the device.",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // Widget buildSignalBars() {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     crossAxisAlignment: CrossAxisAlignment.end,
  //     children: List.generate(4, (index) {
  //       final heights = [12.0, 18.0, 24.0, 30.0];
  //
  //       return Container(
  //         margin: const EdgeInsets.only(right: 3.5),
  //         width: 7,
  //         height: heights[index],
  //         decoration: BoxDecoration(
  //           color: index < signalValue
  //               ? const Color(0xFF27AE60)
  //               : const Color(0xFFE0E0E0),
  //           borderRadius: BorderRadius.circular(3),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.08),
  //               offset: const Offset(0, 2),
  //               blurRadius: 4,
  //             ),
  //             if (index < signalValue)
  //               BoxShadow(
  //                 color: const Color(0xFF27AE60).withOpacity(0.18),
  //                 offset: Offset.zero,
  //                 blurRadius: 6,
  //                 spreadRadius: 0.5,
  //               ),
  //           ],
  //         ),
  //       );
  //     }),
  //   );
  // }

  Widget buildSignalBars() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final heights = [12.0, 18.0, 24.0, 30.0];

            return Container(
              margin: const EdgeInsets.only(right: 3.5),
              width: 7,
              height: heights[index],
              decoration: BoxDecoration(
                color:
                    index < signalValue
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                  if (index < signalValue)
                    BoxShadow(
                      color: const Color(0xFF27AE60).withOpacity(0.18),
                      offset: Offset.zero,
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                ],
              ),
            );
          }),
        ),

        if (signalValue == 0)
          Positioned(
            top: -6,
            right: -14,
            child: Icon(
              Icons.close_rounded,
              color: const Color(0xFFE53935),
              size: 18,
              shadows: [Shadow(color: Color(0x40E53935), blurRadius: 4)],
            ),
          ),
      ],
    );
  }

  Widget _buildZoneCard(String title, String status) {
    final bool isFire = status == "FIRE";

    // Split "Fire Zone X" into "Fire" and "Zone X"
    final parts = title.split(' ');
    final String line1 = parts.isNotEmpty ? parts[0] : "";
    final String line2 = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isFire ? const Color(0xFFFDF2F2) : const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFire ? const Color(0xFFFFCDD2) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Uniform zone name
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8), // Right: Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFire ? const Color(0xFFD32F2F) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isFire ? Colors.white : const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 9.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingStatusDot extends StatefulWidget {
  final bool isConnected;

  /// Overrides the connected/disconnected colour (e.g. while reconnecting).
  final Color? color;

  const PulsingStatusDot({super.key, required this.isConnected, this.color});

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        widget.color ??
        (widget.isConnected
            ? const Color(0xFF2ECC71)
            : const Color(0xFFE74C3C));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer breathing halo
              Container(
                width: 8 + (_controller.value * 12),
                height: 8 + (_controller.value * 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.35 * (1.0 - _controller.value)),
                ),
              ),
              // Inner glowing status dot
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
