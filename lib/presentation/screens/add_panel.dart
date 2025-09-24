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
import '../../utils/silent_sms.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';

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

  @override
  void initState() {
    super.initState();
    formControllers = PanelFormControllers();

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

  void updateFieldRow() {
    _steps.clear(); // reset steps
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

    debugPrint("Other panel selected: $selectedPanelName");

    setState(() {
      _currentStep = 0; // restart flow
    });
  }

  Future<void> _goToNext() async {
    final step = _steps[_currentStep];

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

      if (label == 'Panel Sim Number') {
        if (value.length != 10 && value.length != 13) {
          SnackBarHelper.showSnackBar(
            context,
            'Panel Sim Number must be 10 or 13 digits',
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

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      final confirmed = await showConfirmationDialog(
        context: context,
        message: 'Do you want to add panel named $selectedPanelName?',
      );

      if (confirmed == true) {
        _addPanelToDB();
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

    ProgressDialog.show(context, message: 'Sending panel SMS...');

    try {
      await Future.delayed(const Duration(seconds: 2));
      await sendSmsSilently(panelSimNumber, message1);
      await Future.delayed(const Duration(seconds: 2));
      await sendSmsSilently(panelSimNumber, message2);

      ProgressDialog.dismiss(context);
      SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
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

    ProgressDialog.show(context, message: 'Sending panel SMS...');

    try {
      await Future.delayed(const Duration(seconds: 2));
      await sendSmsSilently(panelSimNumber, message1);
      await Future.delayed(const Duration(seconds: 2));
      await sendSmsSilently(panelSimNumber, message2);

      ProgressDialog.dismiss(context);
      SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
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

    ProgressDialog.show(context, message: 'Sending panel SMS...');

    try {
      await Future.delayed(const Duration(seconds: 2));
      await sendSmsSilently(panelSimNumber, message1);

      await Future.delayed(const Duration(milliseconds: 3500));
      await sendSmsSilently(panelSimNumber, message2);

      await Future.delayed(const Duration(milliseconds: 5500));
      await sendSmsSilently(panelSimNumber, message3);

      ProgressDialog.dismiss(context);
      SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
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

    debugPrint('Inserting Panel with the following values:');
    debugPrint('Panel Type: ${widget.panelType}');
    debugPrint('Panel Name: $selectedPanelName');
    debugPrint('Site Name: $siteName');
    debugPrint('Panel SIM Number: $panelSimNumber');
    debugPrint('Admin SIM Number: $adminNumber');
    debugPrint('Address: $address');
    debugPrint('User ID: $userId');

    final result = await panelViewModel.insertPanel(
      widget.panelType,
      selectedPanelName!,
      panelSimNumber,
      adminNumber,
      siteName,
      address,
      "1234",
      userId!,
    );

    if (!mounted) return;

    switch (result) {
      case InsertPanelResult.success:
        _performAddPanel();
        break;
      case InsertPanelResult.simNumberExists:
        SnackBarHelper.showSnackBar(
          context,
          'Panel Sim Number already exists!',
        );
        break;
      case InsertPanelResult.siteNameExists:
        SnackBarHelper.showSnackBar(context, 'Site Name already exists!');
        break;
      case InsertPanelResult.failure:
        SnackBarHelper.showSnackBar(context, 'Something went wrong!');
        break;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        pageName: 'Add Panel',
        isFilter: false,
        isDash: false,
        onBack: () {
          CustomNavigation.instance.pushReplace(
            context: context,
            screen: PanelListPage(),
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
                                });
                              },
                            ),
                          ),
                        ],
                      )
                      : FormSection(
                        label: currentStepData['label'],
                        keyboardType: currentStepData['keyboardType'],
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
