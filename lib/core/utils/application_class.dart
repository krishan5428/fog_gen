import 'dart:async';

/// A singleton class to hold application-level global variables.
/// This replaces the static variables from CommonMethods.kt and the
/// purpose of the original ApplicationClass.kt.
class Application {
  static final Application _instance = Application._internal();

  factory Application() {
    return _instance;
  }

  Application._internal();

  // Global state variables
  Timer? packetTimeOut;
  bool templateMode = false;
  String? mIPAddress;
  int? mPortNumber;
  String? mStaticIPAddress;
  int? mStaticPortNumber;
  String? mPassword;
  String? mSiteName;
  String? userType;

  // SR1 Panel Properties
  String? macAddress;
  String? firmware;
  String? panelId;

  // Constants
  static const String admin = "001";
  static const String user = "002";

  // SB2 Panel Properties
  String receiverNo = "000000";
  String lineNo = "000000";
  String accountNo = "000000";
  String? sb2MacId;
  String? sb2Version;

  // Corrected Getters and Setters for macId and version
  // These will now correctly get and set the values for sb2MacId and sb2Version
  String? get macId => sb2MacId;
  set macId(String? macId) => sb2MacId = macId;

  String? get version => sb2Version;
  set version(String? version) => sb2Version = version;

  void dispose() {
    packetTimeOut?.cancel();
  }
}
