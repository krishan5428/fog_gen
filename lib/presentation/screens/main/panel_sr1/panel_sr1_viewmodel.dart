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

  String _date = "_-_-__";
  String get date => _date;

  String _time = "_:_:_";
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
      final userStatusResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["009"]),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;
      _processReadResponse(userStatusResponse);
      _isPanelStatusLoading = false;
      notifyListeners();

      final inputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["008"]),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;
      _processReadResponse(inputResponse);
      _isZoneStatusLoading = false;
      notifyListeners();

      final outputResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["007"]),
      );
      if (_isDisposed) return;
      _processReadResponse(outputResponse);

      final timeResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["011"]),
      );
      if (_isDisposed) return;
      _processReadResponse(timeResponse);

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
        isPriority: true, // Priority implemented
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
    log.w("NORMAL POLL REQUEST STARTED");
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

    log.d("Starting 2-second FAST polling (Zone/Fire Status)");
    _fastPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _requestFastPollUpdate();
    });

    log.d("Starting 5-second NORMAL polling (Status/Signal)");
    _normalPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      log.w("TIMER TICK (5s)");

      if (_isDisposed) {
        log.e("Timer stopped because ViewModel disposed");
        timer.cancel();
        return;
      }

      final timeSinceLastResponse = DateTime.now().difference(
        _lastResponseTime,
      );
      log.w("WATCHDOG CHECK: ${timeSinceLastResponse.inSeconds}s elapsed");

      if (timeSinceLastResponse.inSeconds > 60) {
        log.e("CRITICAL: No data received for > 60s. Triggering timeout.");

        timer.cancel();
        _fastPollingTimer?.cancel();

        _setEvent(PanelSR1ViewEvent.showConnectionTimeout);
        return;
      }

      if (_isNormalPolling) {
        log.w("Normal poll busy — skipping");
        return;
      }

      _requestNormalPollUpdate();
    });
  }

  void _processReadResponse(String data) {
    log.e("PROCESS RESPONSE CALLED with data: '$data'");
    if (_isDisposed) return;

    log.i("RAW DATA RECEIVED: '$data'");
    final isValidPacket =
        data.startsWith("S*") &&
            data.endsWith("*E") &&
            (data.contains("007") ||
                data.contains("008") ||
                data.contains("009") ||
                data.contains("011") ||
                data.contains("020"));

    if (isValidPacket) {
      log.i("WATCHDOG RESET → Valid packet");
      _lastResponseTime = DateTime.now();

      if (!_isConnectionHealthy) {
        _isConnectionHealthy = true;
      }
    } else {
      log.w("WATCHDOG IGNORE → Invalid packet");
    }

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
      if (splitData.isNotEmpty && splitData[0].length >= 6) {
        final statusString = splitData[0];

        log.d("Input status raw: $statusString");

        if (_inputStatuses.length >= 4 && statusString.length >= 4) {
          _inputStatuses[0] = _getInputStatusDesc(statusString[0]); // Z1
          _inputStatuses[1] = _getInputStatusDesc(statusString[1]); // Z2
          _inputStatuses[2] = _getInputStatusDesc(statusString[2]); // Z3
          _inputStatuses[3] = _getInputStatusDesc(statusString[3]); // Z4
        }

        log.i(
          "Input Zones Updated: Z1: ${_inputStatuses[0]}, Z2: ${_inputStatuses[1]}, Z3: ${_inputStatuses[2]}, Z4: ${_inputStatuses[3]}",
        );

        String systemErrorValue = "UNKNOWN";
        if (statusString.length >= 5) {
          systemErrorValue = statusString[4];
          _isSystemErrorDetected = systemErrorValue != '0';
        }

        log.i("Tamper/System Error Status: $systemErrorValue");

        if (statusString.length >= 6) {
          _isMainsOk = statusString[5] == '1' || statusString[5] == '9';
        }
      }
    } else if (data.contains("020")) {
      final splitData = Packets.splitPacket(data);
      if (splitData.isNotEmpty && splitData[0].length == 1) {
        try {
          final level = int.parse(splitData[0]);
          _signalStrengthLevel = level.clamp(0, 4);
        } catch (e) {
          log.w("Failed to parse signal strength: $e");
          _signalStrengthLevel = 0;
        }
      }
    }
    notifyListeners();
  }

  Future<void> sendAutomationToggleCommand(int autoNumber, bool turnOn) async {
    try {
      final command = turnOn ? "1" : "0";

      // 🔹 Log intent
      log.i(
        "[Automation] Preparing command → autoNumber=$autoNumber, turnOn=$turnOn, command=$command",
      );

      final packet = Packets.getPacket(
        isReadPacket: false,
        args: ["007", "00$autoNumber", command],
      );

      // 🔹 Log packet before sending
      log.d("[Automation] Sending packet → $packet");

      final response = await _socketRepository.sendPacketSR1(
        packet,
        isPriority: true,
      );

      // 🔹 Log raw response
      log.d("[Automation] Raw response received → $response");

      if (_isDisposed) {
        log.w("[Automation] ViewModel disposed, ignoring response");
        return;
      }

      if (response.contains("S*007#")) {
        log.i(
          "[Automation] Command ACK received (S*007#) → autoNumber=$autoNumber",
        );

        if (autoNumber == 1) {
          _outputAuto1Status = turnOn ? "ON" : "OFF";
          log.i(
            "[Automation] Fogger state updated → $_outputAuto1Status",
          );

          _setEvent(
            turnOn
                ? PanelSR1ViewEvent.showFoggerArmedToast
                : PanelSR1ViewEvent.showFoggerDisarmedToast,
          );
        } else if (autoNumber == 3) {
          _outputAuto3Status = turnOn ? "ON" : "OFF";
          log.i(
            "[Automation] Exhaust fan state updated → ${_outputAuto3Status}",
          );

          _setEvent(
            turnOn
                ? PanelSR1ViewEvent.showExhaustFanOnToast
                : PanelSR1ViewEvent.showExhaustFanOffToast,
          );
        }

        notifyListeners();
        log.d("[Automation] Listeners notified");

        await refreshOutputStatus();
        log.d("[Automation] Output status refreshed");

        if (autoNumber == 1) {
          await refreshInputStatus();
          log.d("[Automation] Input status refreshed (fogger)");
        }
      } else {
        // 🔹 Unexpected response
        log.e(
          "[Automation] Command failed → Unexpected response: $response",
        );
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e, s) {
      // 🔹 Exception case
      log.e(
        "[Automation] Exception while sending command",
        error: e,
        stackTrace: s,
      );

      if (!_isDisposed) {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    }
  }

  Future<void> sendAutomationPulseCommand(int autoNumber) async {
    try {
      if (autoNumber == 2 && _outputAuto1Status != "ON") {
        log.w(
          "Fogger Trigger (Automation 2) pressed, but system (Automation 1) is not ON.",
        );
        _setEvent(PanelSR1ViewEvent.showFoggerNotActiveToast);
        return;
      }

      const command = "3";
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(
          isReadPacket: false,
          args: ["007", "00$autoNumber", command],
        ),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        if (autoNumber == 1) {
          _setEvent(PanelSR1ViewEvent.showEvacuatePulseSuccessToast);
        } else if (autoNumber == 2) {
          _setEvent(PanelSR1ViewEvent.showFoggerTriggerSuccessToast);
          log.i("Fogger triggered successfully. Automatically triggering Sounder ON.");
          await sendSounderOnCommand();
        } else {
          _setEvent(PanelSR1ViewEvent.showOutputStatusUpdatedToast);
        }
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send automation pulse command: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendInputPulseCommand(int inputNumber) async {
    log.i("Sending Input Pulse command for Input $inputNumber (HIGH PRIORITY)");
    try {
      if (inputNumber == 1 && _outputAuto1Status != "ON") {
        log.w(
          "Panic Alarm (Input 1) pressed, but system (Automation 1) is not ON.",
        );
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
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;

      if (response.contains("S*008#")) {
        _setEvent(
          PanelSR1ViewEvent.showInputPulseSuccessToast,
          data: {'inputNumber': inputNumber},
        );
        await refreshInputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send input pulse command: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendSounderOffAckCommand() async {
    log.i("Sending Sounder OFF/ACK command (HIGH PRIORITY)");
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "2"]),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "ACK";
        _setEvent(PanelSR1ViewEvent.showSounderOffSuccessToast);
        notifyListeners();
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send sounder off/ack command: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendSounderOnCommand() async {
    log.i("Sending Sounder ON command (HIGH PRIORITY)");
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "1"]),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "ON";
        _setEvent(PanelSR1ViewEvent.showSounderToggleSuccessToast);
        notifyListeners();
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send sounder on command: $e");
      if (!_isDisposed) _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
    }
  }

  Future<void> sendAlarmResetCommand() async {
    log.i("Sending Alarm Reset command (HIGH PRIORITY)");
    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: ["007", "000", "4"]),
        isPriority: true, // Priority implemented
      );
      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        _outputSounderStatus = "OFF";
        _setEvent(PanelSR1ViewEvent.showAlarmResetSuccessToast);
        notifyListeners();
        await refreshOutputStatus();
      } else {
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("Failed to send alarm reset command: $e");
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
        isPriority: true, // Priority implemented
      );
      if (!_isDisposed) _processReadResponse(response);
    } catch (e) {
      log.e("Failed to refresh input status: $e");
    }
  }

  Future<void> syncDateTime() async {
    log.i("Syncing panel date and time");
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
        log.i("Date and time sync successful");
        _currentPanelTime = now;
        _startClock();
        _setEvent(PanelSR1ViewEvent.showDateTimeSyncSuccessToast);
      } else {
        log.w("Failed to sync date and time. Response: $response");
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      if (!_isDisposed) {
        log.e("Error syncing date and time: $e");
        _setEvent(PanelSR1ViewEvent.showCommandFailedToast);
      }
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
    if (strings.isNotEmpty && strings.length >= 4) {
      if (strings[0].length > 1) {
        final sounderState = strings[0][1];
        switch (sounderState) {
          case '0':
            _outputSounderStatus = "OFF";
            break;
          case '1':
            _outputSounderStatus = "ON";
            break;
          case '2':
            _outputSounderStatus = "ACK";
            break;
          default:
            _outputSounderStatus = "OFF";
        }
      } else {
        _outputSounderStatus = "OFF";
      }

      _outputAuto1Status =
      (strings[1].length > 1 && strings[1][1] == '0') ? "OFF" : "ON";
      _outputAuto2Status =
      (strings[2].length > 1 && strings[2][1] == '0') ? "OFF" : "ON";
      _outputAuto3Status =
      (strings[3].length > 1 && strings[3][1] == '0') ? "OFF" : "ON";
    }
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
      log.e("Error parsing date/time: $e");
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _currentPanelTime = _currentPanelTime?.add(const Duration(seconds: 1));
      if (_currentPanelTime != null) {
        final dt = _currentPanelTime!;
        _date =
        "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
        _time =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
        _isAm = dt.hour < 12;
        notifyListeners();
      }
    });
  }
}