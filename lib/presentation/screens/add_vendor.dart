import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/vendor_data.dart';
import '../../core/data/repo_impl/vendor_repo_impl.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../cubit/vendor/vendor_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';
import '../widgets/vertical_gap.dart';

class AddVendorPage extends StatelessWidget {
  const AddVendorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorCubit(VendorRepoImpl()),
      child: AddVendorUI(),
    );
  }
}

class AddVendorUI extends StatefulWidget {
  const AddVendorUI({super.key});

  @override
  State<AddVendorUI> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorUI> {
  final vendorNameController = TextEditingController();
  final vendorEmailIdController = TextEditingController();
  final vendorAddressController = TextEditingController();
  final vendorMobileNumberController = TextEditingController();
  int? userId;
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
        SnackBarHelper.showSnackBar(context, 'Please fill is $label');
        return;
      }

      if (label == 'Vendor Mobile Number') {
        if (value.length != 10) {
          SnackBarHelper.showSnackBar(
            context,
            'Vendor Mobile Number must be exactly 10 digits',
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
    final vendorName = vendorNameController.text.trim();
    final vendorMobileNumber = vendorMobileNumberController.text.trim();
    final vendorEmailAddress = vendorEmailIdController.text.trim();
    final vendorAddress = vendorAddressController.text.trim();
    userId = await SharedPreferenceHelper.getUserId();
    final String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    debugPrint("Add Vendor Params:");
    debugPrint("userId: $userId");
    debugPrint("vendorName: $vendorName");
    debugPrint("vendorMobile: $vendorMobileNumber");
    debugPrint("vendorEmail: $vendorEmailAddress");
    debugPrint("vendorAddress: $vendorAddress");
    debugPrint("createdAt: $currentTime");

    if (!mounted) return;

    if (userId == null) {
      SnackBarHelper.showSnackBar(context, 'User ID not found');
      return;
    }
    context.read<VendorCubit>().addVendor(
      userId: userId.toString(),
      vendorName: vendorName,
      vendorEmail: vendorEmailAddress,
      vendorMobile: vendorMobileNumber,
      vendorAddress: vendorAddress,
      createdAt: currentTime,
    );
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

    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);
    final smallTextSize = Responsive.smallTextSize(context);

    return BlocListener<VendorCubit, VendorState>(
      listener: (context, state) {
        if (state is VendorLoading) {
          ProgressDialog.show(context);
        } else if (state is AddVendorSuccess || state is AddVendorFailure) {
          ProgressDialog.dismiss(context);
          ProgressDialog.dismiss(context);
          if (state is AddVendorSuccess) {
            SnackBarHelper.showSnackBar(context, state.message);

            final vendorData = VendorData(
              // vendor_id: 'DateTime.now().millisecondsSinceEpoch.toString()',
              user_id: userId.toString(),
              vendor_name: vendorNameController.text.trim(),
              vendor_email: vendorEmailIdController.text.trim(),
              vendor_mobile: vendorMobileNumberController.text.trim(),
              vendor_address: vendorAddressController.text.trim(),
            );

            // Save to shared prefs
            SharedPreferenceHelper.saveVendorData(vendorData);
            CustomNavigation.instance.pushReplace(
              context: context,
              screen: PanelListPage(),
            );
          } else {
            SnackBarHelper.showSnackBar(context, 'Error while adding Vendor');
          }
        } else {
          SnackBarHelper.showSnackBar(context, 'Something went wrong');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          pageName: 'Add Vendor',
          isFilter: false,
          isDash: false,
          isProfile: false,
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
              padding: EdgeInsets.symmetric(
                horizontal: spacingBwtView,
                vertical: spacingBwtView * 0.7,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: fontSize,
                    color: AppColors.colorPrimary,
                  ),
                  SizedBox(width: spacingBwtView * 0.5),
                  Text(
                    'Please add the Vendor details...',
                    style: TextStyle(
                      color: AppColors.colorPrimary,
                      fontSize: smallTextSize,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.all(spacingBwtView * 2.5),
                margin: EdgeInsets.only(top: spacingBwtView * 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormSection(
                      label: currentStepData['label'],
                      keyboardType: currentStepData['keyboardType'],
                      controller: currentStepData['controller'],
                      maxLength: currentStepData['maxLength'],
                    ),
                    VerticalSpace(height: spacingBwtView),
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: CustomButton(
                              buttonText: "BACK",
                              buttonTextSize: fontSize,
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
                            buttonTextSize: fontSize,
                            backgroundColor: AppColors.colorPrimary,
                            foregroundColor: AppColors.white,
                            onPressed: _goToNext,
                          ),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 10),
                    // CustomButton(
                    //   buttonText: 'SKIP',
                    //   backgroundColor: AppColors.colorPrimary,
                    //   foregroundColor: AppColors.litePrimary,
                    //   onPressed: () {},
                    // ),
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
