import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'dart:convert';
import '../../../core/data/pojo/panel_data.dart';
import '../../../core/responses/socket_repository.dart';
import '../../../core/utils/application_class.dart';

enum AlertType {
  disabled(0, "Disable"),
  sms(1, "SMS"),
  call(2, "Call"),
  smsAndCall(3, "SMS and Call");

  const AlertType(this.value, this.displayName);
  final int value;
  final String displayName;

  static AlertType fromValue(int value) {
    return AlertType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlertType.disabled,
    );
  }

  Map<String, dynamic> toJson() => {'value': value};
  static AlertType fromJson(Map<String, dynamic> json) =>
      fromValue(json['value'] ?? 0);
}

class TelephoneNumberSetting {
  String number;
  AlertType type;

  TelephoneNumberSetting({required this.number, required this.type});

  TelephoneNumberSetting copyWith({String? number, AlertType? type}) {
    return TelephoneNumberSetting(
      number: number ?? this.number,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {'number': number, 'type': type.toJson()};

  factory TelephoneNumberSetting.fromJson(Map<String, dynamic> json) =>
      TelephoneNumberSetting(
        number: json['number'] ?? "",
        type: AlertType.fromJson(json['type']),
      );
}

enum TelephoneSettingsEvent {
  none,
  showUpdateSuccessToast,
  showUpdateFailedToast,
  showFetchFailedToast,
  settingsReverted,
}

class TelephoneNoSettingsViewModel extends ChangeNotifier {
  final SocketRepository _socketRepository;
  final log = Logger();
  final PanelData panelData;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  List<TelephoneNumberSetting> _fetchedSettings = List.generate(
    10,
    (_) => TelephoneNumberSetting(number: "", type: AlertType.disabled),
  );

  List<TelephoneNumberSetting> _localSettings = List.generate(
    10,
    (_) => TelephoneNumberSetting(number: "", type: AlertType.disabled),
  );

  List<TelephoneNumberSetting> get settings => _localSettings;

  TelephoneSettingsEvent _event = TelephoneSettingsEvent.none;
  TelephoneSettingsEvent get event => _event;

  String _lastUpdateMessage = "";
  String get lastUpdateMessage => _lastUpdateMessage;

  TelephoneNoSettingsViewModel({
    required this.panelData,
    required SocketRepository socketRepository,
  }) : _socketRepository = socketRepository {
    // RUN THIS ONCE WHEN panelData IS AVAILABLE
    _initializePanelConnection();

    // Fetch initial telephone numbers
    fetchTelephoneNumbers();
  }

  void _initializePanelConnection() {
    final app = Application();
    app.mIPAddress = panelData.ipAdd;
    app.mPortNumber = int.tryParse(panelData.portNo);
    app.mPassword = panelData.pass;
    app.mStaticIPAddress = panelData.staticIp;
    app.mStaticPortNumber = int.tryParse(panelData.staticPort);
  }

  void _setEvent(TelephoneSettingsEvent event) {
    _event = event;
    notifyListeners();
  }

  void resetEvent() {
    _event = TelephoneSettingsEvent.none;
  }

  List<TelephoneNumberSetting> _deepCopySettings(
    List<TelephoneNumberSetting> source,
  ) {
    final String encoded = jsonEncode(source.map((e) => e.toJson()).toList());
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => TelephoneNumberSetting.fromJson(e)).toList();
  }

  Future<void> fetchTelephoneNumbers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: true, args: ["018"]),
        isPriority: true,
      );
      _parseReadResponse(response);
    } catch (e) {
      log.e("Failed to fetch telephone numbers: $e");
      _setEvent(TelephoneSettingsEvent.showFetchFailedToast);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _parseReadResponse(String data) {
    debugPrint("telephone number response: $data");
    if (!data.startsWith("S*018#") || !data.endsWith("*E")) {
      log.w("Invalid telephone data format: $data");
      return;
    }

    final parts = data.substring(6, data.length - 2).split('#');
    if (parts.length < 20) {
      log.w("Incomplete response. Expected 20 parts, got ${parts.length}");
      return;
    }

    List<TelephoneNumberSetting> newSettings = [];
    for (int i = 0; i < 10; i++) {
      final number = parts[i * 2];
      final typeValue = int.tryParse(parts[i * 2 + 1]) ?? 0;

      newSettings.add(
        TelephoneNumberSetting(
          number: number == "DISABLED" ? "" : number,
          type: AlertType.fromValue(typeValue),
        ),
      );
    }

    _fetchedSettings = _deepCopySettings(newSettings);
    _localSettings = _deepCopySettings(newSettings);

    log.i("Telephone settings loaded successfully.");
  }

  void updateLocalSetting(int index, {String? number, AlertType? type}) {
    if (index < 0 || index >= _localSettings.length) return;

    _localSettings[index] = _localSettings[index].copyWith(
      number: number,
      type: type,
    );
    notifyListeners();
  }

  void cancelChanges() {
    _localSettings = _deepCopySettings(_fetchedSettings);
    _setEvent(TelephoneSettingsEvent.settingsReverted);
  }

  // -------------------------------------------------------------------
  //  NEW FALLBACK HANDLER
  // -------------------------------------------------------------------
  void _handleNoImplementation() {
    log.w("No action executed. Operation not implemented or unavailable.");
    _lastUpdateMessage = "Cannot complete this operation right now.";
    _setEvent(TelephoneSettingsEvent.showUpdateFailedToast);
  }

  Future<void> submitAllChanges() async {
    if (_isUpdating) {
      log.w("Update already in progress.");
      return;
    }

    _isUpdating = true;
    notifyListeners();

    // Prepare packet
    List<String> packetArgs = ["018"];
    for (var setting in _localSettings) {
      packetArgs.add(setting.number.isEmpty ? "DISABLED" : setting.number);
      packetArgs.add(setting.type.value.toString());
    }

    try {
      // Attempt to send packet
      final writeResponse = await _socketRepository.sendPacketSR1(
        Packets.getPacket(isReadPacket: false, args: packetArgs),
        isPriority: true,
      );

      if (writeResponse == "S*018#0*E") {
        log.i("Update successful, reloading data.");

        await fetchTelephoneNumbers();

        _lastUpdateMessage = "Telephone settings updated successfully.";
        _setEvent(TelephoneSettingsEvent.showUpdateSuccessToast);
      } else {
        log.w("Unexpected write response: $writeResponse");
        _handleNoImplementation(); // fallback
      }
    } catch (e) {
      log.e("Failed to send update packet: $e");
      _handleNoImplementation(); // fallback
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
