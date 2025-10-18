import 'dart:developer' as developer;

import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/strings.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';
import 'add_ip_gprs_panel.dart';
import 'add_ip_panel.dart';

class AddPanelPage extends StatefulWidget {
  final String panelType;
  const AddPanelPage({super.key, required this.panelType});

  @override
  State<AddPanelPage> createState() => _AddPanelPageState();
}

class _AddPanelPageState extends State<AddPanelPage> {
  String? selectedPanelName;
  final List<String> panelNames = [];
  late final PanelFormControllers formControllers;
  int _currentStep = 0;
  final List<Map<String, dynamic>> _steps = [];
  String? device;

  @override
  void initState() {
    super.initState();
    formControllers = PanelFormControllers();
    getDevice();

    if (widget.panelType == 'FIRE PANEL') {
      panelNames.addAll([
        'FIRE PANEL-2 ZONE - F02L G',
        'FIRE PANEL-2 ZONE - F02L G4',
        'FIRE PANEL-2 ZONE - F02L I',
        'FIRE PANEL-2 ZONE - F02L GI',
        'FIRE PANEL-4 ZONE - F04L G',
        'FIRE PANEL-4 ZONE - F04L G4',
        'FIRE PANEL-4 ZONE - F04L I',
        'FIRE PANEL-4 ZONE - F04L GI',
        'FIRE PANEL-4 ZONE - F04L GI 2',
      ]);
    } else if (widget.panelType == 'FIRE DIALERS') {
      panelNames.addAll(['MULTICOM 4G DIALER', 'NEURON 4G', '4G COM']);
    }

    _steps.add({'type': 'dropdown', 'label': 'Panel Category'});
  }

