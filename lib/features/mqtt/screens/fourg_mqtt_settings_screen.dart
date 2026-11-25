// ignore_for_file: deprecated_member_use, unused_field, use_build_context_synchronously
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/features/mqtt/screens/fourg_mqtt_zone_mappings_screen.dart';
import 'package:fog_gen_new/features/mqtt/screens/fourg_mqtt_telephone_settings_screen.dart';
import 'package:fog_gen_new/features/mqtt/screens/fourg_mqtt_audio_settings_screen.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/core/utils/toast_helper.dart';

class FourGMqttSettingsScreen extends StatefulWidget {
  final PanelData panelData;
  final FourGRepository fourGRepository;

  const FourGMqttSettingsScreen({
    super.key,
    required this.panelData,
    required this.fourGRepository,
  });

  @override
  State<FourGMqttSettingsScreen> createState() =>
      _FourGMqttSettingsScreenState();
}

class _FourGMqttSettingsScreenState extends State<FourGMqttSettingsScreen> {
  // Lazily filled the first time each item is opened, then reused for the
  // rest of this screen's lifetime — not eagerly prefetched on open.
  String? _panelIdResponse;
  String? _destinationIPResponse;

  @override
  void initState() {
    super.initState();
    // Connect packet only — every other read is manual, on the page that needs it.
    widget.fourGRepository.sendSilentConnectPing(
      imei: widget.panelData.panelImei,
      passcode: widget.panelData.pass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_GridOption> options = [
      _GridOption(
        title: 'Device ID',
        icon: Icons.device_hub,
        onTap: () => _handlePanelId(context),
      ),
      _GridOption(
        title: 'Destination IP Settings',
        icon: Icons.public,
        onTap: () => _handleDestinationIP(context),
      ),
      _GridOption(
        title: 'Telephone Settings',
        icon: Icons.person_add_alt_1,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FourGMqttTelephoneSettingsScreen(
                    panelData: widget.panelData,
                    fourGRepository: widget.fourGRepository,
                  ),
            ),
          );
        },
      ),
      _GridOption(
        title: 'Zone Mappings',
        icon: Icons.map,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FourGMqttZoneMappingsScreen(
                    panelData: widget.panelData,
                    fourGRepository: widget.fourGRepository,
                  ),
            ),
          );
        },
      ),
      _GridOption(
        title: 'Audio Settings',
        icon: Icons.audiotrack,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FourGMqttAudioSettingsScreen(
                    panelData: widget.panelData,
                    fourGRepository: widget.fourGRepository,
                  ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        pageName: 'Device Settings',
        isFilter: false,
        isDash: false,
        onBack: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return _GridBox(option: option);
          },
        ),
      ),
    );
  }

  // Await helper for MQTT response acks.
  //
  // Panel write-ack STATUS codes: 00=Nack, 01=Ack, 02=Process Success,
  // 03=Process Fail, 04=Processing (non-terminal — more messages still to
  // come), 99=Data Error. "02" was previously never checked, so a write the
  // panel actually applied (and acked with "02") looked like a failure to
  // the app; "04" was previously treated as an immediate success, when it
  // really just means "keep waiting for the real result".
  Future<bool> _awaitWriteAck(String packetId) async {
    final completer = Completer<bool>();
    late StreamSubscription sub;
    sub = widget.fourGRepository.mqttService.mqttRepository.messageStream
        .listen((response) {
          final parts = response.split('\$');
          if (parts.length < 5) return;
          if (parts[2] != "04" || !parts[4].startsWith(packetId)) return;

          final status = parts[3];
          if (status == "01" || status == "02") {
            if (!completer.isCompleted) completer.complete(true);
          } else if (status == "04") {
            // Processing — not terminal, keep waiting for the real status.
          } else {
            if (!completer.isCompleted) completer.complete(false);
          }
        });

    final result = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    await sub.cancel();
    return result;
  }

  // Show generic feedback toast
  void _showFeedback(BuildContext context, String message) {
    if (!context.mounted) return;
    ToastHelper.show(context, message);
  }

  // PANEL ID SETUP METHOD
  void _handlePanelId(BuildContext context) async {
    String? response = _panelIdResponse;

    if (response == null) {
      ProgressDialog.show(context, message: "Reading Device ID data...");
      response = await widget.fourGRepository.readPanelId(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
      );
      if (mounted) {
        ProgressDialog.dismiss(context);
        setState(() {
          _panelIdResponse = response;
        });
      }
    }

    if (response == null) {
      _showFeedback(context, "Read Timeout: Could not read Device ID.");
      return;
    }

    // Parse response
    final parts = response.split('\$');
    String panelId = "";
    String rValue = "000001";
    String lValue = "000000";

    if (parts.length >= 7) panelId = parts[6];
    if (parts.length >= 8) rValue = parts[7];
    if (parts.length >= 9) lValue = parts[8].replaceAll("*ED", "");

    final panelIdController = TextEditingController(text: panelId);
    final rValueController = TextEditingController(text: rValue);
    final lValueController = TextEditingController(text: lValue);

    // Show Bottom Sheet Editor
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Device ID Information",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: AppColors.colorPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildField(
                  "Device ID",
                  panelIdController,
                  maxLength: 6,
                  readOnly: true,
                  icon: Icons.fingerprint,
                ),
                const SizedBox(height: 12),
                _buildField(
                  "R Value",
                  rValueController,
                  maxLength: 6,
                  readOnly: true,
                  icon: Icons.router_outlined,
                ),
                const SizedBox(height: 12),
                _buildField(
                  "L Value",
                  lValueController,
                  maxLength: 6,
                  readOnly: true,
                  icon: Icons.numbers_outlined,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // DESTINATION IP SETUP METHOD
  void _handleDestinationIP(BuildContext context) async {
    String? response = _destinationIPResponse;

    if (response == null) {
      ProgressDialog.show(
        context,
        message: "Reading Destination IP settings...",
      );
      response = await widget.fourGRepository.readDestinationSettings(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
      );
      if (mounted) {
        ProgressDialog.dismiss(context);
        setState(() {
          _destinationIPResponse = response;
        });
      }
    }

    if (response == null) {
      _showFeedback(context, "Read Timeout: Could not fetch Destination IP.");
      return;
    }

    final parts = response.split('\$');
    String modeType = "1";
    String destIp = "";
    String destPort = "";
    String destIp2 = "0.0.0.0";
    String destPort2 = "00000";

    if (parts.length >= 7) modeType = parts[6];
    if (parts.length >= 8) destIp = parts[7];
    if (parts.length >= 9) destPort = parts[8];
    if (parts.length >= 11) destIp2 = parts[10];
    if (parts.length >= 12) destPort2 = parts[11].replaceAll("*ED", "");

    final ipController = TextEditingController(text: destIp);
    final portController = TextEditingController(text: destPort);
    final ip2Controller = TextEditingController(text: destIp2);
    final port2Controller = TextEditingController(text: destPort2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Destination IP Settings",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: AppColors.colorPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildField("Server IP", ipController, isNumber: false),
                const SizedBox(height: 12),
                _buildField("Port Number", portController, maxLength: 5),
                const SizedBox(height: 12),
                _buildField("Backup Server IP", ip2Controller, isNumber: false),
                const SizedBox(height: 12),
                _buildField("Backup Port", port2Controller, maxLength: 5),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final ip = ipController.text.trim();
                    final port = portController.text.trim();
                    final ip2 = ip2Controller.text.trim();
                    final port2 = port2Controller.text.trim();

                    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                    if (!ipRegex.hasMatch(ip) || !ipRegex.hasMatch(ip2)) {
                      _showFeedback(ctx, "Please enter valid IP addresses.");
                      return;
                    }

                    Navigator.pop(ctx); // Close sheet

                    ProgressDialog.show(
                      context,
                      message: "Updating destination IP settings...",
                    );

                    final sent = await widget.fourGRepository
                        .assignDestinationSettings(
                          imei: widget.panelData.panelImei,
                          passcode: widget.panelData.pass,
                          type: modeType,
                          ip: ip,
                          port: port.padLeft(5, '0'),
                          ip2: ip2,
                          port2: port2.padLeft(5, '0'),
                        );

                    final success = sent ? await _awaitWriteAck("013") : false;

                    if (!context.mounted) return;
                    ProgressDialog.dismiss(context); // Dismiss loader

                    if (!sent) {
                      _showFeedback(
                        context,
                        "Could not send request: device not connected.",
                      );
                    } else if (success) {
                      _showFeedback(
                        context,
                        "Destination IP updated successfully.",
                      );
                      setState(() {
                        _destinationIPResponse = null;
                      });
                    } else {
                      _showFeedback(
                        context,
                        "Failed to update Destination IP.",
                      );
                    }
                  },
                  child: const Text(
                    "UPDATE",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Telephone Settings are now handled in a dedicated full-screen file.

  // Field text builder helper
  Widget _buildField(
    String label,
    TextEditingController controller, {
    int? maxLength,
    bool isNumber = true,
    bool readOnly = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: true,
      showCursor: !readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: readOnly ? Colors.grey.shade600 : Colors.black87,
      ),
      inputFormatters:
          isNumber && !readOnly
              ? [
                FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ]
              : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        filled: true,
        fillColor: readOnly ? const Color(0xFFF0F1F3) : Colors.white,
        labelStyle: TextStyle(
          color: readOnly ? Colors.grey.shade400 : Colors.grey,
          fontFamily: 'Montserrat',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon:
            icon != null
                ? Icon(
                  icon,
                  color: readOnly ? Colors.grey.shade400 : Colors.grey.shade600,
                  size: 20,
                )
                : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey.shade300 : AppColors.colorPrimary,
            width: readOnly ? 1 : 1.5,
          ),
        ),
      ),
    );
  }
}

class _GridOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _GridOption({required this.title, required this.icon, required this.onTap});
}

class _GridBox extends StatelessWidget {
  final _GridOption option;

  const _GridBox({required this.option});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: 32, color: AppColors.colorPrimary),
              const SizedBox(height: 12),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
