import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/dialog/progress_with_message.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/presentation/widgets/custom_button.dart';
import 'package:fog_gen_new/presentation/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/navigation.dart';
import '../../../utils/responsive.dart';
import '../../../utils/snackbar_helper.dart';
import '../../cubit/panel/panel_cubit.dart';
import '../../widgets/app_bar.dart';
import 'add_panel_view_model.dart';

class AddPanelFormScreen extends StatelessWidget {
  const AddPanelFormScreen({
    super.key,
    required this.panelType,
    required this.panelName,
  });

  final String panelType;
  final String panelName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddPanelViewModel(),
      child: _AddPanelFormBody(panelType: panelType, panelName: panelName),
    );
  }
}

class _AddPanelFormBody extends StatefulWidget {
  final String panelType;
  final String panelName;

  const _AddPanelFormBody({required this.panelType, required this.panelName});

  @override
  State<_AddPanelFormBody> createState() => _AddPanelFormBodyState();
}

class _AddPanelFormBodyState extends State<_AddPanelFormBody> {
  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final smallTextSize = Responsive.smallTextSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if (state is AddPanelSuccess) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(context, "Panel added successfully");
          CustomNavigation.instance.pushReplace(
            context: context,
            screen: const PanelListPage(),
          );
        } else if (state is AddPanelFailure) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(context, "Error: while adding panel");
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          pageName: 'Add Panel Details',
          isFilter: false,
          isDash: false,
          isProfile: false,
          onBack: () {
            CustomNavigation.instance.pushReplace(
              context: context,
              screen: const PanelListPage(),
            );
          },
        ),
        body: Column(
          children: [
            _buildInfoBar(fontSize, spacingBwtView),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacingBwtView * 1.2),
                child: Consumer<AddPanelViewModel>(
                  builder: (context, vm, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGeneralDetails(vm, fontSize, spacingBwtView),
                        SizedBox(height: spacingBwtView),
                        _buildGprsSettings(vm, fontSize, spacingBwtView),
                        _buildIpSettings(vm, fontSize, spacingBwtView),
                        SizedBox(height: spacingBwtView * 2.5),
                        _buildMandatoryNote(smallTextSize, spacingBwtView),
                        Center(
                          child: CustomButton(
                            buttonText: 'Save Panel',
                            backgroundColor: AppColors.colorPrimary,
                            foregroundColor: AppColors.white,
                            onPressed: () => _onSavePressed(context, vm),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSavePressed(
    BuildContext context,
    AddPanelViewModel vm,
  ) async {
    final siteNames = context.read<SiteCubit>().state;
    final simNumbers = context.read<PanelSimNumberCubit>().state;

    final validationError = vm.validateForm(
      existingSiteNames: siteNames,
      existingPanelSims: simNumbers,
    );

    if (validationError != null) {
      SnackBarHelper.showSnackBar(context, validationError);
      return;
    }

    ProgressDialog.show(context);
    final connectionStatus = await vm.connectToPanel();
    ProgressDialog.dismiss(context);

    bool proceedToSave = false;

    if (connectionStatus == ConnectionStatus.failed) {
      final bool? saveOffline = await showConfirmationDialog(
        context: context,
        message:
            "Could not connect to the panel to verify settings.\n\n"
            "This might be due to no internet or incorrect IP.\n"
            "Do you want to save this panel offline anyway?",
        title: "Connection Failed",
        cancelText: "Cancel",
        confirmText: "Save Offline",
      );

      if (!saveOffline!) return;
      proceedToSave = true;
    } else if (connectionStatus == ConnectionStatus.alreadyConnected) {
      final shouldDisconnect = await _showAlreadyConnectedDialog(context);
      if (shouldDisconnect) {
        final disconnected = await vm.forceDisconnect();
        if (disconnected) proceedToSave = true;
      }
    } else {
      proceedToSave = true;
    }

    if (!proceedToSave) return;

    final smsSent = await _handleNeuronPanels(
      context,
      panelNumber: vm.panelSimNumberController.text,
      adminNumber: vm.adminNumberController.text,
      address: vm.addressController.text,
    );

    if (!smsSent) {
      if (mounted) {
        showInfoDialog(context: context, message: 'SMS operation Cancelled');
      }
      return;
    }

    final panelData = await vm.prepareSaveData(
      panelType: widget.panelType,
      panelName: widget.panelName,
    );

    if (panelData != null && mounted) {
      ProgressDialog.show(context);

      // FIXED: Standardized keys and use ?? "" to prevent null errors
      context.read<PanelCubit>().addPanel(
        userId: panelData['usr_id'] ?? "",
        panelType: panelData['pnl_type'] ?? "",
        panelName: panelData['panel_name'] ?? "",
        site: panelData['site_name'] ?? "",
        panelSimNumber: panelData['panel_sim_number'] ?? "",
        adminCode: panelData['admin_code'] ?? "",
        adminMobileNumber: panelData['admin_mobile_number'] ?? "",
        mobileNumberSubId: panelData['mobile_number_sub_id'] ?? "",
        mobileNumber1: panelData['mobile_number1'] ?? "",
        mobileNumber2: panelData['mobile_number2'] ?? "",
        mobileNumber3: panelData['mobile_number3'] ?? "",
        mobileNumber4: panelData['mobile_number4'] ?? "",
        mobileNumber5: panelData['mobile_number5'] ?? "",
        mobileNumber6: panelData['mobile_number6'] ?? "",
        mobileNumber7: panelData['mobile_number7'] ?? "",
        mobileNumber8: panelData['mobile_number8'] ?? "",
        mobileNumber9: panelData['mobile_number9'] ?? "",
        mobileNumber10: panelData['mobile_number10'] ?? "",
        address: panelData['site_address'] ?? "",
        cOn: panelData['c_on'] ?? "",
        password: panelData['pass'] ?? "",
        ip_address: panelData['ip_add'] ?? "",
        is_ip_gsm_panel: panelData['is_ip_gsm_panel'] ?? false,
        is_ip_panel: panelData['is_ip_panel'] ?? false,
        port_no: panelData['port_no'] ?? "",
        static_ip_address: panelData['static_ip'] ?? "",
        static_port_no: panelData['static_port'] ?? "",
        // Added hardware info keys with fallbacks
        mac_id: panelData['pnl_mac'] ?? "",
        version: panelData['pnl_ver'] ?? "",
        panel_acc_no: panelData['pnl_acc_no'] ?? "",
      );
    }
  }

  Future<bool> _showAlreadyConnectedDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text("Connection Status"),
              content: const Text(
                "This panel appears to be already connected.",
              ),
              actions: [
                TextButton(
                  child: const Text(
                    "Force Disconnect",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _handleNeuronPanels(
    BuildContext context, {
    required String panelNumber,
    required String adminNumber,
    required String address,
  }) async {
    String message1 =
        '''
< 1234 TEL NO
#01-+91$adminNumber*
#02-+910000000000*
#03-+910000000000*
#04-+910000000000*
#05-+910000000000*
>
''';
    String message2 = '< 1234 SIGNATURE $address* >';

    try {
      final result = await ProgressDialogWithMessage.show(
        context,
        messages: [message1, message2],
        panelSimNumber: panelNumber,
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildInfoBar(double fontSize, double spacing) {
    return Container(
      color: AppColors.litePrimary,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing / 2),
      child: Row(
        children: [
          Icon(Icons.info, size: fontSize, color: AppColors.colorPrimary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Please add the panel with Specific Panel Details...',
              style: TextStyle(color: AppColors.colorPrimary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        Text(
          '*',
          style: TextStyle(color: AppColors.red, fontSize: fontSize),
        ),
      ],
    );
  }

  Widget _buildMandatoryNote(double smallTextSize, double spacing) {
    return Padding(
      padding: EdgeInsets.only(right: spacing * 1.2),
      child: Align(
        alignment: Alignment.topRight,
        child: Text(
          '* Indicating Mandatory Field',
          style: TextStyle(fontSize: smallTextSize * 0.8),
        ),
      ),
    );
  }

  Widget _buildGeneralDetails(
    AddPanelViewModel vm,
    double fontSize,
    double spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('General Details', fontSize),
          SizedBox(height: spacing),
          CustomTextField(
            hintText: 'Site Name',
            controller: vm.siteNameController,
            maxLength: 25,
          ),
          SizedBox(height: spacing),
          CustomTextField(
            hintText: 'Site Address',
            controller: vm.addressController,
            maxLength: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildGprsSettings(
    AddPanelViewModel vm,
    double fontSize,
    double spacing,
  ) {
    return ExpansionTile(
      title: _buildSectionTitle('GSM Dialer Settings', fontSize),
      initiallyExpanded: true,
      children: [
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Panel SIM Number',
          controller: vm.panelSimNumberController,
          isNumber: true,
          maxLength: 13,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Admin SIM Number',
          controller: vm.adminNumberController,
          isNumber: true,
          maxLength: 10,
        ),
        SizedBox(height: spacing),
      ],
    );
  }

  Widget _buildIpSettings(
    AddPanelViewModel vm,
    double fontSize,
    double spacing,
  ) {
    return ExpansionTile(
      title: _buildSectionTitle('IP Comm. Settings', fontSize),
      initiallyExpanded: true,
      children: [
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'IP Address',
          isNumber: true,
          controller: vm.ipAddressController,
          maxLength: 15,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Port Number',
          controller: vm.portNumberController,
          maxLength: 5,
          isNumber: true,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Static IP Address',
          isNumber: true,
          controller: vm.staticIpController,
          maxLength: 15,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Static Port Number',
          controller: vm.staticPortController,
          maxLength: 5,
          isNumber: true,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Password',
          controller: vm.passwordController,
          maxLength: 4,
          isNumber: true,
        ),
        SizedBox(height: spacing),
      ],
    );
  }
}
