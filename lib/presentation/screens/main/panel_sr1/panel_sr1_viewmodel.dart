import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:fog_gen_new/core/utils/packets.dart';

import '../../../../core/responses/socket_repository.dart';

enum PanelSR1ViewEvent {
  none,
  showAdminStatusUpdatedToast,
  showInputStatusUpdatedToast,
  showCommandFailedToast,
  showEvacuatePulseSuccessToast,
  showFoggerTriggerSuccessToast,
  showSounderOffSuccessToast,
  showSounderToggleSuccessToast,
  showZoneToggleSuccessToast,
  showDateTimeSyncSuccessToast,
  showConnectionLostWarning,
  showFoggerArmedToast,
  showFoggerDisarmedToast,
  showExhaustFanOnToast,
  showExhaustFanOffToast,
  showOutputStatusUpdatedToast,
  showInputPulseSuccessToast,
  showAlarmResetSuccessToast,
  showFoggerNotActiveToast,
  showConnectionTimeout,
}

class PanelSR1ViewModel extends ChangeNotifier {
  final SocketRepository _socketRepository;
  final log = Logger();

  // WATCHDOG: timestamp of last valid response received from panel
  DateTime _lastResponseTime = DateTime.now();

  Timer? _clockTimer;
  Timer? _fastPollingTimer;
  Timer? _normalPollingTimer;
  DateTime? _currentPanelTime;

  bool _isPanelStatusLoading = true;
  bool get isPanelStatusLoading => _isPanelStatusLoading;

  bool _isZoneStatusLoading = true;
  bool get isZoneStatusLoading => _isZoneStatusLoading;

  bool _isConnectionHealthy = true;
  bool get isConnectionHealthy => _isConnectionHealthy;

  bool _isSystemErrorDetected = false;
  bool get isSystemErrorDetected => _isSystemErrorDetected;

  String _date = "--/--/----";
  String get date => _date;

  String _time = "--:--:--";
  String get time => _time;

  bool _isAm = true;
  bool get isAm => _isAm;

  String _adminStatus = "DISARMED";
  String get adminStatus => _adminStatus;

  String _userStatus = "DISARMED";
  String get userStatus => _userStatus;

  String _outputSounderStatus = "OFF";
  String get outputSounderStatus => _outputSounderStatus;

  String _outputAuto1Status = "OFF";
  String get outputAuto1Status => _outputAuto1Status;

  String _outputAuto2Status = "OFF";
  String get outputAuto2Status => _outputAuto2Status;

  String _outputAuto3Status = "OFF";
  String get outputAuto3Status => _outputAuto3Status;

  final List<String> _inputStatuses = List.filled(5, "UNKNOWN");
  List<String> get inputStatuses => _inputStatuses;

  bool _isMainsOk = false;
  bool get isMainsOk => _isMainsOk;

  final bool _isFireFaultDetected = false;
  bool get isFireFaultDetected => _isFireFaultDetected;

  int _signalStrengthLevel = 0;
  int get signalStrengthLevel => _signalStrengthLevel;

  PanelSR1ViewEvent _event = PanelSR1ViewEvent.none;
  PanelSR1ViewEvent get event => _event;

  Map<String, dynamic>? _eventData;
  Map<String, dynamic>? get eventData => _eventData;

  bool _isDisposed = false;
  bool _isFastPolling = false;
  bool _isNormalPolling = false;

  PanelSR1ViewModel({required SocketRepository socketRepository})
    : _socketRepository = socketRepository {
    _requestInitialData();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    log.d("Disposing PanelSR1ViewModel and stopping all timers.");
    _isDisposed = true;
    _clockTimer?.cancel();
    _fastPollingTimer?.cancel();
    _normalPollingTimer?.cancel();
    super.dispose();
  }

  void _setEvent(PanelSR1ViewEvent event, {Map<String, dynamic>? data}) {
    _event = event;
    _eventData = data;
    notifyListeners();
  }

  void resetEvent() {
    _event = PanelSR1ViewEvent.none;
    _eventData = null;
  }

  Future<void> _requestInitialData() async {
    log.d("Requesting initial panel data");
    _isPanelStatusLoading = true;
    _isZoneStatusLoading = true;
    notifyListeners();

    try {
      // 1. Get User Status (009)
      final userStatusResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["009"]),
        isPriority: true,
      );
      if (_isDisposed) return;
      _processReadResponse(userStatusResponse);
      _isPanelStatusLoading = false;
      notifyListeners();

