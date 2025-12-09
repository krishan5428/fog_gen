import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/core/data/pojo/panel_data.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/responsive.dart';
import '../cubit/mappings/panel_sim_number_cubit.dart';
import '../cubit/mappings/site_cubit.dart';
import '../cubit/panel/panel_cubit.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/vertical_gap.dart';

class EditPanelScreen extends StatefulWidget {
  final PanelData panelData;
  const EditPanelScreen({super.key, required this.panelData});

  @override
  State<EditPanelScreen> createState() => _EditPanelScreenState();
}

class _EditPanelScreenState extends State<EditPanelScreen> {
  late final PanelFormControllers formControllers;
  late PanelData panelData;
  List<String> siteNames = [];
  List<String> panelSimNumbers = [];

  @override
  void initState() {
    super.initState();
    panelData = widget.panelData;
    formControllers = PanelFormControllers();

    formControllers.siteNameController.text = widget.panelData.site;
    formControllers.panelSimNumberController.text =
        widget.panelData.panelSimNumber;
    formControllers.ipAddressController.text = widget.panelData.ip_address;
    formControllers.portNumberController.text = widget.panelData.port_no;
    formControllers.staticIpController.text =
        widget.panelData.static_ip_address;
    formControllers.staticPortController.text = widget.panelData.static_port_no;
    formControllers.passwordController.text = widget.panelData.password;
  }

  @override
  void dispose() {
    formControllers.dispose();
    super.dispose();
  }

