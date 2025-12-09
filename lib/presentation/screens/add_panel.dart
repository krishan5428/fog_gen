import 'dart:developer' as developer;

import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../constants/strings.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../cubit/fire/fire_cubit.dart';
import '../cubit/intrusion/intru_cubit.dart';
import '../cubit/mappings/panel_sim_number_cubit.dart';
import '../cubit/mappings/site_cubit.dart';
import '../cubit/panel/panel_cubit.dart';
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
  List<String> siteNames = [];
  List<String> panelSimNumbers = [];
  late final PanelFormControllers formControllers;
  int _currentStep = 0;
  final List<Map<String, dynamic>> _steps = [];
  String? device;
  String? lastIntruId;
  String? lastFireId;
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
      panelNames.addAll([
        'MULTICOM 4G DIALER',
        'NEURON 4G',
        '4G COM',
        // 'GALAXY GX GSMD DIALER',
        'SEC GSMD 4G',
        'SEC GSMD 4GC',
      ]);
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

    // Step 1 (always dropdown)
    _steps.add({'type': 'dropdown', 'label': 'Panel Category'});

    // Common fields
    _steps.addAll([
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
    ]);

    // ----------------------------------------------------------
    //   ADD EXTRA FIELD ONLY IF PANEL TYPE IS FIRE DIALERS
    // ----------------------------------------------------------

    if (widget.panelType == 'FIRE DIALERS') {
      _steps.add({
        'label': 'Admin Code',
        'controller': formControllers.adminCodeController,
        'keyboardType': TextInputType.number,
        'maxLength': 4,
      });
    }

    // Remaining common fields
    _steps.addAll([
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
        if (siteNames.contains(value)) {
          SnackBarHelper.showSnackBar(
            context,
            'Site name "$value" already exists.',
          );
          return;
        }
      }

      if (label == 'Panel Sim Number') {
        final formattedValue =
            value.length == 13 && value.startsWith('+91')
                ? value.substring(3)
                : value;

        if (panelSimNumbers.contains(formattedValue) ||
            panelSimNumbers.contains(value)) {
          SnackBarHelper.showSnackBar(
            context,
            'Panel SIM number "$value" already exists.',
          );
          return;
        }
      }

      if (label == 'Admin Code') {
        if (value.length != 4) {
          SnackBarHelper.showSnackBar(
            context,
            'Admin code must be exactly 4 digits',
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
        formControllers.adminNumberController.text.trim().isNotEmpty) {
      final adminNumber = formControllers.adminNumberController.text.trim();
      final adminCode =
          formControllers.adminCodeController.text.trim().isEmpty
              ? "1234"
              : formControllers.adminCodeController.text.trim();

      final panelSimNumber =
          formControllers.panelSimNumberController.text.trim();

      List<String> messages = [];

      if (fourGComPanels.contains(selectedPanelName)) {
        messages = ['SECURICO 1234 ADD ADMIN +91-$adminNumber END'];
      } else if (neuronPanels.contains(selectedPanelName)) {
        messages = [
          '''
< 1234 TEL NO
#01-+91$adminNumber*
#02-+910000000000*
#03-+910000000000*
#04-+910000000000*
#05-+910000000000*
>
''',
        ];
      } else if (dialerPanels.contains(selectedPanelName)) {
        messages = [
          '$adminCode TEL NO INTRUSION #01-+91$adminNumber* END',
          '$adminCode TEL NO FIRE #01-+91$adminNumber* END',
        ];
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

        if (messages.isEmpty) {
          SnackBarHelper.showSnackBar(context, "Unsupported panel type");
          return;
        }

        await ProgressDialogWithMessage.show(
          context,
          messages: messages,
          panelSimNumber: panelSimNumber,
        );
      }
    }

    if (step['label'] == 'Address' &&
        formControllers.addressController.text.trim().isNotEmpty) {
      final address = formControllers.addressController.text.trim();
      final panelSimNumber =
          formControllers.panelSimNumberController.text.trim();

      final adminCode =
          formControllers.adminCodeController.text.trim().isEmpty
              ? "1234"
              : formControllers.adminCodeController.text.trim();

      String message = "";

      if (fourGComPanels.contains(selectedPanelName)) {
        message = 'SECURICO 1234 ADD SIGNATURE $address* END';
      } else if (neuronPanels.contains(selectedPanelName)) {
        message = '< 1234 SIGNATURE $address* >';
      } else if (dialerPanels.contains(selectedPanelName)) {
        message = '$adminCode NAME $address* END';
      }

      if (message.isEmpty) {
        debugPrint("No SMS format for this panel type");
        return;
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

  Future<void> _addPanelToDB() async {
    final siteName = formControllers.siteNameController.text.trim();
    final panelSimNumber = formControllers.panelSimNumberController.text.trim();
    final adminNumber = formControllers.adminNumberController.text.trim();
    final address = formControllers.addressController.text.trim();
    final userId = await SharedPreferenceHelper.getUserId();

    final adminCode =
        widget.panelType == 'FIRE DIALERS'
            ? formControllers.adminCodeController.text.trim().isNotEmpty
                ? formControllers.adminCodeController.text.trim()
                : "1234"
            : "1234";

    final String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    debugPrint('Inserting Panel with the following values:');
    debugPrint('Panel Type: ${widget.panelType}');
    debugPrint('Panel Name: $selectedPanelName');
    debugPrint('Site Name: $siteName');
    debugPrint('Panel SIM Number: $panelSimNumber');
    debugPrint('Admin SIM Number: $adminNumber');
    debugPrint('Admin Code: $adminCode');
    debugPrint('Address: $address');
    debugPrint('User ID: $userId');

    if (!mounted) return;

    context.read<PanelCubit>().addPanel(
      userId: userId.toString(),
      panelType: widget.panelType,
      panelName: selectedPanelName!,
      site: siteName,
      panelSimNumber: panelSimNumber,
      adminCode: adminCode,
      adminMobileNumber: adminNumber,
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
      password: "00000",
      ip_address: "",
      is_ip_gsm_panel: false,
      is_ip_panel: false,
      port_no: "",
      static_ip_address: "",
      static_port_no: "",
    );

    ProgressDialog.show(context);
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

  void _savingAndNavigating() async {
    SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
    CustomNavigation.instance.push(context: context, screen: PanelListPage());
  }

  void _getFireIntruId() async {
    final userId = await SharedPreferenceHelper.getUserId();
    print('ids requested!');
    context.read<IntruCubit>().getIntru(userId: userId.toString());
    context.read<FireCubit>().getFireNumbers(userId: userId.toString());
  }

  void _savingAndNavigatingDialers() async {
    SnackBarHelper.showSnackBar(context, 'Panel Added Successfully!');
    CustomNavigation.instance.push(context: context, screen: PanelListPage());

    await SharedPreferenceHelper.setFireIdForPanelSimNumber(
      formControllers.panelSimNumberController.text.toString().trim(),
      lastFireId!,
    );
    await SharedPreferenceHelper.setIntruIdForPanelSimNumber(
      formControllers.panelSimNumberController.text.toString().trim(),
      lastIntruId!,
    );
  }

  void _addIntruAndFireNumbers() async {
    final userId = await SharedPreferenceHelper.getUserId();
    context.read<IntruCubit>().addIntru1(
      userId: userId.toString(),
      intruNo1: formControllers.adminNumberController.text.toString(),
    );
    context.read<FireCubit>().addFire1(
      userId: userId.toString(),
      fireNo1: formControllers.adminNumberController.text.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];
    siteNames = context.watch<SiteCubit>().state;
    panelSimNumbers = context.watch<PanelSimNumberCubit>().state;
    return MultiBlocListener(
      listeners: [
        BlocListener<PanelCubit, PanelState>(
          listener: (context, state) {
            if (state is AddPanelSuccess) {
              ProgressDialog.dismiss(context);
              final isDialer = dialerPanels
                  .map((e) => e.trim().toUpperCase())
                  .contains(selectedPanelName!.trim().toUpperCase());

              if (!isDialer) {
                _savingAndNavigating();
              } else {
                _addIntruAndFireNumbers();
              }
            } else if (state is AddPanelFailure) {
              ProgressDialog.dismiss(context);
              SnackBarHelper.showSnackBar(context, "Error while adding Panel");
            }
          },
        ),
        BlocListener<IntruCubit, IntruState>(
          listener: (context, state) {
            if (state is AddIntruSuccess) {
              SnackBarHelper.showSnackBar(context, state.message);
            } else if (state is AddIntruFailure) {
              SnackBarHelper.showSnackBar(context, state.message);
            }

            if (state is GetIntruSuccess) {
              final data = state.intruData;

              if (data.isNotEmpty) {
                final lastIntru = data.reduce(
                  (a, b) => a.intruId > b.intruId ? a : b,
                );
                print('getting intruId');
                lastIntruId = lastIntru.intruId.toString();
              }
            } else if (state is GetIntruFailure) {
              SnackBarHelper.showSnackBar(
                context,
                'Failed to store Intrusion Number',
              );
            }
          },
        ),
        BlocListener<FireCubit, FireState>(
          listener: (context, state) {
            if (state is AddFireSuccess) {
              SnackBarHelper.showSnackBar(context, state.message);
              _getFireIntruId();
            } else if (state is AddFireFailure) {
              SnackBarHelper.showSnackBar(context, state.message);
            }

            if (state is GetFireSuccess) {
              final data = state.fireData;

              if (data.isNotEmpty) {
                final lastIntru = data.reduce(
                  (a, b) => a.fireId > b.fireId ? a : b,
                );
                print('getting fireId');
                lastFireId = lastIntru.fireId.toString();
                if (kDebugMode) {
                  print('$lastIntruId! &  $lastFireId!');
                }

                _savingAndNavigatingDialers();
              }
            } else if (state is GetFireFailure) {
              SnackBarHelper.showSnackBar(
                context,
                'Failed to store Fire Number',
              );
            }
          },
        ),
      ],
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
              child: Row(
                children: const [
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.colorPrimary,
                                ),
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
      ),
    );
  }
}

class PanelFormControllers {
  final siteNameController = TextEditingController();
  final adminNumberController = TextEditingController();
  final panelSimNumberController = TextEditingController();
  final addressController = TextEditingController();
  final adminCodeController = TextEditingController();
  void dispose() {
    siteNameController.dispose();
    adminNumberController.dispose();
    panelSimNumberController.dispose();
    addressController.dispose();
    adminCodeController.dispose();
  }
}