      // 2. Get Input Status (008)
      final inputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["008"]),
        isPriority: true,
      );
      if (_isDisposed) return;
      _processReadResponse(inputResponse);
      _isZoneStatusLoading = false;
      notifyListeners();

      // 3. Get Outputs (007)
      final outputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["007"]),
      );
      if (_isDisposed) return;
      _processReadResponse(outputResponse);

      // 4. Get Time (011)
      final timeResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["011"]),
      );
      if (_isDisposed) return;
      _processReadResponse(timeResponse);

      // 5. Get Signal (020)
      final signalResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["020"]),
      );
      if (_isDisposed) return;
      _processReadResponse(signalResponse);

      _startStatusPolling();
    } catch (e) {
      if (!_isDisposed) {
        log.e("Failed to get initial panel data: $e");
        _isPanelStatusLoading = false;
        _isZoneStatusLoading = false;
        _isConnectionHealthy = false;
        notifyListeners();
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    }
  }

  Future<void> _requestFastPollUpdate() async {
    if (_isDisposed || _isFastPolling) return;
    _isFastPolling = true;

    try {
      final inputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["008"]),
        isPriority: true,
      );
      if (_isDisposed) return;
      _processReadResponse(inputResponse);
    } catch (e) {
      if (!_isDisposed) {
        log.w("Fast poll (zone) failed: $e");
      }
    } finally {
      _isFastPolling = false;
    }
  }

  Future<void> _requestNormalPollUpdate() async {
    // log.v("NORMAL POLL REQUEST STARTED"); // Reduced log noise
    if (_isDisposed || _isNormalPolling) return;
    _isNormalPolling = true;

    try {
      final userStatusResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["009"]),
      );
      if (_isDisposed) return;
      _processReadResponse(userStatusResponse);

      final outputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["007"]),
      );
      if (_isDisposed) return;
      _processReadResponse(outputResponse);

      final signalResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["020"]),
      );
      if (_isDisposed) return;
      _processReadResponse(signalResponse);

      if (!_isConnectionHealthy) {
        _isConnectionHealthy = true;
        notifyListeners();
        log.i("Connection restored (detected in normal poll)");
      }
    } catch (e) {
      if (!_isDisposed) {
        log.w("Normal poll failed: $e");
        _isConnectionHealthy = false;
        notifyListeners();
      }
    } finally {
      _isNormalPolling = false;
    }
  }

  void _startStatusPolling() {
    log.i("STARTED STATUS POLLING");
    _fastPollingTimer?.cancel();
    _normalPollingTimer?.cancel();

    // Fast Polling (2s) for Zones
    _fastPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _requestFastPollUpdate();
    });

    // Normal Polling (5s) for System Status
    _normalPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final timeSinceLastResponse = DateTime.now().difference(
        _lastResponseTime,
      );

      // Watchdog Check (60 seconds timeout)
      if (timeSinceLastResponse.inSeconds > 60) {
        log.e("CRITICAL: No data received for > 60s. Triggering timeout.");
        timer.cancel();
        _fastPollingTimer?.cancel();
        _setEvent(PanelSR1ViewEvent.showConnectionTimeout);
        return;
      }

      if (_isNormalPolling) return; // Skip if busy

      _requestNormalPollUpdate();
    });
  }

  void _processReadResponse(String data) {
    if (_isDisposed) return;

    // Basic Validation
    final isValidPacket =
        data.startsWith("S*") &&
        data.endsWith("*E") &&
        (data.contains("007") ||
            data.contains("008") ||
            data.contains("009") ||
            data.contains("011") ||
            data.contains("020"));

    if (isValidPacket) {
      _lastResponseTime = DateTime.now(); // Reset Watchdog
      if (!_isConnectionHealthy) _isConnectionHealthy = true;
    } else {
      // Ignore random noise or partial packets
      return;
    }

    try {
      if (data.contains("009")) {
        final splitData = Packets.splitPacket(data);
        if (splitData.isNotEmpty) _updateUserStatus(splitData[0].split(''));
      } else if (data.contains("007")) {
        final splitData = Packets.splitOutputPacket(data);
        if (splitData.isNotEmpty) _updateOutputStatus(splitData);
      } else if (data.contains("011")) {
        final splitData = Packets.splitOutputPacket(data);
        if (splitData.isNotEmpty) _extractDateAndTime(splitData.join());
      } else if (data.contains("008")) {
        final splitData = Packets.splitPacket(data);
        if (splitData.isNotEmpty && splitData[0].length >= 4) {
          final statusString = splitData[0];

          _inputStatuses[0] = _getInputStatusDesc(statusString[0]);
          _inputStatuses[1] = _getInputStatusDesc(statusString[1]);
          _inputStatuses[2] = _getInputStatusDesc(statusString[2]);
          _inputStatuses[3] = _getInputStatusDesc(statusString[3]);

          if (statusString.length >= 5) {
            final systemErrorValue = statusString[4];
            _isSystemErrorDetected = systemErrorValue != '0';
          }

          if (statusString.length >= 6) {
            _isMainsOk = statusString[5] == '1' || statusString[5] == '9';
          }
        }
      } else if (data.contains("020")) {
        final splitData = Packets.splitPacket(data);
        if (splitData.isNotEmpty && splitData[0].length == 1) {
          final level = int.tryParse(splitData[0]) ?? 0;
          _signalStrengthLevel = level.clamp(0, 4);
        }
      }
      notifyListeners();
    } catch (e) {
      log.e("Error parsing read response: $e");
    }
  }

  Future<void> sendAutomationToggleCommand(int autoNumber, bool turnOn) async {
    try {
      final command = turnOn ? "1" : "0";
      log.i(
        "[Automation] Sending command → autoNumber=$autoNumber, command=$command",
      );

      final packet = Packets.getPacket(
        isReadPacket: false,
        args: ["007", "00$autoNumber", command],
      );

      final response = await _socketRepository.sendPacketSR1(
        packet,
        isPriority: true,
      );

      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        log.i("[Automation] ACK received.");

        if (autoNumber == 1) {
          _outputAuto1Status = turnOn ? "ON" : "OFF";
          _setEvent(
            turnOn
                ? PanelSR1ViewEvent.showFoggerArmedToast
                : PanelSR1ViewEvent.showFoggerDisarmedToast,
          );
        } else if (autoNumber == 3) {
          _outputAuto3Status = turnOn ? "ON" : "OFF";
          _setEvent(
            turnOn
                ? PanelSR1ViewEvent.showExhaustFanOnToast
                : PanelSR1ViewEvent.showExhaustFanOffToast,
          );
        }
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 250));

        await refreshOutputStatus();
        if (autoNumber == 1) await refreshInputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("[Automation] Exception: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendAutomationPulseCommand(int autoNumber) async {
    try {
      if (autoNumber == 2 && _outputAuto1Status != "ON") {
        log.w("Blocked Fogger Trigger: System not ARMED.");
        _setEvent(PanelSR1ViewEvent.showFoggerNotActiveToast);
        return;
      }

      const command = "3"; // Pulse
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(
          isReadPacket: false,
          args: ["007", "00$autoNumber", command],
        ),
        isPriority: true,
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        if (autoNumber == 1) {
          _setEvent(PanelSR1ViewEvent.showEvacuatePulseSuccessToast);
        } else if (autoNumber == 2) {
          _setEvent(PanelSR1ViewEvent.showFoggerTriggerSuccessToast);
          await sendSounderOnCommand();
        } else {
          _setEvent(PanelSR1ViewEvent.showOutputStatusUpdatedToast);
        }

        await Future.delayed(const Duration(milliseconds: 250));
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send automation pulse: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendInputPulseCommand(int inputNumber) async {
    try {
      if (inputNumber == 1 && _outputAuto1Status != "ON") {
        _setEvent(PanelSR1ViewEvent.showFoggerNotActiveToast);
        return;
      }

      const command = "3";
      final packetIndex = (inputNumber - 1).toString().padLeft(3, '0');

      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(
          isReadPacket: false,
          args: ["008", packetIndex, command],
        ),
        isPriority: true,
      );
      if (_isDisposed) return;

      if (response.contains("S*008#")) {
        _setEvent(
          PanelSR1ViewEvent.showInputPulseSuccessToast,
          data: {'inputNumber': inputNumber},
        );

        await Future.delayed(const Duration(milliseconds: 250));
        await refreshInputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send input pulse: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendSounderOffAckCommand() async {
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "2"]),
        isPriority: true,
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "ACK";
        _setEvent(PanelSR1ViewEvent.showSounderOffSuccessToast);
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 250));
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendSounderOnCommand() async {
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "1"]),
        isPriority: true,
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "ON";
        _setEvent(PanelSR1ViewEvent.showSounderToggleSuccessToast);
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 250));
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendAlarmResetCommand() async {
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "4"]),
        isPriority: true,
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "OFF";
        _setEvent(PanelSR1ViewEvent.showAlarmResetSuccessToast);
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 250));
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> refreshOutputStatus() async {
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["007"]),
      );
      if (!_isDisposed) _processReadResponse(response);
    } catch (e) {
      log.e("Failed to refresh output status: $e");
    }
  }

  Future<void> refreshInputStatus() async {
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["008"]),
        isPriority: true,
      );
      if (!_isDisposed) _processReadResponse(response);
    } catch (e) {
      log.e("Failed to refresh input status: $e");
    }
  }

  Future<void> syncDateTime() async {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    final formattedDateTime = "$hour$minute$second$day$month$year";

    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(
          isReadPacket: false,
          args: ["011", formattedDateTime],
        ),
      );
      if (_isDisposed) return;

      if (response.contains("S*011#0*E")) {
        _currentPanelTime = now;
        _startClock();
        _setEvent(PanelSR1ViewEvent.showDateTimeSyncSuccessToast);
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  String _getInputStatusDesc(String ch) {
    switch (ch) {
      case '0':
        return "NORMAL";
      case '1':
        return "ARM ALERT";
      case '2':
        return "AUTOMATION ALERT";
      case '3':
        return "DISARM ALERT";
      case '4':
        return "LONG OPEN";
      case '5':
        return "OUT OF SCHEDULE";
      case '6':
        return "NOT APPLICABLE";
      case '7':
        return "HOOTER ACK";
      case '8':
        return "IDLE";
      case '9':
        return "DISABLE";
      default:
        return "UNKNOWN";
    }
  }

  void _updateOutputStatus(List<String> strings) {
    if (strings.isEmpty || strings.length < 4) return;

    if (strings[0].length > 1) {
      final sounderState = strings[0][1];
      if (sounderState == '1') {
        _outputSounderStatus = "ON";
      } else if (sounderState == '2') {
        _outputSounderStatus = "ACK";
      } else {
        _outputSounderStatus = "OFF";
      }
    }

    _outputAuto1Status = (strings[1].length > 1 && strings[1][1] == '0')
        ? "OFF"
        : "ON";
    _outputAuto2Status = (strings[2].length > 1 && strings[2][1] == '0')
        ? "OFF"
        : "ON";
    _outputAuto3Status = (strings[3].length > 1 && strings[3][1] == '0')
        ? "OFF"
        : "ON";
  }

  void _updateUserStatus(List<String> chars) {
    if (chars.length >= 2) {
      _adminStatus = (chars[0] == '0') ? "ARMED" : "DISARMED";
      _userStatus = (chars[1] == '0') ? "ARMED" : "DISARMED";
    }
  }

  void _extractDateAndTime(String timestamp) {
    if (timestamp.length < 14) return;
    try {
      final hour = int.parse(timestamp.substring(0, 2));
      final minute = int.parse(timestamp.substring(2, 4));
      final second = int.parse(timestamp.substring(4, 6));
      final day = int.parse(timestamp.substring(6, 8));
      final month = int.parse(timestamp.substring(8, 10));
      final year = int.parse(timestamp.substring(10, 14));
      _currentPanelTime = DateTime(year, month, day, hour, minute, second);
      _startClock();
    } catch (e) {
      log.w("Error parsing date/time: $e");
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_currentPanelTime == null) {
        _currentPanelTime = DateTime.now();
      } else {
        _currentPanelTime = _currentPanelTime!.add(const Duration(seconds: 1));
      }

      final dt = _currentPanelTime!;
      _date =
          "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
      _time =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
      _isAm = dt.hour < 12;
      notifyListeners();
    });
  }
}
