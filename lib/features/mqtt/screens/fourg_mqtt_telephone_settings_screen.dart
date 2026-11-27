import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/features/mqtt/services/admin_number_sync.dart';
import 'package:fog_gen_new/presentation/cubit/panel/panel_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

class FourGMqttTelephoneSettingsScreen extends StatefulWidget {
  final PanelData panelData;
  final FourGRepository fourGRepository;

  const FourGMqttTelephoneSettingsScreen({
    super.key,
    required this.panelData,
    required this.fourGRepository,
  });

  @override
  State<FourGMqttTelephoneSettingsScreen> createState() =>
      _FourGMqttTelephoneSettingsScreenState();
}

class _FourGMqttTelephoneSettingsScreenState
    extends State<FourGMqttTelephoneSettingsScreen> {
  final List<_TelephoneData> _tempNumbers = [];
  final List<TextEditingController> _controllers = [];
  final List<TextEditingController> _ccControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Manual load: only fires once this screen is actually opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTelephoneSettings();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var controller in _ccControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchTelephoneSettings() async {
    setState(() => _isLoading = true);
    ProgressDialog.show(context, message: "Reading Telephone Settings...");

    final response = await widget.fourGRepository.readTelephoneSettings(
      imei: widget.panelData.panelImei,
      passcode: widget.panelData.pass,
    );

    if (mounted) {
      ProgressDialog.dismiss(context);
      setState(() {
        _isLoading = false;
        if (response != null) {
          _parseResponse(response);
        } else {
          _showToast("Read Timeout: Could not fetch Telephone Settings.");
        }
      });

      if (_tempNumbers.isNotEmpty) {
        final panelAdmin = _tempNumbers[0].number;
        if (panelAdmin.isEmpty) {
          // e.g. an add that was interrupted after the device was saved to
          // the account but before the admin number reached the panel.
          _offerAdminRestore();
        } else {
          // If the admin number was changed some other way (keypad, another
          // app, an older build), bring the server copy back in line.
          _syncAdminToServer(panelAdmin);
        }
      }
    }
  }

  /// The panel has no admin number but the account does — offer to write
  /// the account's number back to the panel.
  Future<void> _offerAdminRestore() async {
    final accountAdmin = AdminNumberSync.knownServerAdmin(widget.panelData);
    if (accountAdmin.length != 10 || int.tryParse(accountAdmin) == null) {
      return;
    }

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Admin number missing on device",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        content: Text(
          "The device has no admin number, so it won't send alerts to "
          "anyone. Restore the admin number from your account "
          "(+91 $accountAdmin)?",
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "NOT NOW",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "RESTORE",
              style: TextStyle(
                color: AppColors.colorPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
    if (restore != true || !mounted) return;

    ProgressDialog.show(context, message: "Restoring admin number...");
    final result = await AdminNumberSync.writeToPanel(
      fourGRepository: widget.fourGRepository,
      imei: widget.panelData.panelImei,
      passcode: widget.panelData.pass,
      adminNumber: accountAdmin,
    );
    if (!mounted) return;
    await ProgressDialog.dismiss(context);
    if (!mounted) return;

    if (!result.isSuccess) {
      _showToast("Could not restore admin number: ${result.failureReason}.");
      return;
    }

    // Mirror what writeToPanel set on slot 0, without re-reading the panel
    // while it may still be finishing the write.
    setState(() {
      final admin = _tempNumbers[0];
      if (!const {"2", "3", "4"}.contains(admin.ability)) admin.ability = "4";
      if (admin.countryCode.isEmpty ||
          admin.countryCode == "-" ||
          admin.countryCode == "NO CODE") {
        admin.countryCode = "+91";
        _ccControllers[0].text = "+91";
      }
      admin.number = accountAdmin;
      _controllers[0].text = accountAdmin;
    });
    _showToast(
      "Admin number restored on the device.",
      type: ToastificationType.success,
    );
  }

  void _parseResponse(String response) {
    final parts = response.split('\$');
    // 11 entries total (Admin + Tele1-10), at parts[5]..parts[15] — need
    // at least 16 elements to safely reach the last one.
    if (parts.length < 16) {
      _showToast("Unexpected response format from device.");
      return;
    }

    _tempNumbers.clear();
    _controllers.clear();
    _ccControllers.clear();

    setState(() {
      // index 0 = Admin, indices 1-10 = Tel. No. 1-10 (protocol Section 9).
      for (int i = 0; i < 11; i++) {
        final rawPart = parts[i + 5].replaceAll("*ED", "");
        final subparts = rawPart.split('#');
        String ability = "0";
        String cc = "+91";
        String number = "0";

        if (subparts.length >= 3) {
          ability = subparts[0];
          cc = subparts[1];
          number = subparts[2];
        }

        final parsedNumber = number == "0" ? "" : number;
        _tempNumbers.add(
          _TelephoneData(
            ability: ability,
            countryCode: cc,
            number: parsedNumber,
          ),
        );

        _controllers.add(TextEditingController(text: parsedNumber));
        _ccControllers.add(TextEditingController(text: cc));
      }
    });
  }

  void _showToast(
    String message, {
    ToastificationType type = ToastificationType.error,
  }) {
    if (!mounted) return;
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
        message,
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 12.sp),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  /// The panel is the source of truth for the admin number; keep the
  /// server's display copy in line with it (see [AdminNumberSync]).
  void _syncAdminToServer(String adminNumber) {
    if (adminNumber.length != 10) return;
    AdminNumberSync.syncToServer(
      panelCubit: context.read<PanelCubit>(),
      panel: widget.panelData,
      adminNumber: adminNumber,
    );
  }

  Future<void> _saveAllSettings() async {
    final adminNum = _controllers[0].text.trim();

    // 1. Admin Number Validation
    if (adminNum.isEmpty) {
      _showToast("Admin number cannot be empty.");
      return;
    }
    if (adminNum.length != 10) {
      _showToast("Admin number must be exactly 10 digits.");
      return;
    }

    // 2. Validate format of other telephone numbers & check uniqueness
    final Set<String> uniqueNumbers = {adminNum};

    for (int i = 1; i < 11; i++) {
      final numText = _controllers[i].text.trim();
      if (numText.isEmpty) continue; // Skip empty fields

      if (numText.length != 10) {
        _showToast("Telephone Number $i must be exactly 10 digits.");
        return;
      }

      // Check if Admin Number is reused
      if (numText == adminNum) {
        _showToast("Admin number cannot be used in Telephone Number $i.");
        return;
      }

      // Check for duplicates
      if (uniqueNumbers.contains(numText)) {
        _showToast(
          "Duplicate number found: '$numText' is used more than once.",
        );
        return;
      }

      uniqueNumbers.add(numText);
    }

    final List<String> formatted = [];
    // 11 entries total (Admin + Tele1-10) — must match what was read.
    for (int i = 0; i < 11; i++) {
      final numText = _controllers[i].text.trim();
      var ccText = _ccControllers[i].text.trim();
      final ability = _tempNumbers[i].ability;

      // Per protocol (Section 9): the panel echoes "-" for a blank country
      // code on read, but rejects a literal "-" on write — rewrite it, and
      // rewrite an empty code to the literal "NO CODE" (a bare empty field
      // between the two "#" delimiters is malformed).
      if (ccText == "-") {
        ccText = "+91";
      } else if (ccText.isEmpty) {
        ccText = "NO CODE";
      }

      if (numText.isEmpty) {
        formatted.add("0#$ccText#0");
      } else {
        formatted.add("$ability#$ccText#$numText");
      }
    }

    ProgressDialog.show(context, message: "Updating telephone settings...");

    var sent = true;
    final ack = await AdminNumberSync.sendAndAwaitWriteAck(
      mqttRepository: widget.fourGRepository.mqttService.mqttRepository,
      imei: widget.panelData.panelImei,
      send: () async {
        sent = await widget.fourGRepository.assignAdminNumbers(
          imei: widget.panelData.panelImei,
          passcode: widget.panelData.pass,
          formattedNumbers: formatted,
        );
        return sent;
      },
    );
    final success = ack == true;

    if (!mounted) return;
    await ProgressDialog.dismiss(context);
    if (!mounted) return;

    if (!sent) {
      _showToast("Could not send request: device not connected.");
    } else if (success) {
      // Panel confirmed — now the server copy can follow.
      _syncAdminToServer(adminNum);
      _showToast(
        "Telephone settings saved successfully.",
        type: ToastificationType.success,
      );
      Navigator.pop(context, true); // Return true to trigger cache updates
    } else {
      _showToast("Failed to update telephone settings.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        pageName: 'Telephone Settings',
        isFilter: false,
        isDash: false,
        onBack: () => Navigator.pop(context),
      ),
      body: _isLoading && _tempNumbers.isEmpty
          ? const SizedBox.shrink()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _tempNumbers.length,
                    itemBuilder: (context, index) {
                      return _buildTelephoneCard(index);
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.colorPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _saveAllSettings,
                            child: const Text(
                              "SAVE ALL",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTelephoneCard(int index) {
    final data = _tempNumbers[index];
    // Per protocol (Section 9): 0=Disable 2=SMS 3=Call 4=SMS+Call.
    // Was previously missing "Call" (3) entirely and mislabeling "2" as
    // "Call" instead of "SMS" — selecting the UI's "Call" option actually
    // wrote wire value 2 (SMS), so there was no way to get SMS-only alerts
    // to actually work, and no way to reach true Call-only (3) at all.
    final List<Map<String, String>> alertOptions = [
      {'value': '0', 'label': 'Disable'},
      {'value': '2', 'label': 'SMS'},
      {'value': '3', 'label': 'Call'},
      {'value': '4', 'label': 'SMS & Call'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index == 0
                ? "Admin"
                : "Tel. No. ${index.toString().padLeft(2, '0')}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              fontFamily: 'Montserrat',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Row 1: Country Code & Mobile Number
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _ccControllers[index],
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    hintText: '+91',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mobile number input
              Expanded(
                child: TextFormField(
                  controller: _controllers[index],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(index == 0 ? 10 : 10),
                  ],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: index == 0
                        ? '10 digit number'
                        : '10 digit number',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Alert Mode Dropdown (takes full width, zero overflow risk)
          DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue:
                  alertOptions.any((opt) => opt['value'] == data.ability)
                  ? data.ability
                  : '0',
              decoration: InputDecoration(
                labelText: 'Alert Mode',
                labelStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13.sp,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.colorPrimary),
                ),
              ),
              items: alertOptions
                  .map(
                    (opt) => DropdownMenuItem(
                      value: opt['value'],
                      child: Text(
                        opt['label']!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    data.ability = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TelephoneData {
  String ability;
  String countryCode;
  String number;

  _TelephoneData({
    required this.ability,
    required this.countryCode,
    required this.number,
  });
}
