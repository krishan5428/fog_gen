import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../cubit/fire/fire_cubit.dart';
import '../cubit/intrusion/intru_cubit.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../dialog/progress_with_message.dart';
import '../screens/panel_list.dart';
import '../widgets/custom_text_field.dart';

class ChangeNumberBottomSheet extends StatefulWidget {
  const ChangeNumberBottomSheet({
    super.key,
    required this.userId,
    this.intruId,
    this.fireId,
    this.panelId,
    required this.count,
    this.initialNumber,
    required this.isAdd,
    required this.isUpdate,
    required this.existingNumbers,
    required this.panelData,
  });

  final String userId;
  final String? intruId;
  final String? fireId;
  final String? panelId;
  final String? initialNumber;
  final int count;
  final bool isAdd;
  final bool isUpdate;
  final List<String> existingNumbers;
  final PanelData? panelData;

  @override
  State<ChangeNumberBottomSheet> createState() =>
      _ChangeNumberBottomSheetState();
}

class _ChangeNumberBottomSheetState extends State<ChangeNumberBottomSheet> {
  final newController = TextEditingController();
  String? infoMessage;
  Color messageColor = Colors.black;

  @override
  void initState() {
    super.initState();
    if (widget.initialNumber != null) {
      newController.text = widget.initialNumber!;
    }
  }

  @override
  void dispose() {
    newController.dispose();
    super.dispose();
  }

  Future<void> _handleIntruSuccess(BuildContext context, String msg) async {
    context.read<IntruCubit>().getIntru(userId: widget.userId);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) CustomNavigation.instance.pop(context);
  }

  Future<void> _handleFireSuccess(BuildContext context, String msg) async {
    context.read<FireCubit>().getFireNumbers(userId: widget.userId);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) CustomNavigation.instance.pop(context);
  }

  Future<void> _handleUpdateNumberSuccess(
    BuildContext context,
    String msg,
  ) async {
    context.read<PanelCubit>().getPanel(userId: widget.userId);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      CustomNavigation.instance.pushReplace(
        context: context,
        screen: PanelListPage(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<IntruCubit, IntruState>(
          listener: (context, state) {
            if (state is IntruLoading) {
              ProgressDialog.show(context);
            } else {
              ProgressDialog.dismiss(context);
            }

            if (state is UpdateIntruSuccess) {
              _handleIntruSuccess(context, state.msg);
            } else if (state is UpdateIntruFailure) {
              SnackBarHelper.showSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<FireCubit, FireState>(
          listener: (context, state) {
            if (state is FireLoading) {
              ProgressDialog.show(context);
            } else {
              ProgressDialog.dismiss(context);
            }

            if (state is UpdateFireSuccess) {
              _handleFireSuccess(context, state.msg);
            } else if (state is UpdateFireFailure) {
              SnackBarHelper.showSnackBar(context, state.message);
            }
          },
        ),
        BlocListener<PanelCubit, PanelState>(
          listener: (context, state) {
            if (state is UpdatePanelsSuccess) {
              debugPrint('add number success');
              _handleUpdateNumberSuccess(context, state.msg);
            } else if (state is UpdatePanelsFailure) {
              debugPrint('add number failure');
              SnackBarHelper.showSnackBar(context, state.message);
            }
          },
        ),
      ],
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: spacingBwtView * 4,
              height: spacingBwtView / 2.5,
              margin: EdgeInsets.only(bottom: spacingBwtView * 2),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.isAdd ? 'Add Number' : 'Edit Number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 1.1,
              ),
            ),
            SizedBox(height: spacingBwtView * 2),

            CustomTextField(
              hintText: 'Enter Number',
              controller: newController,
              isNumber: true,
              maxLength: 10,
            ),
            SizedBox(height: spacingBwtView * 2),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => CustomNavigation.instance.pop(context),
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
            SizedBox(height: spacingBwtView * 2),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      infoMessage = null;
    });
    final newNumber = newController.text.trim();

    if (!RegExp(r'^\d{10}$').hasMatch(newNumber)) {
      setState(() {
        infoMessage = 'Enter a valid 10-digit number';
        messageColor = Colors.red;
      });
      return;
    }

    final existing =
        widget.existingNumbers
            .where((num) => num != widget.initialNumber)
            .toList();

    if (existing.contains(newNumber)) {
      setState(() {
        infoMessage = 'This number already exists in the list';
        messageColor = Colors.red;
      });
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      message:
          widget.isAdd
              ? 'Do you want to add this number?'
              : 'Do you want to update this number?',
      cancelText: 'No',
      confirmText: 'Yes',
    );

    if (!mounted || confirmed != true) return;

    final isFire = widget.fireId != null && widget.fireId!.isNotEmpty;
    final isIntru = widget.intruId != null && widget.intruId!.isNotEmpty;
    final isPanelId = widget.panelId != null && widget.panelId!.isNotEmpty;

    debugPrint('isFire: $isFire && isIntru: $isIntru');

    String sms = "";
    if (isFire) {
      sms =
          "${widget.panelData?.adminCode ?? ''} TEL NO FIRE #${widget.count}-$newNumber* END";
    } else if (isIntru) {
      sms =
          "${widget.panelData?.adminCode ?? ''} TEL NO INTRUSION #${widget.count}-$newNumber* END";
    } else if (isPanelId) {
      sms = getMobileNumberMessages(
        panel: widget.panelData!,
        newNumber: newNumber,
        index: widget.count,
      );
    } else {
      SnackBarHelper.showSnackBar(context, 'No update target provided');
      return;
    }

    var result = await ProgressDialogWithMessage.show(
      context,
      messages: [sms],
      panelSimNumber: widget.panelData!.panelSimNumber,
    );

    if (result == true) {
      if (isFire) {
        context.read<FireCubit>().updateFireNo(
          userId: widget.userId,
          count: widget.count,
          fireId: widget.fireId!,
          number: newNumber,
        );
      } else if (isIntru) {
        context.read<IntruCubit>().updateIntruNo(
          userId: widget.userId,
          count: widget.count,
          intruId: widget.intruId!,
          number: newNumber,
        );
      } else if (isPanelId) {
        context.read<PanelCubit>().updateSolitareMobileNumber(
          userId: widget.panelData!.userId,
          panelId: widget.panelData!.pnlId,
          mobileNumber: newNumber,
          index: widget.count.toString(),
        );
      }
    } else {
      setState(() {
        infoMessage = 'Failed to send command to panel.';
        messageColor = Colors.red;
      });
    }
  }
}

