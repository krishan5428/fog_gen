import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fog_gen_new/presentation/screens/main/panel_sr1/panel_sr1_viewmodel.dart';
import 'package:logger/logger.dart';
import '../../../core/data/pojo/panel_data.dart';
import '../../../core/responses/socket_repository.dart';
import '../../../core/utils/application_class.dart';
import '../../../core/utils/packets.dart';

enum MainViewEvent {
  none,
  showAlreadyConnectedDialog,
  showDisconnectedToast,
  showNoSiteSelectedToast,
  showConnectionFailedToast,
  showInactivityWarningDialog,
  dismissInactivityDialog,
  showSounderOffSuccessToast,
  showCommandFailedToast,
}

class MainViewModel extends ChangeNotifier {
  SocketRepository socketRepository;
  final PanelData panel;
  final log = Logger();
  Timer? _inactivityTimer;
  Timer? _autoDisconnectTimer;

  // --- STATE FLAGS ---
  bool _isForceCooldownActive = false;
  bool get isForceCooldownActive => _isForceCooldownActive;

  bool _showingInactivityDialog = false;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  // NEW: Flag to prevent infinite retry loops
  bool _isAutoRetryingBusyState = false;

  MainViewEvent _event = MainViewEvent.none;
  MainViewEvent get event => _event;

  bool isUserEvent = false;

  PanelSR1ViewModel? panelSR1ViewModel;

  Timer? _initializationCheckTimer;
  DateTime? _connectionTime;

  StreamSubscription? _siteNameSubscription;

  bool _isDisposed = false;

  Timer? _warningTimer;

