import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';
import 'package:fog_gen_new/presentation/dialog/ok_dialog.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/presentation/dialog/progress_with_message.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/presentation/widgets/custom_button.dart';
import 'package:fog_gen_new/presentation/widgets/custom_text_field.dart';
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
          // Show message (might be "Saved Offline")
          SnackBarHelper.showSnackBar(context, state.message);
          CustomNavigation.instance.pushReplace(
            context: context,
            screen: const PanelListPage(),
          );
        } else if (state is AddPanelFailure) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(context, "Error: ${state.message}");
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

  Future<void> _onSavePressed(BuildContext context, AddPanelViewModel vm) async {
    final siteNames = context.read<SiteCubit>().state;
    final simNumbers = context.read<PanelSimNumberCubit>().state;

    // 1. Validation
    final validationError = vm.validateForm(
      existingSiteNames: siteNames,
      existingPanelSims: simNumbers,
    );

    if (validationError != null) {
      SnackBarHelper.showSnackBar(context, validationError);
      return;
    }

    // 2. Try Connection (Validation)
    ProgressDialog.show(context);
    final connectionStatus = await vm.connectToPanel();
    ProgressDialog.dismiss(context);

    bool proceedToSave = false;

    // Handle Connection Results
    if (connectionStatus == ConnectionStatus.failed) {
      // NEW: Allow Offline Save
      final bool saveOffline = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Connection Failed"),
          content: const Text(
            "Could not connect to the panel to verify settings.\n\n"
                "This might be due to no internet or incorrect IP.\n"
                "Do you want to save this panel offline anyway?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save Offline", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;

      if (!saveOffline) return;
      proceedToSave = true;

    } else if (connectionStatus == ConnectionStatus.alreadyConnected) {
      final shouldDisconnect = await _showAlreadyConnectedDialog(context);
      if (shouldDisconnect) {
        final disconnected = await vm.forceDisconnect();
        if (disconnected) proceedToSave = true;
      }
    } else {
      // Connected successfully
      proceedToSave = true;
    }

    if (!proceedToSave) return;

    // 3. Handle SMS (Skip if we are saving offline due to connection issues?
    // Usually SMS requires network/signal, but we'll try it or let it fail silently/UI cancel)
    final smsSent = await _handleNeuronPanels(
      context,
      panelNumber: vm.panelSimNumberController.text,
      adminNumber: vm.adminNumberController.text,
      address: vm.addressController.text,
    );

    if (!smsSent) {
      if (mounted) {
        // If user cancelled SMS, we might still want to stop?
        // Or if offline, maybe we skip SMS? For now, respecting existing flow:
        showInfoDialog(context: context, message: 'SMS operation Cancelled');
      }
      return;
    }

    // 4. Save to DB (Trigger Cubit)
    // The Cubit will now handle "No Internet" by saving to local Pending List
    final panelData = await vm.prepareSaveData(
      panelType: widget.panelType,
      panelName: widget.panelName,
    );

    if (panelData != null && mounted) {
      ProgressDialog.show(context);

      context.read<PanelCubit>().addPanel(
        userId: panelData['userId'],
        panelType: panelData['panelType'],
        panelName: panelData['panelName'],
        site: panelData['site'],
        panelSimNumber: panelData['panelSimNumber'],
        adminCode: panelData['adminCode'],
        adminMobileNumber: panelData['adminMobileNumber'],
        mobileNumberSubId: panelData['mobileNumberSubId'],
        mobileNumber1: panelData['mobileNumber1'],
        mobileNumber2: "0000000000",
        mobileNumber3: "0000000000",
        mobileNumber4: "0000000000",
        mobileNumber5: "0000000000",
        mobileNumber6: "0000000000",
        mobileNumber7: "0000000000",
        mobileNumber8: "0000000000",
        mobileNumber9: "0000000000",
        mobileNumber10: "0000000000",
        address: panelData['address'],
        cOn: panelData['cOn'],
        password: panelData['password'],
        ip_address: panelData['ip_address'],
        is_ip_gsm_panel: panelData['is_ip_gsm_panel'],
        is_ip_panel: panelData['is_ip_panel'],
        port_no: panelData['port_no'],
        static_ip_address: panelData['static_ip_address'],
        static_port_no: panelData['static_port_no'],
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