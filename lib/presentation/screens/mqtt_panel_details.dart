// ignore_for_file: unused_element, use_build_context_synchronously
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/features/mqtt/services/admin_number_sync.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';
import 'package:fog_gen_new/presentation/widgets/custom_button.dart';
import '../cubit/panel/panel_cubit.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'panel_list/panel_list.dart';
import '../cubit/mappings/panel_sim_number_cubit.dart';
import '../cubit/mappings/site_cubit.dart';

class MqttPanelDetailsScreen extends StatefulWidget {
  final PanelData panelData;
  const MqttPanelDetailsScreen({super.key, required this.panelData});

  @override
  State<MqttPanelDetailsScreen> createState() => _MqttPanelDetailsScreenState();
}

class _MqttPanelDetailsScreenState extends State<MqttPanelDetailsScreen> {
  late final TextEditingController siteNameController;
  late final TextEditingController siteAddressController;
  late final TextEditingController imeiController;
  late final TextEditingController panelSimController;
  late final TextEditingController adminSimController;

  DateTime? startDate;
  DateTime? endDate;
  int daysUsed = 0;
  int daysRemaining = 365;
  double progress = 0.0;

  String _userRole = 'customer';

  @override
  void initState() {
    super.initState();
    siteNameController = TextEditingController(text: widget.panelData.siteName);
    siteAddressController = TextEditingController(
      text: widget.panelData.siteAddress,
    );
    imeiController = TextEditingController(text: widget.panelData.panelImei);
    panelSimController = TextEditingController(
      text: widget.panelData.panelSimNumber,
    );
    adminSimController = TextEditingController(
      text: widget.panelData.adminMobileNumber,
    );

    _calculateWarranty();
    _loadUserRole();
  }

  // FogShield has no user roles yet; every user is a 'customer', so the
  // FireNex factory-worker "Release to market" variant never shows.
  void _loadUserRole() {}

  bool get _isFactoryWorker =>
      _userRole == 'factory_worker' || _userRole == 'tester';

  @override
  void dispose() {
    siteNameController.dispose();
    siteAddressController.dispose();
    imeiController.dispose();
    panelSimController.dispose();
    adminSimController.dispose();
    super.dispose();
  }

  void _calculateWarranty() {
    try {
      if (widget.panelData.cOn.isNotEmpty) {
        startDate = DateTime.tryParse(widget.panelData.cOn);
      }
    } catch (_) {}

    startDate ??= DateTime.now();
    endDate = DateTime(
      startDate!.year + 1,
      startDate!.month,
      startDate!.day,
      startDate!.hour,
      startDate!.minute,
      startDate!.second,
    );

    final now = DateTime.now();
    if (now.isAfter(startDate!)) {
      daysUsed = now.difference(startDate!).inDays;
    } else {
      daysUsed = 0;
    }

    if (endDate!.isAfter(now)) {
      daysRemaining = endDate!.difference(now).inDays;
    } else {
      daysRemaining = 0;
    }

    daysUsed = daysUsed.clamp(0, 365);
    daysRemaining = daysRemaining.clamp(0, 365);
    progress = (daysUsed / 365).clamp(0.0, 1.0);
  }