  MainViewModel({required this.panel, required this.socketRepository}) {
    loadPanelDetails();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _initializationCheckTimer?.cancel();
    _siteNameSubscription?.cancel();
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    panelSR1ViewModel?.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // FORCE DISCONNECT (Manual User Action)
  // ----------------------------------------------------------------------
  Future<void> forceDisconnectAndAllowReconnect() async {
    log.w("Force disconnect initiated. Cooling down for 5 seconds.");

    _isForceCooldownActive = true;
    notifyListeners();

    // Perform a full disconnect
    await disconnect();

    // Wait extra time for hardware to clear socket
    await Future.delayed(const Duration(seconds: 5));

    if (_isDisposed) return;
    _isForceCooldownActive = false;
    notifyListeners();

    log.i("Force disconnect cooldown complete. Connect allowed.");
  }

  // ----------------------------------------------------------------------
  // INACTIVITY LOGIC
  // ----------------------------------------------------------------------
  void onUserInteraction() {
    if (!_isConnected) return;
    _restartInactivityTimer();
  }

  void startInactivityTimer() {
    if (!_isConnected) return;
    _restartInactivityTimer();
  }

  void stopInactivityTimers() {
    _inactivityTimer?.cancel();
    _autoDisconnectTimer?.cancel();
    _showingInactivityDialog = false;
  }

  void _restartInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      const Duration(minutes: 3),
      () => _triggerInactivityDialog(),
    );
  }

  void _triggerInactivityDialog() {
    if (!_isConnected || _showingInactivityDialog) return;
    _showingInactivityDialog = true;
    _setEvent(MainViewEvent.showInactivityWarningDialog);

    _autoDisconnectTimer?.cancel();
    _autoDisconnectTimer = Timer(const Duration(minutes: 1), () {
      _showingInactivityDialog = false;
      disconnect();
    });
  }

  void stayConnected() {
    _showingInactivityDialog = false;
    _autoDisconnectTimer?.cancel();
    _restartInactivityTimer();
  }

  // ----------------------------------------------------------------------
  // COMMANDS
  // ----------------------------------------------------------------------
  Future<void> sendSounderOffAckCommand() async {
    log.i("[Sounder] Sending Sounder OFF / ACK command");
    try {
      final packet = Packets.getPacket(
        isReadPacket: false,
        args: ["007", "000", "2"],
      );

      final response = await socketRepository.sendPacketSR1(
        packet,
        isPriority: true,
      );

      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        log.i("[Sounder] ACK received");
        _setEvent(MainViewEvent.showSounderOffSuccessToast);
      } else {
        log.e("[Sounder] Unexpected response → $response");
        _setEvent(MainViewEvent.showCommandFailedToast);
      }
    } catch (e) {
      log.e("[Sounder] Exception: $e");
      if (!_isDisposed) _setEvent(MainViewEvent.showCommandFailedToast);
    }
  }

  // ----------------------------------------------------------------------
  // CONNECTION & RESPONSE HANDLING (UPDATED)
  // ----------------------------------------------------------------------
  void _handleSR1Response(String result, String siteName) {
    // CASE 1: PANEL BUSY (#3#)
    if (result.contains("S*000#3#")) {
      log.w("SR1 Response: Panel is BUSY (#3#).");

      if (!_isAutoRetryingBusyState) {
        log.i("First BUSY response detected. Attempting AUTO-FIX...");
        _attemptAutoFixBusyState();
      } else {
        // We already tried to fix it, and it's still busy. Show dialog.
        log.e("Auto-Fix failed. Panel remains busy. Showing dialog.");
        _isAutoRetryingBusyState = false;
        _isConnecting = false;
        notifyListeners();
        _setEvent(MainViewEvent.showAlreadyConnectedDialog);
      }
    }
    // CASE 2: SUCCESS (#1#)
    else if (result.startsWith("S*000#1")) {
      try {
        final parts = result.replaceAll(RegExp(r'S\*|\*E'), '').split('#');
        if (parts.length >= 7) {
          final macId = parts[2];
          final version = parts[5];
          final panelId = parts[6];

          final app = Application();
          app.macAddress = macId;
          app.firmware = version;
          app.panelId = panelId;
          log.i("SR1 Response: Handshake successful.");

          // Success! Reset the retry flag
          _isAutoRetryingBusyState = false;

          panelSR1ViewModel = PanelSR1ViewModel(
            socketRepository: socketRepository,
          );

          panelSR1ViewModel!.addListener(_checkInitializationStatus);

          _connectionSuccess();
        } else {
          log.w("SR1 Response: Handshake format unexpected: $result");
          _connectionFailed();
        }
      } catch (e) {
        log.e("Failed to parse SR1 handshake: $e");
        _connectionFailed();
      }
    }
    // CASE 3: UNKNOWN
    else {
      log.w("SR1 Response: Unknown response: $result");
      _connectionFailed();
    }
  }

  /// NEW: Logic to automatically kick a ghost session
  Future<void> _attemptAutoFixBusyState() async {
    _isAutoRetryingBusyState = true;

    // 1. Send Disconnect Command silently
    try {
      final pwd = panel.password.isNotEmpty ? panel.password : "1234";
      final disconnectPacket = "S*$pwd#W#013*E";
      log.i("[AutoFix] Sending Kill Command: $disconnectPacket");

      // We don't care about the response here, just send it to clear the buffer
      await socketRepository
          .sendPacketSR1(disconnectPacket, isPriority: true)
          .timeout(const Duration(seconds: 2), onTimeout: () => "");
    } catch (e) {
      log.w("[AutoFix] Error sending kill packet (expected): $e");
    }

    // 2. Wait for Hardware to reset (3 seconds is standard for IoT chips)
    log.i("[AutoFix] Waiting 3s for hardware socket reset...");
    await Future.delayed(const Duration(seconds: 3));

    // 3. Close local socket to be sure
    socketRepository.stopAllActivity();

    // 4. Retry Connection (Recursive call to connect)
    log.i("[AutoFix] Retrying connection now...");
    _isConnecting = false; // Reset flag so connect() runs
    connect();
  }

  void loadPanelDetails() {
    final app = Application();
    app.mIPAddress = panel.ip_address;
    app.mPortNumber = int.tryParse(panel.port_no) ?? 0;
    app.mStaticIPAddress = panel.static_ip_address;
    app.mStaticPortNumber = int.tryParse(panel.static_port_no) ?? 0;
    app.mPassword = panel.password;
  }

  void _connectionSuccess() {
    _isConnected = true;
    _isInitializing = true;
    notifyListeners();

    startInactivityTimer();
    _startInitializationCheck();
  }

  Future<void> disconnect() async {
    log.i("User/System initiated disconnect.");

    if (_isConnected) {
      try {
        final pwd = panel.password.isNotEmpty ? panel.password : "1234";
        final disconnectPacket = "S*$pwd#W#013*E";

        log.i("Sending Disconnect Packet: $disconnectPacket");

        // Send and wait briefly for ACK
        final response = await socketRepository
            .sendPacketSR1(disconnectPacket, isPriority: true)
            .timeout(const Duration(seconds: 2), onTimeout: () => "TIMEOUT");

        if (response.contains("S*013#0")) {
          log.i("✅ Disconnect confirmed by panel.");
        }
      } catch (e) {
        log.w("Disconnect warning: $e");
      }
    }

    // Always clean up local socket
    socketRepository.stopAllActivity();

    _setEvent(MainViewEvent.showDisconnectedToast);
    resetState();
  }

  // ----------------------------------------------------------------------
  // INITIALIZATION CHECKERS
  // ----------------------------------------------------------------------
  void _startInitializationCheck() {
    _initializationCheckTimer?.cancel();

    _initializationCheckTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (panelSR1ViewModel != null &&
            !panelSR1ViewModel!.isPanelStatusLoading &&
            !panelSR1ViewModel!.isZoneStatusLoading) {
          log.i("SR1 Panel initialization complete.");
          _completeInitialization();
          timer.cancel();
        }
      },
    );

    // Watchdog for init
    Timer(const Duration(seconds: 10), () {
      if (_isInitializing && !_isDisposed) {
        log.w("Initialization timeout - forcing completion.");
        _completeInitialization();
      }
    });
  }

  void _checkInitializationStatus() {
    if (!_isInitializing || _isDisposed) return;
    // Listener callback - logic handled in _startInitializationCheck
  }

  void _completeInitialization() async {
    if (!_isDisposed && _isInitializing) {
      _initializationCheckTimer?.cancel();

      // Ensure minimum 3s splash
      const minDisplayDuration = Duration(seconds: 3);
      final timeSinceConnection = _connectionTime != null
          ? DateTime.now().difference(_connectionTime!)
          : minDisplayDuration;

      if (timeSinceConnection < minDisplayDuration) {
        await Future.delayed(minDisplayDuration - timeSinceConnection);
      }

      if (_isDisposed) return;

      _isInitializing = false;
      notifyListeners();
    }
  }

  void _connectionFailed() {
    disconnect();
    // Only show toast if we aren't in the middle of an auto-retry
    if (!_isAutoRetryingBusyState) {
      _setEvent(MainViewEvent.showConnectionFailedToast);
    }
  }

  Future<void> connect() async {
    if (_isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      loadPanelDetails();

      // Fresh Socket Repo for new attempt
      socketRepository = SocketRepository();

      final response = await socketRepository.sendPacketSR1(
        Packets.connectPacket(),
      );

      _handleSR1Response(response, panel.site);
    } catch (e) {
      log.e("Connection failed: $e");

      // If we were auto-retrying and it failed with Exception, stop retrying
      if (_isAutoRetryingBusyState) {
        _isAutoRetryingBusyState = false;
        _setEvent(MainViewEvent.showAlreadyConnectedDialog);
      } else {
        _setEvent(MainViewEvent.showConnectionFailedToast);
      }
    } finally {
      // If we are auto-retrying, keep isConnecting true to prevent UI flicker
      // otherwise set it to false
      if (!_isAutoRetryingBusyState) {
        _isConnecting = false;
        notifyListeners();
      }
    }
  }

  void resetState() {
    _isConnected = false;
    _isConnecting = false;
    _isInitializing = false;
    isUserEvent = false;
    _connectionTime = null;

    _isAutoRetryingBusyState = false;
    _initializationCheckTimer?.cancel();
    stopInactivityTimers();

    if (panelSR1ViewModel != null) {
      panelSR1ViewModel!.removeListener(_checkInitializationStatus);
      panelSR1ViewModel!.dispose();
      panelSR1ViewModel = null;
    }

    notifyListeners();
  }

  void _setEvent(MainViewEvent event) {
    _event = event;
    notifyListeners();
  }

  void resetEvent() {
    _event = MainViewEvent.none;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
