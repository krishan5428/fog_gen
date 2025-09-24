import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/viewModel/vendor_view_model.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';

import '../../utils/auth_helper.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';

class AddVendorPage extends StatefulWidget {
  const AddVendorPage({super.key});

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final vendorNameController = TextEditingController();
  final vendorEmailIdController = TextEditingController();
  final vendorAddressController = TextEditingController();
  final vendorMobileNumberController = TextEditingController();

  @override
  void dispose() {
    vendorNameController.dispose();
    vendorEmailIdController.dispose();
    vendorAddressController.dispose();
    vendorMobileNumberController.dispose();
    super.dispose();
  }

  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();

    _steps.addAll([
      {
        'label': 'Vendor Name',
        'controller': vendorNameController,
        'keyboardType': TextInputType.text,
        'maxLength': 20,
      },
      {
        'label': 'Vendor Mobile Number',
        'controller': vendorMobileNumberController,
        'keyboardType': TextInputType.phone,
        'maxLength': 10,
      },
      {
        'label': 'Vendor E-Mail Id',
        'controller': vendorEmailIdController,
        'keyboardType': TextInputType.emailAddress,
      },
      {
        'label': 'Vendor Address',
        'controller': vendorAddressController,
        'keyboardType': TextInputType.text,
        'maxLength': 30,
      },
    ]);
  }

  Future<void> _goToNext() async {
    final step = _steps[_currentStep];
    {
      final controller = step['controller'] as TextEditingController;
      final label = step['label'] as String;
      final value = controller.text.trim();

      if (value.isEmpty) {
        SnackBarHelper.showSnackBar(context, "Please fill is $label");
        return;
      }

      if (label == 'Vendor Mobile Number') {
        if (value.length != 10) {
          SnackBarHelper.showSnackBar(
            context,
            "Vendor Mobile Number must be exactly 10 digits",
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
        message:
            'Do you want to add vendor named ${vendorNameController.text.trim()}?',
      );

      if (confirmed == true) {
        _addVendor();
      }
    }
  }

  Future<void> _addVendor() async {
    final vendorViewModel = context.read<VendorViewModel>();

    final vendorName = vendorNameController.text.trim();
    final vendorMobileNumber = vendorMobileNumberController.text.trim();
    final vendorEmailAddress = vendorEmailIdController.text.trim();
    final vendorAddress = vendorAddressController.text.trim();
    final userId = await SharedPreferenceHelper.getUserId();

    final result = await vendorViewModel.insertVendor(
      vendorName,
      vendorEmailAddress,
      vendorMobileNumber,
      userId!,
      vendorAddress,
    );

    if (!mounted) return;

    if (result == true) {
      SnackBarHelper.showSnackBar(context, 'Vendor added successfully');
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
    } else {
      SnackBarHelper.showSnackBar(context, 'Failed to add vendor');
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
              children: [
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
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(top: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormSection(
                    label: currentStepData['label'],
                    keyboardType: currentStepData['keyboardType'],
                    controller: currentStepData['controller'],
                    maxLength: currentStepData['maxLength'],
                  ),
                  VerticalSpace(height: 20),
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
