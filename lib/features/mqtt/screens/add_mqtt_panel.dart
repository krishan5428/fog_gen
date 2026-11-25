// ignore_for_file: use_build_context_synchronously
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'package:fog_gen_new/features/mqtt/screens/imei_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';
import 'package:fog_gen_new/presentation/widgets/custom_button.dart';
import 'package:fog_gen_new/presentation/widgets/form_section.dart';
import 'package:fog_gen_new/presentation/widgets/vertical_gap.dart';
import 'package:toastification/toastification.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';

class AddMqttPanelPage extends StatefulWidget {
  final String panelType;
  final String panelName;

  const AddMqttPanelPage({
    super.key,
    required this.panelType,
    required this.panelName,
  });

  @override
  State<AddMqttPanelPage> createState() => _AddMqttPanelPageState();
}

class _AddMqttPanelPageState extends State<AddMqttPanelPage> {
  final _logger = Logger();

  final siteController = TextEditingController();

  final imeiController = TextEditingController();

  final passwordController = TextEditingController();

  final adminNumberController = TextEditingController();

  final simNumberController = TextEditingController();

  final addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        _logger.d("📢 STATE: ${state.runtimeType}");

        if (state is AddPanelSuccess) {
          _logger.i("✅ AddPanelSuccess received");
          ProgressDialog.dismiss(context);
          _showToast(
            "Device Added Successfully",
            type: ToastificationType.success,
          );
          Navigator.pop(context);
        }

