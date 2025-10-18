import 'package:fire_nex/core/responses/socket_repository.dart';
import 'package:fire_nex/presentation/dialog/ok_dialog.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/dialog/progress_with_message.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/widgets/custom_button.dart';
import 'package:fire_nex/presentation/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../core/utils/application_class.dart';
import '../../core/utils/packets.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/app_bar.dart';

class AddPanelFormScreen extends StatefulWidget {
  const AddPanelFormScreen({
    super.key,
    required this.panelType,
    required this.panelName,
  });

  final String panelType;
  final String panelName;

  @override
  State<AddPanelFormScreen> createState() => _AddPanelFormScreenState();
}

class _AddPanelFormScreenState extends State<AddPanelFormScreen> {
  final generalControllers = PanelFormControllers();
  final gprsControllers = PanelFormControllers();
  final ipControllers = PanelFormControllers();

  @override
  void dispose() {
    generalControllers.dispose();
    gprsControllers.dispose();
    ipControllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final smallTextSize = Responsive.smallTextSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return Scaffold(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralDetails(fontSize, spacingBwtView),
                  SizedBox(height: spacingBwtView),
                  _buildGprsSettings(fontSize, spacingBwtView),
                  _buildIpSettings(fontSize, spacingBwtView),
                  SizedBox(height: spacingBwtView * 2.5),
                  Padding(
                    padding: EdgeInsets.only(right: spacingBwtView * 1.2),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        '* Indicating Mandatory Field',
                        style: TextStyle(fontSize: smallTextSize * 0.8),
                      ),
                    ),
                  ),
                  Center(
                    child: CustomButton(
                      buttonText: 'Save Panel',
                      backgroundColor: AppColors.colorPrimary,
                      foregroundColor: AppColors.white,
                      onPressed: _addPanelToDB,
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
        Text('*', style: TextStyle(color: AppColors.red, fontSize: fontSize)),
      ],
    );
  }

  Widget _buildGeneralDetails(double fontSize, double spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('General Details', fontSize),
          SizedBox(height: spacing),
          CustomTextField(
            hintText: 'Site Name',
            controller: generalControllers.siteNameController,
            maxLength: 25,
          ),
          SizedBox(height: spacing),
          CustomTextField(
            hintText: 'Site Address',
            controller: generalControllers.addressController,
            maxLength: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildGprsSettings(double fontSize, double spacing) {
    return ExpansionTile(
      title: _buildSectionTitle('GSM Dialer Settings', fontSize),
      initiallyExpanded: false,
      children: [
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Panel SIM Number',
          controller: gprsControllers.ipAddressController,
          isNumber: true,
          maxLength: 13,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Admin SIM Number',
          controller: gprsControllers.portNumberController,
          isNumber: true,
          maxLength: 10,
        ),
        SizedBox(height: spacing),
      ],
    );
  }

  Widget _buildIpSettings(double fontSize, double spacing) {
    return ExpansionTile(
      title: _buildSectionTitle('IP Comm Settings', fontSize),
      initiallyExpanded: false,
      children: [
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'IP Address',
          isNumber: true,
          controller: ipControllers.ipAddressController,
          maxLength: 15,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Port Number',
          controller: ipControllers.portNumberController,
          maxLength: 5,
          isNumber: true,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Static IP Address',
          isNumber: true,
          controller: ipControllers.staticIpController,
          maxLength: 15,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Static Port Number',
          controller: ipControllers.staticPortController,
          maxLength: 5,
          isNumber: true,
        ),
        SizedBox(height: spacing),
        CustomTextField(
          hintText: 'Password',
          controller: ipControllers.passwordController,
          maxLength: 4,
          isNumber: true,
        ),
        SizedBox(height: spacing),
      ],
    );
  }

  bool _validateForm(
    BuildContext context,
    String siteName,
    String address,
    String panelSimNumber,
    String adminNumber,
    String ipAddress,
    String staticIPAddress,
    String portStr,
    String staticPortStr,
    String pass,
    List<dynamic> siteList,
  ) {
    const ipPattern = r'^(\d{1,3}\.){3}\d{1,3}$';
    final ipRegex = RegExp(ipPattern);
    if (siteName.isEmpty) {
      SnackBarHelper.showSnackBar(context, 'Site Name cannot be empty');
      return false;
    }

    if (address.isEmpty) {
      SnackBarHelper.showSnackBar(context, 'Site Address cannot be empty');
      return false;
    }

    if (siteList.any(
      (info) => info.siteName.toLowerCase() == siteName.toLowerCase(),
    )) {
      SnackBarHelper.showSnackBar(context, 'This Site Name already exists');
      return false;
    }

    if (ipAddress.isEmpty || !ipRegex.hasMatch(ipAddress)) {
      SnackBarHelper.showSnackBar(
        context,
        'Enter a valid IP Address (e.g., 192.168.1.1)',
      );
      return false;
    }

    if (staticIPAddress.isNotEmpty && !ipRegex.hasMatch(staticIPAddress)) {
      SnackBarHelper.showSnackBar(context, 'Enter a valid Static IP Address');
      return false;
    }

    if (panelSimNumber.isEmpty) {
      SnackBarHelper.showSnackBar(context, 'Panel SIM Number cannot be empty');
      return false;
    }

    if (panelSimNumber.length != 10 && panelSimNumber.length != 13) {
      SnackBarHelper.showSnackBar(
        context,
        'Panel SIM Number must be 10 or 13 digits',
      );
      return false;
    }

    if (siteList.any(
      (info) =>
          info.panelSimNumber.toLowerCase() == panelSimNumber.toLowerCase(),
    )) {
      SnackBarHelper.showSnackBar(context, 'This Panel SIM Number exists');
      return false;
    }

    if (adminNumber.isEmpty) {
      SnackBarHelper.showSnackBar(context, 'Admin SIM Number cannot be empty');
      return false;
    }

    final port = int.tryParse(portStr);
    if (port == null || port <= 0) {
      SnackBarHelper.showSnackBar(context, 'Enter a valid Port Number');
      return false;
    }

    if (staticPortStr.isNotEmpty) {
      final staticPort = int.tryParse(staticPortStr);
      if (staticPort == null || staticPort <= 0) {
        SnackBarHelper.showSnackBar(
          context,
          'Enter a valid Static Port Number',
        );
        return false;
      }
    }

    if (pass.length != 4 || int.tryParse(pass) == null) {
      SnackBarHelper.showSnackBar(context, 'Password must be 4 digits');
      return false;
    }

    return true;
  }

  Future<void> _addPanelToDB() async {
    final panelViewModel = context.read<PanelViewModel>();
    final socketRepo = SocketRepository();

    final siteName = generalControllers.siteNameController.text.trim();
    final address = generalControllers.addressController.text.trim();
    final panelSimNumber = gprsControllers.ipAddressController.text.trim();
    final adminNumber = gprsControllers.portNumberController.text.trim();
    final ipAddress = ipControllers.ipAddressController.text.trim();
    final staticIPAddress = ipControllers.staticIpController.text.trim();
    final portStr = ipControllers.portNumberController.text.trim();
    final staticPortStr = ipControllers.staticPortController.text.trim();
    final pass = ipControllers.passwordController.text.trim();
    final userId = await SharedPreferenceHelper.getUserId();

    if (!_validateForm(
      context,
      siteName,
      address,
      panelSimNumber,
      adminNumber,
      ipAddress,
      staticIPAddress,
      portStr,
      staticPortStr,
      pass,
      panelViewModel.sitePanelInfoList,
    )) {
      return;
    }

    final ipConnected = await _handleIPOperations(
      ipAddress: ipAddress,
      password: pass,
      portNumber: int.parse(portStr),
      socketRepo: socketRepo,
    );

    if (ipConnected) {
      final isSMSSend = await _handleNeuronPanels(
        panelNumber: panelSimNumber,
        adminNumber: adminNumber,
        address: address,
      );

      if (isSMSSend) {
        try {
          await _savePanelToDatabase(
            panelSimNumber: panelSimNumber,
            adminNumber: adminNumber,
            address: address,
            siteName: siteName,
            ipAddress: ipAddress,
            staticIPAddress: staticIPAddress,
            portStr: portStr,
            staticPortStr: staticPortStr,
            pass: pass,
            panelViewModel: panelViewModel,
            panelType: widget.panelType,
            panelName: widget.panelName,
            userId: userId!,
          );
        } catch (e) {
          debugPrint('Failed to save panel: $e');
          SnackBarHelper.showSnackBar(context, 'Failed to save panel: $e');
        }
      } else {
        showInfoDialog(context: context, message: 'SMS operation revoked');
      }
    }
    showInfoDialog(
      context: context,
      message: 'Failed to connect panel!',
      onOk: () {
        CustomNavigation.instance.pushReplace(
          context: context,
          screen: const PanelListPage(),
        );
      },
    );
  }

  Future<bool> _handleNeuronPanels({
    required String panelNumber,
    required String adminNumber,
    required String address,
  }) async {
    String message1 = '''
< 1234 TEL NO
#01-+91$adminNumber*
#02-+910000000000*
#03-+910000000000*
#04-+910000000000*
#05-+910000000000*
>
''';
    String message2 = '< 1234 SIGNATURE $address* >';

    final messages = [message1, message2];
    try {
      final result = await ProgressDialogWithMessage.show(
        context,
        messages: messages,
        panelSimNumber: panelNumber,
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _savePanelToDatabase({
    required String panelSimNumber,
    required String adminNumber,
    required String address,
    required String siteName,
    required String ipAddress,
    required String staticIPAddress,
    required String portStr,
    required String staticPortStr,
    required String pass,
    required PanelViewModel panelViewModel,
    required String panelType,
    required String panelName,
    required int userId,
  }) async {
    try {
      await panelViewModel.insertPanel(
        panelType: panelType,
        isIPGPRSPanel: true,
        panelCategory: panelName,
        panelSimNumber: panelSimNumber,
        mobileNumber: adminNumber,
        address: address,
        siteName: siteName,
        adminCode: '1234',
        userId: userId,
        isIPPanel: false,
        ipAddress: ipAddress,
        port: portStr,
        staticPort: staticPortStr,
        pass: pass,
        staticIP: staticIPAddress,
      );

      SnackBarHelper.showSnackBar(context, 'Panel saved successfully');
      await Future.delayed(const Duration(milliseconds: 400));

      CustomNavigation.instance.pushReplace(
        context: context,
        screen: const PanelListPage(),
      );
    } catch (e) {
      debugPrint('Failed to save panel: $e');
      SnackBarHelper.showSnackBar(context, 'Failed to save panel: $e');
    }
  }

  Future<bool> _handleIPOperations({
    required String ipAddress,
    required int portNumber,
    required String password,
    required SocketRepository socketRepo,
  }) async {
    try {
      ProgressDialog.show(context);

      final _ =
          Application()
            ..mIPAddress = ipAddress
            ..mPortNumber = portNumber
            ..mPassword = password;

      final response = await socketRepo.sendPacketSR1(Packets.connectPacket());
      return _handleSR1Response(response, socketRepo);
    } catch (e) {
      debugPrint("Error sending packet: $e");

      final errorText = e.toString().toLowerCase();
      final isConnectionFailed =
          errorText.contains('socketexception') ||
          errorText.contains('connection refused') ||
          errorText.contains('timed out') ||
          errorText.contains('did not respond') ||
          errorText.contains('failed');

      ProgressDialog.dismiss(context);

      if (isConnectionFailed) {
        await showInfoDialog(
          context: context,
          message:
              'Unable to connect to the panel.\nPlease check the network connection and try again.',
        );
      } else {
        SnackBarHelper.showSnackBar(context, 'Unexpected error: $e');
      }

      return false;
    } finally {
      ProgressDialog.dismiss(context);
    }
  }

  Future<bool> _handleSR1Response(
    String result,
    SocketRepository socketRepo,
  ) async {
    if (result.contains("S*000#3#*E")) {
      ProgressDialog.dismiss(context);
      return await _showAlreadyConnectedDialog(socketRepo);
    } else if (result.startsWith("S*000#1")) {
      ProgressDialog.dismiss(context);
      return true;
    }
    return false;
  }

  Future<bool> _showAlreadyConnectedDialog(SocketRepository socketRepo) async {
    final navigator = Navigator.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Connection Status",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text("This panel appears to be already connected."),
          actions: [
            TextButton(
              child: const Text(
                "Force Disconnect",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                try {
                  navigator.pop(); // Close dialog first
                  await socketRepo.sendDisconnectPacket();

                  ProgressDialog.show(context);
                  await Future.delayed(const Duration(milliseconds: 200));

                  final reconnectResponse =
                  await socketRepo.sendPacketSR1(Packets.connectPacket());

                  if (!context.mounted) return;

                  ProgressDialog.dismiss(context);

                  if (reconnectResponse.startsWith("S*000#1")) {
                    await Future.delayed(const Duration(seconds: 1));
                    await _addPanelToDB();
                    navigator.pop(true);
                  } else if (reconnectResponse == "S*000#3#*E") {
                    await showInfoDialog(
                      context: context,
                      message:
                      'Please restart the panel, and reconnect again!',
                    );
                    navigator.pop(false);
                  } else {
                    SnackBarHelper.showSnackBar(
                      context,
                      "Failed to reconnect",
                    );
                    navigator.pop(false);
                  }
                } catch (e, stackTrace) {
                  debugPrint('Error in Force Disconnect: $e');
                  debugPrint(stackTrace.toString());

                  ProgressDialog.dismiss(context);

                  final errorText = e.toString().toLowerCase();
                  final isConnectionFailed =
                      errorText.contains('socketexception') ||
                          errorText.contains('connection refused') ||
                          errorText.contains('timed out') ||
                          errorText.contains('did not respond') ||
                          errorText.contains('failed');

                  if (context.mounted) {
                    if (isConnectionFailed) {
                      await showInfoDialog(
                        context: context,
                        message:
                        'Unable to reconnect.\nPlease check your network and try again.',
                      );
                    } else {
                      SnackBarHelper.showSnackBar(
                        context,
                        'Unexpected error: $e',
                      );
                    }
                    navigator.pop(false);
                  }
                } finally {
                  ProgressDialog.dismiss(context);
                }
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => navigator.pop(false),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class PanelFormControllers {
  final siteNameController = TextEditingController();
  final ipAddressController = TextEditingController();
  final portNumberController = TextEditingController();
  final passwordController = TextEditingController();
  final staticIpController = TextEditingController();
  final staticPortController = TextEditingController();
  final addressController = TextEditingController();
  final adminNumberController = TextEditingController();
  final panelSimNumberController = TextEditingController();

  void dispose() {
    siteNameController.dispose();
    ipAddressController.dispose();
    portNumberController.dispose();
    passwordController.dispose();
    staticIpController.dispose();
    staticPortController.dispose();
    addressController.dispose();
    adminNumberController.dispose();
    panelSimNumberController.dispose();
  }
}
