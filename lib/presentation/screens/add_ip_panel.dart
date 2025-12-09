import 'package:fire_nex/presentation/cubit/mappings/site_cubit.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/widgets/custom_button.dart';
import 'package:fire_nex/presentation/widgets/custom_text_field.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../core/responses/socket_repository.dart';
import '../../core/utils/application_class.dart';
import '../../core/utils/packets.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/ok_dialog.dart';
import '../widgets/app_bar.dart';

class AddIpPanelPage extends StatefulWidget {
  const AddIpPanelPage({
    super.key,
    required this.panelType,
    required this.panelName,
  });

  final String panelType;
  final String panelName;

  @override
  State<AddIpPanelPage> createState() => _AddIpPanelPageState();
}

class _AddIpPanelPageState extends State<AddIpPanelPage> {
  late final PanelFormControllers formControllers;
  List<String> siteNames = [];

  @override
  void initState() {
    super.initState();
    formControllers = PanelFormControllers();
  }

  @override
  void dispose() {
    formControllers.dispose();
    super.dispose();
  }

  Future<void> _addPanelToDB() async {
    final socketRepository = SocketRepository();

    final siteName = formControllers.siteNameController.text.trim();
    final ipAddress = formControllers.ipAddressController.text.trim();
    final staticIPAddress = formControllers.staticIpController.text.trim();
    final portStr = formControllers.portNumberController.text.trim();
    final staticPortStr = formControllers.staticPortController.text.trim();
    final pass = formControllers.passwordController.text.trim();
    final address = formControllers.addressController.text.trim();

    if (siteName.isEmpty) {
      return SnackBarHelper.showSnackBar(context, 'Site Name cannot be empty');
    }
    if (address.isEmpty) {
      return SnackBarHelper.showSnackBar(
        context,
        'Site Address cannot be empty',
      );
    }
    if (siteNames.contains(siteName)) {
      SnackBarHelper.showSnackBar(
        context,
        'Site name "$siteName" already exists.',
      );
      return;
    }

    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipAddress.isEmpty || !ipRegex.hasMatch(ipAddress)) {
      return SnackBarHelper.showSnackBar(
        context,
        'Enter a valid IP Address (e.g., 192.168.1.1)',
      );
    }
    if (staticIPAddress.isNotEmpty && !ipRegex.hasMatch(staticIPAddress)) {
      return SnackBarHelper.showSnackBar(
        context,
        'Enter a valid Static IP Address',
      );
    }

    final port = int.tryParse(portStr);
    if (port == null || port <= 0) {
      return SnackBarHelper.showSnackBar(context, 'Enter a valid Port Number');
    }

    int? staticPort;
    if (staticPortStr.isNotEmpty) {
      staticPort = int.tryParse(staticPortStr);
      if (staticPort == null || staticPort <= 0) {
        return SnackBarHelper.showSnackBar(
          context,
          'Enter a valid Static Port Number',
        );
      }
    }

    if (pass.length != 4 || int.tryParse(pass) == null) {
      return SnackBarHelper.showSnackBar(context, 'Password must be 4 digits');
    }

    _savePanelToDatabase(
      siteName: siteName,
      ipAddress: ipAddress,
      staticIPAddress: staticIPAddress,
      port: portStr,
      staticPort: staticPortStr,
      password: pass,
      address: address,
    );

    final connected = await _handleIPOperations(
      ipAddress: ipAddress,
      password: pass,
      portNumber: port,
      socketRepo: socketRepository,
    );

