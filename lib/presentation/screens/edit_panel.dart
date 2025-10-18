import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/responsive.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/vertical_gap.dart';

class EditPanelScreen extends StatefulWidget {
  const EditPanelScreen({super.key});

  @override
  State<EditPanelScreen> createState() => _EditPanelScreenState();
}

class _EditPanelScreenState extends State<EditPanelScreen> {
  late final PanelFormControllers formControllers;

  @override
  void initState() {
    super.initState();
    formControllers = PanelFormControllers();
    final panel = context.read<PanelViewModel>().currentPanel;

    if (panel != null) {
      formControllers.siteNameController.text = panel.siteName;
      formControllers.panelSimNumberController.text = panel.panelSimNumber;
      formControllers.ipAddressController.text = panel.ipAddress;
      formControllers.portNumberController.text = panel.port;
      formControllers.staticIpController.text = panel.staticIPAddress;
      formControllers.staticPortController.text = panel.staticPort;
      formControllers.passwordController.text = panel.ipPassword;
    }
  }

  @override
  void dispose() {
    formControllers.dispose();
    super.dispose();
  }

  bool _validateFields(bool isIPPanel) {
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
    final panelViewModel = context.read<PanelViewModel>();
    final panel = panelViewModel.currentPanel;

    if (panel == null) return;

    final isIPPanel = panel.isIPPanel;

    if (!_validateFields(isIPPanel)) return;

    try {
      final updated = await panelViewModel.updatePanelDetails(
        siteName: formControllers.siteNameController.text.trim(),
        simNumber:
            isIPPanel
                ? ''
                : formControllers.panelSimNumberController.text.trim(),
        ipAddress: formControllers.ipAddressController.text.trim(),
        port: formControllers.portNumberController.text.trim(),
        staticIP: formControllers.staticIpController.text.trim(),
        staticPort: formControllers.staticPortController.text.trim(),
        pass: formControllers.passwordController.text.trim(),
      );

      if (updated) {
        await panelViewModel.refreshPanel(panel.panelSimNumber);
        if (mounted) {
          SnackBarHelper.showSnackBar(context, "Panel updated successfully");
          await Future.delayed(const Duration(milliseconds: 500));
          CustomNavigation.instance.pushAndRemove(
            context: context,
            screen: PanelListPage(),
          );
        }
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(context, "Failed to update panel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);
    return Consumer<PanelViewModel>(
      builder: (context, viewModel, child) {
        final panel = viewModel.currentPanel;

        if (panel == null) {
          return const Scaffold(body: Center(child: Text("No panel selected")));
        }

        return Scaffold(
          appBar: const CustomAppBar(pageName: 'Edit Panel', isFilter: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Info box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                const SizedBox(height: 12),

                // Form fields
                CustomTextField(
                  controller: formControllers.siteNameController,
                  hintText: 'Site Name',
                  maxLength: 40,
                ),
                const SizedBox(height: 12),

                if (!panel.isIPPanel)
                  CustomTextField(
                    controller: formControllers.panelSimNumberController,
                    hintText: 'Panel SIM Number',
                    maxLength: 13,
                  ),

                if (panel.isIPPanel) ...[
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
        );
      },
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