  bool _validateFields(bool isIPPanel, bool isIPGPRSPanel) {
    final siteName = formControllers.siteNameController.text.trim();
    final simNumber = formControllers.panelSimNumberController.text.trim();
    final ipAddress = formControllers.ipAddressController.text.trim();
    final port = formControllers.portNumberController.text.trim();
    final staticIP = formControllers.staticIpController.text.trim();
    final staticPort = formControllers.staticPortController.text.trim();
    final password = formControllers.passwordController.text.trim();

    if (siteName.isEmpty) {
      SnackBarHelper.showSnackBar(context, "Site Name cannot be empty");
      return false;
    }

    if (siteNames.contains(siteName)) {
      SnackBarHelper.showSnackBar(
        context,
        'Site name "$siteName" already exists.',
      );
      return false;
    }

    if (panelSimNumbers.contains(simNumber)) {
      SnackBarHelper.showSnackBar(
        context,
        'Panel sim number "$simNumber" already exists.',
      );
      return false;
    }

    if (!isIPPanel && simNumber.isEmpty) {
      SnackBarHelper.showSnackBar(context, "Panel SIM Number cannot be empty");
      return false;
    }

    if (isIPPanel) {
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipRegex.hasMatch(ipAddress)) {
        SnackBarHelper.showSnackBar(
          context,
          "Enter a valid IP Address (e.g., 192.168.1.1)",
        );
        return false;
      }
      if (port.isEmpty || int.tryParse(port) == null || int.parse(port) <= 0) {
        SnackBarHelper.showSnackBar(context, "Enter a valid Port Number");
        return false;
      }
      if (staticIP.isNotEmpty && !ipRegex.hasMatch(staticIP)) {
        SnackBarHelper.showSnackBar(context, "Enter a valid Static IP Address");
        return false;
      }
      if (staticPort.isNotEmpty &&
          (int.tryParse(staticPort) == null || int.parse(staticPort) <= 0)) {
        SnackBarHelper.showSnackBar(
          context,
          "Enter a valid Static Port Number",
        );
        return false;
      }
      if (password.isEmpty ||
          password.length != 4 ||
          int.tryParse(password) == null) {
        SnackBarHelper.showSnackBar(context, "Password must be 4 digits");
        return false;
      }
    }
    return true;
  }

  Future<void> _savePanel() async {
    final isIPPanel = widget.panelData.is_ip_panel;
    final isIPGPRSPanel = widget.panelData.is_ip_gsm_panel;

    if (!_validateFields(isIPPanel, isIPGPRSPanel)) return;

    try {
      context.read<PanelCubit>().updatePanelDataList(
        userId: widget.panelData.userId,
        panelId: widget.panelData.pnlId,
        keys: [
          'site',
          'panel_sim_number',
          'ip_address',
          'port_no',
          'static_ip_address',
          'static_port_no',
          'password',
        ],
        values: [
          formControllers.siteNameController.text.trim(),
          formControllers.panelSimNumberController.text.trim(),
          formControllers.ipAddressController.text.trim(),
          formControllers.portNumberController.text.trim(),
          formControllers.staticIpController.text.trim(),
          formControllers.staticPortController.text.trim(),
          formControllers.passwordController.text.trim(),
        ],
      );
    } catch (e) {
      SnackBarHelper.showSnackBar(context, "Failed to update panel: $e");
    }
  }

  void _savingAndNavigating(PanelData updatedData) async {
    SnackBarHelper.showSnackBar(context, "Panel updated successfully");
    await Future.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) return;
    CustomNavigation.instance.popWithResult(context: context,result: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);
    siteNames = context.watch<SiteCubit>().state;
    panelSimNumbers = context.watch<PanelSimNumberCubit>().state;

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if (state is UpdatePanelsSuccess) {
          debugPrint('update panel data success');
          _savingAndNavigating(state.panelData);
        } else if (state is UpdatePanelsFailure) {
          debugPrint('update panel data failure');
          SnackBarHelper.showSnackBar(context, 'Failed to update panel data');
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(pageName: 'Edit Panel', isFilter: false),
        backgroundColor: AppColors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box (fixed at top)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.litePrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info, color: AppColors.colorPrimary, size: 14),
                  SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      "Please fill out the form below with panel details...",
                      style: TextStyle(
                        color: AppColors.colorPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: formControllers.siteNameController,
                        hintText: 'Site Name',
                        maxLength: 40,
                      ),
                      const SizedBox(height: 12),

                      if (!widget.panelData.is_ip_gsm_panel)
                        CustomTextField(
                          controller: formControllers.panelSimNumberController,
                          hintText: 'Panel SIM Number',
                          maxLength: 13,
                        ),

                      if (widget.panelData.is_ip_panel || widget.panelData.is_ip_gsm_panel) ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          hintText: 'IP Address',
                          maxLength: 15,
                          controller: formControllers.ipAddressController,
                        ),
                        VerticalSpace(height: spacingBwtView * 1.2),
                        CustomTextField(
                          hintText: 'Port Number',
                          isNumber: true,
                          maxLength: 5,
                          controller: formControllers.portNumberController,
                        ),
                        VerticalSpace(height: spacingBwtView * 1.2),
                        CustomTextField(
                          hintText: 'Static IP Address',
                          isNumber: true,
                          maxLength: 15,
                          controller: formControllers.staticIpController,
                        ),
                        VerticalSpace(height: spacingBwtView * 1.2),
                        CustomTextField(
                          hintText: 'Static Port Number',
                          isNumber: true,
                          maxLength: 5,
                          controller: formControllers.staticPortController,
                        ),
                        VerticalSpace(height: spacingBwtView * 1.2),
                        CustomTextField(
                          hintText: 'Password',
                          isNumber: true,
                          maxLength: 4,
                          controller: formControllers.passwordController,
                        ),
                      ],

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: "BACK",
                              onPressed: () => CustomNavigation.instance.pop(context),
                              backgroundColor: AppColors.litePrimary,
                              foregroundColor: AppColors.colorPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              buttonText: "SAVE",
                              onPressed: _savePanel,
                            ),
                          ),
                        ],
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
}

class PanelFormControllers {
  final siteNameController = TextEditingController();
  final panelSimNumberController = TextEditingController();
  final ipAddressController = TextEditingController();
  final portNumberController = TextEditingController();
  final staticIpController = TextEditingController();
  final staticPortController = TextEditingController();
  final passwordController = TextEditingController();

  void dispose() {
    siteNameController.dispose();
    panelSimNumberController.dispose();
    ipAddressController.dispose();
    portNumberController.dispose();
    staticIpController.dispose();
    staticPortController.dispose();
    passwordController.dispose();
  }
}