String getMobileNumberMessages({
  required PanelData panel,
  required String newNumber,
  required int index,
}) {
  index += 0;
  if (index == 2) {
    return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91$newNumber*
#03-+91${panel.mobileNumber3}*
#04-+91${panel.mobileNumber4}*
#05-+91${panel.mobileNumber5}*
>
''';
  } else if (index == 3) {
    return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber2}*
#03-+91$newNumber*
#04-+91${panel.mobileNumber4}*
#05-+91${panel.mobileNumber5}*
>
''';
  } else if (index == 4) {
    return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber2}*
#03-+91${panel.mobileNumber3}*
#04-+91$newNumber*
#05-+91${panel.mobileNumber5}*
>
''';
  } else if (index == 5) {
    return '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber2}*
#03-+91${panel.mobileNumber3}*
#04-+91${panel.mobileNumber4}*
#05-+91$newNumber*
>
''';
  } else if (index == 6) {
    return '''
< 1234 TEL NO
#06-+91$newNumber*
#07-+91${panel.mobileNumber7}*
#08-+91${panel.mobileNumber8}*
#09-+91${panel.mobileNumber9}*
#10-+91${panel.mobileNumber10}*
>
''';
  } else if (index == 7) {
    return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber6}*
#07-+91$newNumber*
#08-+91${panel.mobileNumber8}*
#09-+91${panel.mobileNumber9}*
#10-+91${panel.mobileNumber10}*
>
''';
  } else if (index == 8) {
    return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber6}*
#07-+91${panel.mobileNumber7}*
#08-+91$newNumber*
#09-+91${panel.mobileNumber9}*
#10-+91${panel.mobileNumber10}*
>
''';
  } else if (index == 9) {
    return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber6}*
#07-+91${panel.mobileNumber7}*
#08-+91${panel.mobileNumber8}*
#09-+91$newNumber*
#10-+91${panel.mobileNumber10}*
>
''';
  } else if (index == 10) {
    return '''
< 1234 TEL NO
#06-+91${panel.mobileNumber6}*
#07-+91${panel.mobileNumber7}*
#08-+91${panel.mobileNumber8}*
#09-+91${panel.mobileNumber9}*
#10-+91$newNumber*
>
''';
  } else {
    return "";
  }
}