    if (connected) {
      Future.delayed(const Duration(seconds: 1));
      await _savePanelToDatabase(
        siteName: siteName,
        ipAddress: ipAddress,
        staticIPAddress: staticIPAddress,
        port: port.toString(),
        staticPort: staticPort?.toString() ?? '',
        password: pass,
        address: address,
      );
    } else {
      showInfoDialog(
        context: context,
        message:
            'Failed to connect panel, please check the Panel and the Panel details that you have shared!',
        // onOk: () {
        //   CustomNavigation.instance.pushReplace(
        //     context: context,
        //     screen: const PanelListPage(),
        //   );
        // },
      );
    }
  }

  Future<void> _savePanelToDatabase({
    required String siteName,
    required String ipAddress,
    required String staticIPAddress,
    required String port,
    required String staticPort,
    required String password,
    required String address,
  }) async {
    final userId = await SharedPreferenceHelper.getUserId();
    final String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    try {
      context.read<PanelCubit>().addPanel(
        userId: userId.toString(),
        panelType: widget.panelType,
        panelName: widget.panelName,
        site: siteName,
        panelSimNumber: '',
        adminCode: "1234",
        adminMobileNumber: '0000000000',
        mobileNumberSubId: '0',
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
        address: address,
        cOn: currentTime,
        password: password,
        ip_address: ipAddress,
        is_ip_gsm_panel: false,
        is_ip_panel: true,
        port_no: port,
        static_ip_address: staticIPAddress,
        static_port_no: staticPort,
      );
      ProgressDialog.show(context, message: 'Adding panel');
    } catch (e, stackTrace) {
      debugPrint('Error inserting panel: $e');
      debugPrintStack(stackTrace: stackTrace);
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
                  navigator.pop(); // Close the dialog first
                  await socketRepo.sendDisconnectPacket();

                  ProgressDialog.show(context);
                  await Future.delayed(const Duration(milliseconds: 200));

                  final reconnectResponse = await socketRepo.sendPacketSR1(
                    Packets.connectPacket(),
                  );

                  if (!context.mounted) return;

                  ProgressDialog.dismiss(context);

                  if (reconnectResponse.startsWith("S*000#1")) {
                    await Future.delayed(const Duration(seconds: 1));
                    await _addPanelToDB();
                    navigator.pop(true);
                  } else if (reconnectResponse == "S*000#3#*E") {
                    await showInfoDialog(
                      context: context,
                      message: 'Please restart the panel and reconnect again.',
                    );
                    navigator.pop(false);
                  } else {
                    SnackBarHelper.showSnackBar(context, "Failed to reconnect");
                    navigator.pop(false);
                  }
                } catch (e, stackTrace) {
                  debugPrint("Error sending packet: $e");
                  debugPrint(stackTrace.toString());

                  ProgressDialog.dismiss(context);

                  final errorText = e.toString().toLowerCase();
                  final isConnectionFailed =
                      errorText.contains('socketexception') ||
                      errorText.contains('connection refused') ||
                      errorText.contains('timed out') ||
                      errorText.contains('did not respond') ||
                      errorText.contains('failed');

                  if (isConnectionFailed) {
                    if (context.mounted) {
                      await showInfoDialog(
                        context: context,
                        message:
                            'An error occurred while reconnecting.\nPlease check your network and try again.',
                      );
                    }
                  } else {
                    SnackBarHelper.showSnackBar(
                      context,
                      'Unexpected error: $e',
                    );
                  }

                  if (context.mounted) {
                    navigator.pop(false);
                  }
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

  @override
  Widget build(BuildContext context) {
    final spacing = Responsive.spacingBwtView(context);
    siteNames = context.watch<SiteCubit>().state;

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if (state is AddPanelSuccess) {
          ProgressDialog.dismiss(context);
          _savingAndNavigating();
        } else if (state is AddPanelFailure) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(context, "Error while adding Panel");
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
            Container(
              color: AppColors.litePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 15, color: AppColors.colorPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Please add the panel with Specific Panel Details...',
                    style: TextStyle(
                      color: AppColors.colorPrimary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing * 2),
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: 'Site Name',
                      controller: formControllers.siteNameController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'IP Address',
                      maxLength: 15,
                      controller: formControllers.ipAddressController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'Port Number',
                      isNumber: true,
                      maxLength: 5,
                      controller: formControllers.portNumberController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'Static IP Address',
                      maxLength: 15,
                      controller: formControllers.staticIpController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'Static Port Number',
                      isNumber: true,
                      maxLength: 5,
                      controller: formControllers.staticPortController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'Password',
                      isNumber: true,
                      maxLength: 4,
                      controller: formControllers.passwordController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomTextField(
                      hintText: 'Site Address',
                      maxLength: 40,
                      controller: formControllers.addressController,
                    ),
                    VerticalSpace(height: spacing * 1.2),
                    CustomButton(
                      buttonText: 'Save Panel',
                      backgroundColor: AppColors.colorPrimary,
                      foregroundColor: AppColors.white,
                      onPressed: _addPanelToDB,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savingAndNavigating() {
    SnackBarHelper.showSnackBar(context, 'Panel saved successfully');
    CustomNavigation.instance.pushReplace(
      context: context,
      screen: const PanelListPage(),
    );
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

  void dispose() {
    siteNameController.dispose();
    ipAddressController.dispose();
    portNumberController.dispose();
    passwordController.dispose();
    staticIpController.dispose();
    staticPortController.dispose();
    addressController.dispose();
  }
}