        if (state is AddPanelFailure) {
          _logger.w("❌ AddPanelFailure received");
          ProgressDialog.dismiss(context);
          _showToast(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          pageName: 'Add Device Details',
          isFilter: false,
          isDash: false,
          onBack: () {
            Navigator.pop(context);
          },
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.litePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.info, size: 15, color: AppColors.colorPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Please add the device with Specific Device Details...',
                    style: TextStyle(
                      color: AppColors.colorPrimary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    children: [
                      FormSection(
                        label: "Site Name",
                        controller: siteController,
                        maxLength: 15,
                      ),

                      const VerticalSpace(height: 10),

                      FormSection(
                        label: "Device IMEI",
                        controller: imeiController,
                        maxLength: 15,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.colorPrimary,
                          ),
                          onPressed: () async {
                            final scannedImei = await showImeiScanner(context);
                            if (scannedImei != null && mounted) {
                              setState(() {
                                imeiController.text = scannedImei;
                              });
                            }
                          },
                        ),
                      ),

                      const VerticalSpace(height: 10),

                      FormSection(
                        label: "Password",
                        controller: passwordController,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                      ),

                      const VerticalSpace(height: 10),

                      FormSection(
                        label: "Admin SIM Number",
                        controller: adminNumberController,
                        maxLength: 10,
                        keyboardType: TextInputType.number,
                      ),

                      const VerticalSpace(height: 10),

                      FormSection(
                        label: "Device SIM Number",
                        controller: simNumberController,
                        maxLength: 13,
                        keyboardType: TextInputType.number,
                      ),

                      const VerticalSpace(height: 10),

                      FormSection(
                        label: "Address",
                        controller: addressController,
                        maxLength: 40,
                      ),

                      const VerticalSpace(height: 15),

                      CustomButton(
                        buttonText: "SAVE DEVICE",
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(
    String message, {
    ToastificationType type = ToastificationType.error,
  }) {
    if (!mounted) return;

    // Remove developer-facing exception prefixes
    String cleanMessage = message.trim();
    if (cleanMessage.startsWith("Exception: ")) {
      cleanMessage = cleanMessage.replaceFirst("Exception: ", "").trim();
    }

    // Capitalize the first letter
    if (cleanMessage.isNotEmpty) {
      cleanMessage = cleanMessage[0].toUpperCase() + cleanMessage.substring(1);
    }

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        type == ToastificationType.success ? 'Success' : 'Error',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
      description: Text(
        cleanMessage,
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.sp),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _submit() async {
    final siteName = siteController.text.trim();
    final imei = imeiController.text.trim();
    final password = passwordController.text.trim();
    final adminNum = adminNumberController.text.trim();
    final simNum = simNumberController.text.trim();
    final address = addressController.text.trim();

    final siteNames = context.read<SiteCubit>().state;
    final panelSimNumbers = context.read<PanelSimNumberCubit>().state;

    final panelState = context.read<PanelCubit>().state;
    List<String> existingImeis = [];
    if (panelState is GetPanelsSuccess) {
      existingImeis =
          panelState.panelsData.map((p) => p.panelImei.trim()).toList();
    }

    // 1. Site Name Validation
    if (siteName.isEmpty) {
      _showToast("Site Name cannot be empty.");
      return;
    }
    if (siteName.length > 15) {
      _showToast("Site Name cannot exceed 15 characters.");
      return;
    }
    if (siteNames.contains(siteName)) {
      _showToast('Site name "$siteName" already exists.');
      return;
    }

    // 2. Panel IMEI Validation
    if (imei.isEmpty) {
      _showToast("Device IMEI cannot be empty.");
      return;
    }
    if (imei.length != 15 || int.tryParse(imei) == null) {
      _showToast("Device IMEI must be exactly 15 digits.");
      return;
    }
    if (existingImeis.contains(imei)) {
      _showToast('Device IMEI "$imei" already exists.');
      return;
    }

    // 3. Password Validation
    if (password.isEmpty) {
      _showToast("Password cannot be empty.");
      return;
    }
    if (password.length != 4 || int.tryParse(password) == null) {
      _showToast("Password must be exactly 4 digits.");
      return;
    }

    // 4. Admin Number Validation
    if (adminNum.isEmpty) {
      _showToast("Admin Number cannot be empty.");
      return;
    }
    if (adminNum.length != 10 || int.tryParse(adminNum) == null) {
      _showToast("Admin Number must be exactly 10 digits.");
      return;
    }

    // 5. SIM Number Validation
    if (simNum.isEmpty) {
      _showToast("SIM Number cannot be empty.");
      return;
    }
    if ((simNum.length != 10 && simNum.length != 13) ||
        int.tryParse(simNum) == null) {
      _showToast("SIM Number must be either 10 or 13 digits.");
      return;
    }
    if (adminNum == simNum) {
      _showToast("Admin number and SIM number must be different.");
      return;
    }
    final formattedSimNum =
        simNum.length == 13 && simNum.startsWith('+91')
            ? simNum.substring(3)
            : simNum;
    if (panelSimNumbers.contains(formattedSimNum) ||
        panelSimNumbers.contains(simNum)) {
      _showToast('Device SIM number "$simNum" already exists.');
      return;
    }

    // 6. Address Validation
    if (address.isEmpty) {
      _showToast("Address cannot be empty.");
      return;
    }
    if (address.length > 40) {
      _showToast("Address cannot exceed 40 characters.");
      return;
    }

    final userId = await SharedPreferenceHelper.getUserId();

    if (mounted) {
      ProgressDialog.show(context, message: "Saving device details...");
    }

    context.read<PanelCubit>().addPanel(
      userId: userId.toString(),

      // Persisted as its own pnl_type (not the FIRE PANEL/FIRE DIALERS
      // category widget.panelType carries) so the backend can gate the
      // MQTT vs TCP notification pipelines on pnl_type alone.
      panelType: '4GCOM',

      panelName: widget.panelName,

      site: siteController.text,

      panelSimNumber: simNumberController.text.trim(),

      adminCode: "1234",

      adminMobileNumber: adminNumberController.text,

      mobileNumberSubId: "0",

      mobileNumber1: "0000000000",

      mobileNumber2: "0000000000",

      mobileNumber3: "0000000000",

      mobileNumber4: "0000000000",

      mobileNumber5: "0000000000",

      mobileNumber6: "0000000000",

      mobileNumber7: "0000000000",

      mobileNumber8: "0000000000",

      mobileNumber9: "0000000000",

      mobileNumber10: "0000000000",

      address: addressController.text,

      cOn: DateTime.now().toString(),

      password: passwordController.text,

      imei: imeiController.text,

      ip_address: "",
      port_no: "",
      static_ip_address: "",
      static_port_no: "",

      is_ip_panel: false,
      is_ip_gsm_panel: false,

      // Generated by the server for G4 panels (written to the device after save).
      panel_acc_no: "",
      mac_id: "",
      version: "",
    );
  }
}