  void _handleOtherPanelProcedure(String panelName) {
    if (panelName == 'FIRE PANEL-2 ZONE - F02L I' ||
        panelName == 'FIRE PANEL-4 ZONE - F04L I') {
      Future.delayed(const Duration(milliseconds: 300));
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: AddIpPanelPage(
          panelType: widget.panelType,
          panelName: panelName,
        ),
      );
    } else if (panelName == 'FIRE PANEL-2 ZONE - F02L GI' ||
        panelName == 'FIRE PANEL-4 ZONE - F04L GI') {
      Future.delayed(const Duration(milliseconds: 300));
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: AddPanelFormScreen(
          panelType: widget.panelType,
          panelName: panelName,
        ),
      );
    }
  }

  void updateFieldRow() {
    _steps.clear();
    _steps.addAll([
      {'type': 'dropdown', 'label': 'Panel Category'},
      {
        'label': 'Site Name',
        'controller': formControllers.siteNameController,
        'keyboardType': TextInputType.text,
        'maxLength': 20,
      },
      {
        'label': 'Panel Sim Number',
        'controller': formControllers.panelSimNumberController,
        'keyboardType': TextInputType.phone,
        'maxLength': 13,
      },
      {
        'label': 'Admin Sim Number',
        'controller': formControllers.adminNumberController,
        'keyboardType': TextInputType.phone,
        'maxLength': 10,
      },
      {
        'label': 'Address',
        'controller': formControllers.addressController,
        'keyboardType': TextInputType.text,
        'maxLength': 40,
      },
    ]);

    debugPrint("panel selected: $selectedPanelName");

    setState(() {
      _currentStep = 0;
    });
  }

  void getDevice() async {
    device = await SharedPreferenceHelper.getDeviceType();
  }

  Future<void> _goToNext() async {
    final panelVM = context.read<PanelViewModel>();
    final siteSimList = panelVM.sitePanelInfoList;

    debugPrint("Site + SIM list:");
    for (var info in siteSimList) {
      debugPrint("- Site: ${info.siteName}, SIM: ${info.panelSimNumber}");
    }

    final step = _steps[_currentStep];
    _trackSteps("validating", _currentStep);

    if (step['type'] == 'dropdown') {
      if (selectedPanelName == null) {
        SnackBarHelper.showSnackBar(context, 'Please select a Panel Category');
        return;
      }
    } else {
      final controller = step['controller'] as TextEditingController;
      final label = step['label'] as String;
      final value = controller.text.trim();

      if (value.isEmpty) {
        SnackBarHelper.showSnackBar(context, 'Please fill in $label');
        return;
      }

      if (label == 'Site Name') {
        final newSite = value.toLowerCase().trim();

        final siteExists = siteSimList.any(
          (info) => info.siteName.toLowerCase() == newSite,
        );

        if (siteExists) {
          SnackBarHelper.showSnackBar(context, 'This Site Name already exists');
          return;
        }
      }

      if (label == 'Panel Sim Number') {
        if (value.length != 10 && value.length != 13) {
          SnackBarHelper.showSnackBar(
            context,
            'Panel Sim Number must be 10 or 13 digits',
          );
          return;
        }

        final newPanelSimNumber = value.trim();
        final numberExists = siteSimList.any(
          (info) => info.panelSimNumber == newPanelSimNumber,
        );

        if (numberExists) {
          SnackBarHelper.showSnackBar(
            context,
            'This Panel Sim Number already exists',
          );
          return;
        }
      }

      if (label == 'Admin Sim Number') {
        if (value.length != 10) {
          SnackBarHelper.showSnackBar(
            context,
            'Admin Sim Number must be exactly 10 digits',
          );
          return;
        }

        final panelSim = formControllers.panelSimNumberController.text.trim();
        if (panelSim.isNotEmpty && panelSim == value) {
          SnackBarHelper.showSnackBar(
            context,
            'Admin and Panel Sim Numbers must be different',
          );
          return;
        }
      }
    }

    if (step['label'] == 'Admin Sim Number' &&
        device == 'IOS' &&
        formControllers.adminNumberController.text.trim().isNotEmpty) {
      final adminNumber = formControllers.adminNumberController.text.trim();
      final panelSimNumber =
          formControllers.panelSimNumberController.text.trim();
      var message = '';

      if (fourGComPanels.contains(selectedPanelName)) {
        message = 'SECURICO 1234 ADD ADMIN +91-$adminNumber END';
      } else if (neuronPanels.contains(selectedPanelName)) {
        message = '''
< 1234 TEL NO
#01-+91$adminNumber*
#02-+910000000000*
#03-+910000000000*
#04-+910000000000*
#05-+910000000000*
>
''';
      } else {
        message = 'null';
      }

      final result = await showConfirmationDialog(
        context: context,
        message: 'Sending your 1st message to the Panel, to add Admin Number!',
        cancelText: "",
        confirmText: "SEND SMS",
        title: 'Setting Panel',
      );
      if (result == true) {
        if (!mounted) return;
        await ProgressDialogWithMessage.show(
          context,
          messages: [message],
          panelSimNumber: panelSimNumber,
        );
      }
    }

    if (step['label'] == 'Address' &&
        device == 'IOS' &&
        formControllers.addressController.text.trim().isNotEmpty) {
      final address = formControllers.addressController.text.trim();
      final panelSimNumber =
          formControllers.panelSimNumberController.text.trim();
      var message = '';

      if (fourGComPanels.contains(selectedPanelName)) {
        message = 'SECURICO 1234 ADD SIGNATURE $address* END';
      } else if (neuronPanels.contains(selectedPanelName)) {
        message = '< 1234 SIGNATURE $address* >';
      } else {
        message = 'null';
      }

      final result = await showConfirmationDialog(
        context: context,
        message: 'Sending your 2nd message to the Panel, to add Address!',
        cancelText: "",
        confirmText: "SEND SMS",
        title: 'Setting Panel',
      );
      if (result == true) {
        await ProgressDialogWithMessage.show(
          context,
          messages: [message],
          panelSimNumber: panelSimNumber,
        );
      }
    }

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _trackSteps("moved_to", _currentStep);
      });
    } else {
      _trackSteps("final_confirmation", _currentStep, selectedPanelName);
      final confirmed = await showConfirmationDialog(
        context: context,
        message: 'Do you want to add panel named $selectedPanelName?',
      );

      if (confirmed == true) {
        _trackSteps("confirm_submit", _currentStep);
        _addPanelToDB();
      } else {
        _trackSteps("cancelled_submit", _currentStep);
      }
    }
  }

  void _performAddPanel() {
    if (fourGComPanels.contains(selectedPanelName)) {
      _handle4GComPanels();
    } else if (neuronPanels.contains(selectedPanelName)) {
      _handleNeuronPanels();
    } else {
      _handleOtherPanels();
    }
  }

  Future<void> _handle4GComPanels() async {
    final adminNumber = formControllers.adminNumberController.text.trim();
    final panelSimNumber = formControllers.panelSimNumberController.text.trim();
    final address = formControllers.addressController.text.trim();

    String message1 = 'SECURICO 1234 ADD ADMIN +91-$adminNumber END';
    String message2 = 'SECURICO 1234 ADD SIGNATURE $address* END';

    final messages = [message1, message2];

    try {
      final result = await ProgressDialogWithMessage.show(
        context,
        messages: messages,
        panelSimNumber: panelSimNumber,
      );

      debugPrint("result :  $result");

      if (result == true) {
        SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
        CustomNavigation.instance.pushReplace(
          context: context,
          screen: PanelListPage(),
        );
      }
    } catch (e) {
      CustomNavigation.instance.pop(context);
      SnackBarHelper.showSnackBar(context, 'Error');
    }
  }

  Future<void> _handleNeuronPanels() async {
    final adminNumber = formControllers.adminNumberController.text.trim();
    final panelSimNumber = formControllers.panelSimNumberController.text.trim();
    final address = formControllers.addressController.text.trim();

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
        panelSimNumber: panelSimNumber,
      );

      debugPrint("result :  $result");

      if (result == true) {
        SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
        CustomNavigation.instance.pushReplace(
          context: context,
          screen: PanelListPage(),
        );
      }
    } catch (e) {
      CustomNavigation.instance.pop(context);
      SnackBarHelper.showSnackBar(context, 'Error');
    }
  }

  Future<void> _handleOtherPanels() async {
    final adminNumber = formControllers.adminNumberController.text.trim();
    final address = formControllers.addressController.text.trim();
    final panelSimNumber = formControllers.panelSimNumberController.text.trim();

    final String message1 = '1234 NAME ADDRESS #$address* END';
    final String message2 = '1234 TEL NO INTRUSION #01-$adminNumber* END';
    final String message3 = '1234 TEL NO FIRE #01-$adminNumber* END';

    final messages = [message1, message2, message3];

    try {
      final result = await ProgressDialogWithMessage.show(
        context,
        messages: messages,
        panelSimNumber: panelSimNumber,
      );

      if (result == true) {
        SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
        CustomNavigation.instance.pushReplace(
          context: context,
          screen: PanelListPage(),
        );
      } else {
        CustomNavigation.instance.pop(context);
        SnackBarHelper.showSnackBar(context, 'Error');
      }
    } catch (e) {
      CustomNavigation.instance.pop(context);
      SnackBarHelper.showSnackBar(context, 'Error sending SMS: $e');
    }
  }

  Future<void> _addPanelToDB() async {
    final panelViewModel = context.read<PanelViewModel>();

    final siteName = formControllers.siteNameController.text.trim();
    final panelSimNumber = formControllers.panelSimNumberController.text.trim();
    final adminNumber = formControllers.adminNumberController.text.trim();
    final address = formControllers.addressController.text.trim();
    final userId = await SharedPreferenceHelper.getUserId();

    await panelViewModel.insertPanel(
      panelType: widget.panelType,
      panelCategory: selectedPanelName!,
      panelSimNumber: panelSimNumber,
      mobileNumber: adminNumber,
      address: address,
      siteName: siteName,
      adminCode: '1234',
      userId: userId!,
      isIPPanel: false,
      isIPGPRSPanel: false,
      ipAddress: '',
      port: '',
      staticPort: '',
      pass: '',
      staticIP: '',
    );

    if (device == 'ANDROID') {
      _performAddPanel();
    } else {
      SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
    }
  }

  @override
  void dispose() {
    formControllers.dispose();
    super.dispose();
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _trackSteps(String action, int stepIndex, [String? extra]) {
    developer.log(
      "STEP TRACKING",
      name: "ADD PANEL PAGE",
      error: {
        "action": action,
        "step": stepIndex,
        "label": _steps[stepIndex]['label'],
        "extra": extra,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];

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
          Container(
            color: AppColors.litePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: const [
                Icon(Icons.info, size: 15, color: AppColors.colorPrimary),
                SizedBox(width: 5),
                Text(
                  'Please add the panel with Specific Panel Details...',
                  style: TextStyle(color: AppColors.colorPrimary, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  currentStepData['type'] == 'dropdown'
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStepData['label'],
                            style: const TextStyle(
                              color: AppColors.colorPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.colorPrimary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<String>(
                              value: selectedPanelName,
                              isExpanded: true,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                color: AppColors.colorPrimary,
                              ),
                              underline: const SizedBox(),
                              hint: const Text('Select Category'),
                              items:
                                  panelNames.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPanelName = value;
                                  updateFieldRow();
                                  _handleOtherPanelProcedure(value!);
                                });
                              },
                            ),
                          ),
                        ],
                      )
                      : FormSection(
                        label: currentStepData['label'],
                        // keyboardType: currentStepData['keyboardType'],
                        controller: currentStepData['controller'],
                        maxLength: currentStepData['maxLength'],
                      ),
                  const VerticalSpace(height: 20),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: CustomButton(
                            buttonText: "BACK",
                            backgroundColor: AppColors.litePrimary,
                            foregroundColor: AppColors.colorPrimary,
                            onPressed: _goToPreviousStep,
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          buttonText:
                              _currentStep == _steps.length - 1
                                  ? "SUBMIT"
                                  : "NEXT",
                          onPressed: _goToNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelFormControllers {
  final siteNameController = TextEditingController();
  final adminNumberController = TextEditingController();
  final panelSimNumberController = TextEditingController();
  final addressController = TextEditingController();

  void dispose() {
    siteNameController.dispose();
    adminNumberController.dispose();
    panelSimNumberController.dispose();
    addressController.dispose();
  }
}
