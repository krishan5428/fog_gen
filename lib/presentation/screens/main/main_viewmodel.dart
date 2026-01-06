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

  bool _isForceCooldownActive = false;
  bool get isForceCooldownActive => _isForceCooldownActive;

  bool _showingInactivityDialog = false;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

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
    // Cancel timers on dispose
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    panelSR1ViewModel?.dispose();
    super.dispose();
  }

  Future<void> forceDisconnectAndAllowReconnect() async {
    log.w("Force disconnect initiated. Cooling down for 5 seconds.");

    _isForceCooldownActive = true;
    notifyListeners();

    disconnect(force: true, showToast: false);

    await Future.delayed(const Duration(seconds: 5));

    if (_isDisposed) return;
    _isForceCooldownActive = false;
    notifyListeners();

    log.i("Force disconnect cooldown complete. Connect allowed.");
  }

  /// Called by the global Listener in app.dart on any tap.
  void onUserInteraction() {
    if (!_isConnected) return;
    _restartInactivityTimer();
  }

  /// Start inactivity timer when panel connects
  void startInactivityTimer() {
    if (!_isConnected) return;
    _restartInactivityTimer();
  }

  /// Cancel both timers
  void stopInactivityTimers() {
    _inactivityTimer?.cancel();
    _autoDisconnectTimer?.cancel();
    _showingInactivityDialog = false;
  }

  /// Restart the 3-minute timer
  void _restartInactivityTimer() {
    _inactivityTimer?.cancel();

    _inactivityTimer = Timer(
      const Duration(minutes: 3),
      () => _triggerInactivityDialog(),
    );
  }

  /// Called after 3 minutes of no interaction
  void _triggerInactivityDialog() {
    if (!_isConnected || _showingInactivityDialog) return;
    _showingInactivityDialog = true;

    // Fire UI event
    _setEvent(MainViewEvent.showInactivityWarningDialog);

    // Start 1-minute auto disconnect countdown
    _autoDisconnectTimer?.cancel();
    _autoDisconnectTimer = Timer(const Duration(minutes: 1), () {
      _showingInactivityDialog = false;
      disconnect();
    });
  }

  /// Called when user taps “Stay Connected”
  void stayConnected() {
    _showingInactivityDialog = false;
    _autoDisconnectTimer?.cancel();
    _restartInactivityTimer();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> sendSounderOffAckCommand() async {
    log.i("[Sounder] Sending Sounder OFF / ACK command (HIGH PRIORITY)");

    try {
      final packet = Packets.getPacket(
        isReadPacket: false,
        args: ["007", "000", "2"],
      );

      log.d("[Sounder] Packet sent → $packet");

      final response = await socketRepository.sendPacketSR1(
        packet,
        isPriority: true,
      );

      log.d("[Sounder] Raw response received → $response");

      if (_isDisposed) return;

      if (response.contains("S*007#")) {
        log.i("[Sounder] ACK received – Sounder OFF successful");

        _setEvent(MainViewEvent.showSounderOffSuccessToast);
      } else {
        log.e("[Sounder] Unexpected response → $response");

        _setEvent(MainViewEvent.showCommandFailedToast);
      }
    } catch (e, s) {
      log.e(
        "[Sounder] Exception while sending Sounder OFF command",
        error: e,
        stackTrace: s,
      );

      if (!_isDisposed) {
        _setEvent(MainViewEvent.showCommandFailedToast);
      }
    }
  }

  /// Handles the response from an SR1 panel after a connection attempt.
  void _handleSR1Response(String result, String siteName) {
    if (result.contains("S*000#3#*E")) {
      log.w("SR1 Response: Panel is busy or already connected.");
      _setEvent(MainViewEvent.showAlreadyConnectedDialog);
    } else if (result.startsWith("S*000#1")) {
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
          log.i("SR1 Response: Handshake successful. Stored panel details.");

          // --- MODIFIED: Create the ViewModel with siteName ---
          panelSR1ViewModel = PanelSR1ViewModel(
            socketRepository: socketRepository,
            // siteName: siteName, // Pass the siteName
          );
          log.i(
            "PanelSR1ViewModel created for '$siteName'. It will now fetch initial data in the background.",
          );

          // Add listener to child viewModel to track loading completion
          panelSR1ViewModel!.addListener(_checkInitializationStatus);

          _connectionSuccess();
        } else {
          log.w(
            "SR1 Response: Handshake response format is unexpected: $result",
          );
          _connectionFailed();
        }
      } catch (e) {
        log.e("Failed to parse SR1 handshake response: $e");
        _connectionFailed();
      }
    } else {
      log.w("SR1 Response: Unknown response received: $result");
      _connectionFailed();
    }
  }

  void loadPanelDetails() {
    final app = Application();

    app.mIPAddress = panel.ip_address;
    app.mPortNumber = int.tryParse(panel.port_no) ?? 0;
    app.mStaticIPAddress = panel.static_ip_address;
    app.mStaticPortNumber = int.tryParse(panel.static_port_no) ?? 0;
    app.mPassword = panel.password;
  }

  /// Centralized method to handle a successful connection.
  void _connectionSuccess() {
    _isConnected = true;
    _isInitializing = true;
    notifyListeners();

    startInactivityTimer(); // <-- clean call
    _startInitializationCheck();
  }

  Future<void> performAppCloseDisconnect() async {
    if (_isConnected) {
      log.i("App closing: Sending immediate disconnect packet.");
      // We await this to ensure the OS doesn't kill the process before the packet leaves
      await socketRepository.sendDisconnectPacket();
    }
  }

  // Standard disconnect used by timers
  void disconnect({bool showToast = true, bool force = false}) {
    // If NOT force and already disconnected → do nothing
    if (!_isConnected && !force) {
      return;
    }

    stopInactivityTimers();
    _setEvent(MainViewEvent.dismissInactivityDialog);

    // ✅ Always send packet if force OR connected
    socketRepository.sendDisconnectPacket();

    resetState();

    if (showToast) {
      _setEvent(MainViewEvent.showDisconnectedToast);
    }
  }

  /// NEW: Check initialization status periodically
  void _startInitializationCheck() {
    _initializationCheckTimer?.cancel();

    _initializationCheckTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (!panelSR1ViewModel!.isPanelStatusLoading &&
            !panelSR1ViewModel!.isZoneStatusLoading) {
          log.i(
            "SR1 Panel initialization complete - all critical data loaded.",
          );
          _completeInitialization();
          timer.cancel();
        }
      },
    );

    // Safety timeout: force completion after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (_isInitializing && !_isDisposed) {
        log.w("Initialization timeout reached - forcing completion.");
        _completeInitialization();
      }
    });
  }

  /// NEW: Listen to child viewModel changes
  void _checkInitializationStatus() {
    if (!_isInitializing || _isDisposed) return;

    if (panelSR1ViewModel != null &&
        !panelSR1ViewModel!.isPanelStatusLoading &&
        !panelSR1ViewModel!.isZoneStatusLoading) {
      log.i("Initialization status changed - data loading complete.");
      // The periodic timer will pick this up and complete initialization
    }
  }

  /// NEW: Complete the initialization phase
  void _completeInitialization() async {
    // MODIFIED: Make async
    if (!_isDisposed && _isInitializing) {
      _initializationCheckTimer?.cancel();

      // NEW: Enforce a minimum 3-second display time
      const minDisplayDuration = Duration(seconds: 3);
      final timeSinceConnection = _connectionTime != null
          ? DateTime.now().difference(_connectionTime!)
          : minDisplayDuration;

      if (timeSinceConnection < minDisplayDuration) {
        final remainingDelay = minDisplayDuration - timeSinceConnection;
        log.i(
          "Data loaded quickly. Waiting for an additional ${remainingDelay.inMilliseconds}ms to meet 3-second minimum.",
        );
        await Future.delayed(remainingDelay);
      }

      if (_isDisposed) return; // Check again after delay

      _isInitializing = false;
      notifyListeners();
      log.i("Panel initialization complete - UI now showing full controls.");
    }
  }

  /// Centralized method to handle a failed connection attempt.
  void _connectionFailed() {
    disconnect();
    _setEvent(MainViewEvent.showConnectionFailedToast);
  }

  Future<void> connect() async {
    if (_isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      loadPanelDetails();

      // RECOMMENDED FIX: Create a brand new socket repo for a fresh connection
      socketRepository = SocketRepository();

      final response = await socketRepository.sendPacketSR1(
        Packets.connectPacket(),
      );

      _handleSR1Response(response, panel.site);
    } catch (e) {
      log.e("Connection failed: $e");
      _setEvent(MainViewEvent.showConnectionFailedToast);
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void resetState() {
    _isConnected = false;
    _isConnecting = false;
    _isInitializing = false;
    isUserEvent = false;
    _connectionTime = null;

    _initializationCheckTimer?.cancel();
    stopInactivityTimers();

    if (panelSR1ViewModel != null) {
      panelSR1ViewModel!.removeListener(_checkInitializationStatus);
      panelSR1ViewModel!.dispose();
      panelSR1ViewModel = null;
    }

    // ❌ REMOVE wiping Application() values

    notifyListeners();
  }

  void _setEvent(MainViewEvent event) {
    _event = event;
    notifyListeners();
  }

  void resetEvent() {
    _event = MainViewEvent.none;
  }

  void disposeViewModel() {
    _isDisposed = true;

    _initializationCheckTimer?.cancel();
    _siteNameSubscription?.cancel();
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    panelSR1ViewModel?.dispose();
    panelSR1ViewModel = null;

    socketRepository.clearQueue();
  }
}
