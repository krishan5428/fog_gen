import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';
import 'package:fog_gen_new/core/utils/packets.dart';
import 'package:intl/intl.dart';

import '../../../utils/auth_helper.dart';

enum ConnectionStatus { connected, failed, alreadyConnected }

class AddPanelViewModel extends ChangeNotifier {
  // Controllers
  final siteNameController = TextEditingController();
  final addressController = TextEditingController();

  // GPRS Controllers
  final panelSimNumberController = TextEditingController();
  final adminNumberController = TextEditingController();

  // IP Controllers
  final ipAddressController = TextEditingController();
  final portNumberController = TextEditingController();
  final staticIpController = TextEditingController();
  final staticPortController = TextEditingController();
  final passwordController = TextEditingController();

  final SocketRepository _socketRepo = SocketRepository();
  bool _isLoading = false;

  // Parsed Hardware Info
  String _pnlMac = '';
  String _pnlVer = '';
  String _pnlAccNo = '';

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- Validation Logic ---
  String? validateForm({
    required List<String> existingSiteNames,
    required List<String> existingPanelSims,
  }) {
    final siteName = siteNameController.text.trim();
    final address = addressController.text.trim();
    final panelSim = panelSimNumberController.text.trim();
    final adminNum = adminNumberController.text.trim();
    final ip = ipAddressController.text.trim();
    final staticIp = staticIpController.text.trim();
    final port = portNumberController.text.trim();
    final staticPort = staticPortController.text.trim();
    final pass = passwordController.text.trim();

    const ipPattern = r'^(\d{1,3}\.){3}\d{1,3}$';
    final ipRegex = RegExp(ipPattern);

    if (siteName.isEmpty) return 'Site Name cannot be empty';
    if (address.isEmpty) return 'Site Address cannot be empty';
    if (existingSiteNames.contains(siteName)) {
      return 'Site name "$siteName" already exists.';
    }
    if (existingPanelSims.contains(panelSim)) {
      return 'Panel sim number already exists.';
    }

    if (ip.isEmpty || !ipRegex.hasMatch(ip)) {
      return 'Enter a valid IP Address (e.g., 192.168.1.1)';
    }
    if (staticIp.isNotEmpty && !ipRegex.hasMatch(staticIp)) {
      return 'Enter a valid Static IP Address';
    }

    if (panelSim.isEmpty) return 'Panel SIM Number cannot be empty';
    if (panelSim.length != 10 && panelSim.length != 13) {
      return 'Panel SIM Number must be 10 or 13 digits';
    }

    if (adminNum.isEmpty) return 'Admin SIM Number cannot be empty';

    final portInt = int.tryParse(port);
    if (portInt == null || portInt <= 0) return 'Enter a valid Port Number';

    if (staticPort.isNotEmpty) {
      final staticPortInt = int.tryParse(staticPort);
      if (staticPortInt == null || staticPortInt <= 0) {
        return 'Enter a valid Static Port Number';
      }
    }

    if (pass.length != 4 || int.tryParse(pass) == null) {
      return 'Password must be 4 digits';
    }

    return null; // No error
  }

  // --- Socket Operations ---
  Future<ConnectionStatus> connectToPanel() async {
    try {
      setLoading(true);

      // Update Global Application State
      Application()
        ..mIPAddress = ipAddressController.text.trim()
        ..mPortNumber = int.parse(portNumberController.text.trim())
        ..mPassword = passwordController.text.trim()
        ..mStaticIPAddress = staticIpController.text.trim()
        ..mStaticPortNumber =
            int.tryParse(staticPortController.text.trim()) ?? 0;

      final response = await _socketRepo.sendPacketSR1(Packets.connectPacket());

      // LOG THE RAW RESPONSE
      debugPrint("📡 Raw Socket Response from Panel: $response");

      // PARSE THE RESPONSE
      _parseHardwareInfo(response);

      return _handleSR1Response(response);
    } catch (e) {
      debugPrint("❌ Socket Error during connection: $e");
      return ConnectionStatus.failed;
    } finally {
      setLoading(false);
    }
  }

  void _parseHardwareInfo(String response) {
    try {
      // Example: S*000#1#004145098123236254#123456789123456#0#V0.1.1C#999999*E
      response = response.trim();
      final parts = response.split('#');
      if (parts.length >= 7) {
        _pnlMac = parts[2]; // 004145098123236254
        _pnlVer = parts[5]; // V0.1.1C
        String accNoPart = parts[6]; // 999999*E
        _pnlAccNo = accNoPart.replaceAll('*E', ''); // 999999

        debugPrint("✅ Parsed Info - Mac: $_pnlMac, Ver: $_pnlVer, Acc: $_pnlAccNo");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to parse hardware info: $e");
    }
  }

  ConnectionStatus _handleSR1Response(String result) {
    result = result.trim();
    if (result.contains("S*000#3#*E")) {
      return ConnectionStatus.alreadyConnected;
    }
    if (result.startsWith("S*000#1")) {
      return ConnectionStatus.connected;
    }
    return ConnectionStatus.failed;
  }

  Future<bool> forceDisconnect() async {
    try {
      await _socketRepo.sendDisconnectPacket();
      return true;
    } catch (e) {
      debugPrint("Disconnect Error: $e");
      return false;
    }
  }

  // --- Data Preparation for Cubit (Standardized Server Keys) ---
  Future<Map<String, dynamic>?> prepareSaveData({
    required String panelType,
    required String panelName,
  }) async {
    final userId = await SharedPreferenceHelper.getUserId();
    if (userId == null) return null;

    final currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    return {
      'usr_id': userId.toString(),
      'pnl_type': panelType,
      'panel_name': panelName,
      'site_name': siteNameController.text.trim(),
      'panel_sim_number': panelSimNumberController.text.trim(),
      'admin_code': "1234",
      'admin_mobile_number': adminNumberController.text.trim(),
      'mobile_number_sub_id': '0',
      'mobile_number1': "0000000000",
      'mobile_number2': "0000000000",
      'mobile_number3': "0000000000",
      'mobile_number4': "0000000000",
      'mobile_number5': "0000000000",
      'mobile_number6': "0000000000",
      'mobile_number7': "0000000000",
      'mobile_number8': "0000000000",
      'mobile_number9': "0000000000",
      'mobile_number10': "0000000000",
      'site_address': addressController.text.trim(),
      'c_on': currentTime,
      'pass': passwordController.text.trim(),
      'ip_add': ipAddressController.text.trim(),
      'is_ip_gsm_panel': true,
      'is_ip_panel': false,
      'port_no': portNumberController.text.trim(),
      'static_ip': staticIpController.text.trim(),
      'static_port': staticPortController.text.trim(),

      // IMPORTANT: These keys were missing, causing the 'Null' error in UI
      'pnl_mac': _pnlMac,
      'pnl_ver': _pnlVer,
      'pnl_acc_no': _pnlAccNo,
    };
  }

  @override
  void dispose() {
    siteNameController.dispose();
    addressController.dispose();
    panelSimNumberController.dispose();
    adminNumberController.dispose();
    ipAddressController.dispose();
    portNumberController.dispose();
    staticIpController.dispose();
    staticPortController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}