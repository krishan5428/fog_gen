import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../../core/data/pojo/panel_data.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/form_section.dart';

class AddNumberBottomSheet extends StatefulWidget {
  final PanelData panel;
  final int index;
  final List<String> existingNumbers;

  const AddNumberBottomSheet({
    super.key,
    required this.panel,
    required this.index,
    required this.existingNumbers,
  });

  @override
  State<AddNumberBottomSheet> createState() => _AddNumberBottomSheetState();
}

class _AddNumberBottomSheetState extends State<AddNumberBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    final index = widget.index;

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if(state is PanelLoading){
          ProgressDialog.show(context);
        }
        if (state is UpdatePanelsSuccess) {
          ProgressDialog.dismiss(context);
          debugPrint('add number success');
          CustomNavigation.instance.popWithResult(
            context: context,
            result: state.panelData,
          );
        } else if (state is UpdatePanelsFailure) {
          ProgressDialog.dismiss(context);
          debugPrint('add number failure');
          SnackBarHelper.showSnackBar(context, state.message);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                neuronPanels.contains(panel.panelName)
                    ? "Add Number for MOBILE NUMBER ${(index + 1).toString().padLeft(2, '0')}"
                    : "Add Number for USER${index.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colorPrimary,
                ),
              ),
              const SizedBox(height: 20),
              FormSection(
                label: 'Add new Number',
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 10,
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.colorAccent),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colorPrimary,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: _handleSubmit,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final panel = widget.panel;
    final newNumber = _controller.text.trim();
    final normalizedNewNumber = newNumber.replaceAll(RegExp(r'\D'), '');
    final normalizedExisting =
        widget.existingNumbers
            .map((e) => e.replaceAll(RegExp(r'\D'), '').trim())
            .toList();

    if (normalizedNewNumber.length != 10) {
      setState(() => _errorText = 'Number must be exactly 10 digits');
      return;
    }

    if (newNumber == "1234567890") {
      setState(() => _errorText = 'This number is not allowed');
      return;
    }

    if (normalizedNewNumber.isEmpty ||
        normalizedNewNumber == panel.adminMobileNumber ||
        normalizedNewNumber == panel.panelSimNumber ||
        normalizedExisting.contains(normalizedNewNumber)) {
      setState(() {
        _errorText =
            'This number is already used, please use a different number!';
      });
      return;
    }

    final device = await SharedPreferenceHelper.getDeviceType();
    final smsPermission = await Permission.sms.status;

    final confirm = await showConfirmationDialog(
      context: context,
      message: 'Do you want to add/update this number?',
    );

    if (confirm != true) {
      CustomNavigation.instance.popWithResult(context: context, result: false);
      return;
    }

    final message = getMobileNumberMessages(
      panel: panel,
      newNumber: newNumber,
      index: widget.index,
    );

    if (message.isEmpty) {
      setState(() => _errorText = 'Failed to generate message');
      return;
    }

    bool result = false;
    result =
        (await _trySendSms(
          context,
          device,
          smsPermission,
          panel.panelSimNumber,
          [message],
        )) ??
        false;

    if (result) {
      context.read<PanelCubit>().updatePanelData(
        userId: panel.userId,
        panelId: panel.pnlId,
        key: 'mobile_number${widget.index.toString()}',
        value: newNumber,
      );
      SnackBarHelper.showSnackBar(context, 'Number added successfully!');
    } else {
      SnackBarHelper.showSnackBar(context, 'Revoked');
      CustomNavigation.instance.popWithResult(context: context, result: false);
    }
  }
}

// 🔧 Helper methods (unchanged)
Future<bool?> _trySendSms(
  BuildContext context,
  String device,
  PermissionStatus smsPermission,
  String simNumber,
  List<String> messages,
) async {
  final result = ProgressDialogWithMessage.show(
    context,
    messages: messages,
    panelSimNumber: simNumber,
  );
  return result;
}

String getMobileNumberMessages({
  required PanelData panel,
  required String newNumber,
  required int index,
}) {
  if (neuronPanels.contains(panel.panelName)) {
    index += 1;
    if (index == 2) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91$newNumber*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 3) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91$newNumber*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 4) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91$newNumber*
#05-+91${panel.mobileNumber4}*
>
''';
    } else if (index == 5) {
      return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91$newNumber*
>
''';
    } else if (index == 6) {
      return '''
< 1234 TEL NO
#06-+91$newNumber*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 7) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91$newNumber*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 8) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91$newNumber*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 9) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91$newNumber*
#10-+91${panel.mobileNumber9}*
>
''';
    } else if (index == 10) {
      return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91$newNumber*
>
''';
    } else {
      return "";
    }
  } else if (fourGComPanels.contains(panel.panelName)) {
    return "SECURICO 1234 ADD USER${index.toString().padLeft(2, '0')} +91-$newNumber END";
  } else {
    return "";
  }
}