  void _showToast({
    required String message,
    required ToastificationType type,
    String? title,
  }) {
    if (!mounted) return;

    // Resolve correct title text based on type
    String resolvedTitle = title ?? 'Error';
    if (title == null) {
      if (type == ToastificationType.success) {
        resolvedTitle = 'Success';
      } else if (type == ToastificationType.warning) {
        resolvedTitle = 'Warning';
      } else if (type == ToastificationType.info) {
        resolvedTitle = 'Info';
      }
    }

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        resolvedTitle,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
          color: Colors.white,
        ),
      ),
      description: Text(
        message,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12.sp,
          color: Colors.white,
        ),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  bool _validateFields() {
    final siteName = siteNameController.text.trim();
    final siteAddress = siteAddressController.text.trim();
    final simNumber = panelSimController.text.trim();
    final adminSimNumber = adminSimController.text.trim();
    final imei = imeiController.text.trim();

    // 1. Site Name Validation
    if (siteName.isEmpty) {
      _showToast(
        message: "Site Name cannot be empty",
        type: ToastificationType.error,
      );
      return false;
    }
    if (siteName.length > 15) {
      _showToast(
        message: "Site Name cannot exceed 15 characters",
        type: ToastificationType.error,
      );
      return false;
    }
    final siteNames = context.read<SiteCubit>().state;
    if (siteName != widget.panelData.siteName && siteNames.contains(siteName)) {
      _showToast(
        message: 'Site name "$siteName" already exists',
        type: ToastificationType.error,
      );
      return false;
    }

    if (siteAddress.isEmpty) {
      _showToast(
        message: "Site Address cannot be empty",
        type: ToastificationType.error,
      );
      return false;
    }
    if (siteAddress.length > 40) {
      _showToast(
        message: "Site Address cannot exceed 40 characters",
        type: ToastificationType.error,
      );
      return false;
    }

    // 2. SIM Number Validation
    if (simNumber.isEmpty) {
      _showToast(
        message: "Device SIM Number cannot be empty",
        type: ToastificationType.error,
      );
      return false;
    }
    if ((simNumber.length != 10 && simNumber.length != 13) ||
        int.tryParse(simNumber) == null) {
      _showToast(
        message: "Device SIM Number must be either 10 or 13 digits",
        type: ToastificationType.error,
      );
      return false;
    }
    final panelSimNumbers = context.read<PanelSimNumberCubit>().state;
    final formattedSim =
        simNumber.length == 13 && simNumber.startsWith('+91')
            ? simNumber.substring(3)
            : simNumber;
    final currentFormattedSim =
        widget.panelData.panelSimNumber.length == 13 &&
                widget.panelData.panelSimNumber.startsWith('+91')
            ? widget.panelData.panelSimNumber.substring(3)
            : widget.panelData.panelSimNumber;
    if (formattedSim != currentFormattedSim &&
        (panelSimNumbers.contains(formattedSim) ||
            panelSimNumbers.contains(simNumber))) {
      _showToast(
        message: 'Device SIM number "$simNumber" already exists',
        type: ToastificationType.error,
      );
      return false;
    }

    // 3. Admin SIM Number Validation
    if (adminSimNumber.isEmpty) {
      _showToast(
        message: "Admin SIM Number cannot be empty",
        type: ToastificationType.error,
      );
      return false;
    }
    if (adminSimNumber.length != 10 || int.tryParse(adminSimNumber) == null) {
      _showToast(
        message: "Admin SIM Number must be exactly 10 digits",
        type: ToastificationType.error,
      );
      return false;
    }

    // 4. Admin vs Device SIM conflict
    if (adminSimNumber == simNumber) {
      _showToast(
        message: "Admin SIM Number and Device SIM Number must be different",
        type: ToastificationType.error,
      );
      return false;
    }

    if (imei.isEmpty) {
      _showToast(
        message: "IMEI number cannot be empty",
        type: ToastificationType.error,
      );
      return false;
    }

    if (imei.length < 15) {
      _showToast(
        message: "IMEI number must be at least 15 digits",
        type: ToastificationType.error,
      );
      return false;
    }

    // 5. Check if any changes were made
    final isChanged =
        siteName != widget.panelData.siteName ||
        siteAddress != widget.panelData.siteAddress ||
        simNumber != widget.panelData.panelSimNumber ||
        adminSimNumber != widget.panelData.adminMobileNumber ||
        imei != widget.panelData.panelImei;

    if (!isChanged) {
      _showToast(
        message: "No changes made to update",
        type: ToastificationType.warning,
      );
      return false;
    }

    return true;
  }

  Future<void> _savePanel() async {
    if (!_validateFields()) return;

    final newAdmin = adminSimController.text.trim();
    final adminChanged = newAdmin != widget.panelData.adminMobileNumber.trim();

    // The admin number lives on the panel too (it's the number the panel
    // actually alerts). Panel first: if the panel doesn't confirm the new
    // number, nothing is saved — not even the other fields — so the panel
    // and the server can't drift apart.
    if (adminChanged) {
      ProgressDialog.show(
        context,
        message: "Updating admin number on device...",
      );
      final result = await AdminNumberSync.connectAndWriteToPanel(
        imei: widget.panelData.panelImei.trim(),
        passcode: widget.panelData.pass,
        adminNumber: newAdmin,
      );
      if (!mounted) return;
      await ProgressDialog.dismiss(context);
      if (!mounted) return;

      if (!result.isSuccess) {
        _showToast(
          title: "Admin number not changed",
          message:
              "${result.failureReason}. Make sure the device is online "
              "and try again. No changes were saved.",
          type: ToastificationType.error,
        );
        return;
      }
      AdminNumberSync.markSyncedToServer(widget.panelData, newAdmin);
    }

    ProgressDialog.show(context);

    context.read<PanelCubit>().updatePanelDataList(
      userId: widget.panelData.usrId,
      panelId: widget.panelData.pnlId,
      keys: const [
        'site_name',
        'site_address',
        'panel_imei',
        'panel_sim_number',
        'admin_mobile_number',
      ],
      values: [
        siteNameController.text.trim(),
        siteAddressController.text.trim(),
        imeiController.text.trim(),
        panelSimController.text.trim(),
        adminSimController.text.trim(),
      ],
    );
  }

  PanelData _buildUpdatedPanel() {
    return widget.panelData.copyWith(
      siteName: siteNameController.text.trim(),
      siteAddress: siteAddressController.text.trim(),
      panelImei: imeiController.text.trim(),
      panelSimNumber: panelSimController.text.trim(),
      adminMobileNumber: adminSimController.text.trim(),
    );
  }

  Future<void> _deletePanel() async {
    final firstConfirm = await showConfirmationDialog(
      context: context,
      message:
          _isFactoryWorker
              ? 'Are you sure you want to release this device to market?'
              : 'Are you sure you want to delete this device?',
    );
    if (firstConfirm != true) return;

    final secondConfirm = await showConfirmationDialog(
      context: context,
      message:
          _isFactoryWorker
              ? 'After releasing the Device, you will no longer have access to it.\nSure?'
              : 'After deleting the Device, you will not configure the device.\nSure?',
    );
    if (secondConfirm != true) return;

    final loggedInUserId = await SharedPreferenceHelper.getUserId();
    if (loggedInUserId == null && mounted) {
      _showToast(
        message: "Failed to retrieve User ID",
        type: ToastificationType.error,
      );
      return;
    }

    if (mounted) {
      ProgressDialog.show(context);
      context.read<PanelCubit>().deletePanel(
        userId: loggedInUserId.toString(),
        panelId: widget.panelData.pnlId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.panelData.shareStatus.toLowerCase() == 'accepted';

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) async {
        if (state is UpdatePanelsSuccess) {
          ProgressDialog.dismiss(context);
          final updatedPanel = _buildUpdatedPanel();
          _showToast(
            message: "Device updated successfully",
            type: ToastificationType.success,
          );
          CustomNavigation.instance.popWithResult(
            context: context,
            result: updatedPanel,
          );
        } else if (state is UpdatePanelsFailure) {
          ProgressDialog.dismiss(context);
          _showToast(
            message: "Failed to update device",
            type: ToastificationType.error,
          );
        } else if (state is DeletePanelsSuccess) {
          ProgressDialog.dismiss(context);
          await showInfoDialog(
            context: context,
            message: "The Device has been reset.",
            onOk: () {
              CustomNavigation.instance.pushReplace(
                context: context,
                screen: const PanelListPage(),
              );
            },
          );
        } else if (state is DeletePanelsFailure) {
          ProgressDialog.dismiss(context);
          _showToast(
            message: 'Delete Device failed: ${state.message}',
            type: ToastificationType.error,
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          pageName: 'Device Details',
          isFilter: false,
          isDash: false,
          onBack: () {
            CustomNavigation.instance.pop(context);
          },
        ),
        backgroundColor: const Color(0xFFF5F6F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description block
              Text(
                "Update Device Details",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Modify the connection details below.",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Category dropdown representation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.panelData.panelName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // IDENTIFICATION Section
              Text(
                "IDENTIFICATION",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Device ID Field (Read-only)
              if (widget.panelData.pnlAccNo.trim().isNotEmpty) ...[
                _buildTextField(
                  label: "Device ID",
                  controller: TextEditingController(
                    text: widget.panelData.pnlAccNo,
                  ),
                  icon: Icons.fingerprint,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
              ],

              // Site Name Field
              _buildTextField(
                label: "Site Name",
                controller: siteNameController,
                icon: Icons.location_on_outlined,
                maxLength: 15,
                readOnly: isGuest,
              ),
              const SizedBox(height: 16),

              // Site Address Field
              _buildTextField(
                label: "Site Address",
                controller: siteAddressController,
                icon: Icons.business_outlined,
                maxLength: 40,
                readOnly: isGuest,
              ),
              const SizedBox(height: 24),

              // DEVICE CONFIGURATION Section
              Text(
                "DEVICE CONFIGURATION",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // IMEI Number Field
              _buildTextField(
                label: "IMEI number",
                controller: imeiController,
                icon: Icons.tag,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Device SIM Number Field
              _buildTextField(
                label: "Device SIM Number",
                controller: panelSimController,
                icon: Icons.sim_card_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 13,
                readOnly: isGuest,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Admin SIM Number",
                controller: adminSimController,
                icon: Icons.sim_card_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                readOnly: isGuest,
              ),
              // const SizedBox(height: 24),

              // Warranty Details Card
              // _buildWarrantyCard(),
              const SizedBox(height: 28),

              // Actions Block
              if (!isGuest) ...[
                CustomButton(
                  buttonText: 'UPDATE DEVICE',
                  onPressed: _savePanel,
                  borderRadius: 12,
                  backgroundColor: const Color(0xFF232323),
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        _isFactoryWorker
                            ? Colors.blue
                            : Colors.red,
                    elevation: 0,
                    side: BorderSide(
                      color:
                          _isFactoryWorker
                              ? Colors.blue
                              : Colors.red,
                      width: 1.0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deletePanel,
                  icon: Icon(
                    _isFactoryWorker
                        ? Icons.send
                        : Icons.delete,
                    size: 18,
                  ),
                  label: Text(
                    _isFactoryWorker
                        ? "RELEASE TO MARKET"
                        : "DELETE DEVICE",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: readOnly ? Colors.grey.shade600 : Colors.black87,
      ),
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
        prefixIcon: Icon(
          icon,
          color: readOnly ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
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

  Widget _buildWarrantyCard() {
    final startDayStr =
        startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : '-';
    final startTimeStr =
        startDate != null ? DateFormat('HH:mm:ss').format(startDate!) : '-';
    final endDayStr =
        endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : '-';
    final endTimeStr =
        endDate != null ? DateFormat('HH:mm:ss').format(endDate!) : '-';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Warranty details card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Warranty Details",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "WARRANTY VALID",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date widgets row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Colors.blue,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "START DATE",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          startDayStr,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          startTimeStr,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.outlined_flag,
                              color: Colors.red,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "END DATE",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          endDayStr,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          endTimeStr,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress line
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
              ),
            ),
          ),

          // Days labels row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$daysUsed days used",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "$daysRemaining days remaining",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
