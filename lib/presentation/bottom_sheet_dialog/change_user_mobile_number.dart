import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../cubit/user/user_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../screens/login.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/vertical_gap.dart';

class ChangeUserMobileBottomSheet extends StatefulWidget {
  final String userId;
  final String formKey;

  const ChangeUserMobileBottomSheet({
    super.key,
    required this.userId,
    required this.formKey,
  });

  @override
  State<ChangeUserMobileBottomSheet> createState() =>
      _ChangeUserMobileBottomSheetState();
}

class _ChangeUserMobileBottomSheetState
    extends State<ChangeUserMobileBottomSheet> {
  final newController = TextEditingController();
  final reenterController = TextEditingController();

  String? currentError;
  String? newError;

  @override
  void dispose() {
    newController.dispose();
    reenterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return BlocListener<UserCubit, UserState>(
      listener: (context, state) async {
        if (state is UserLoading) {
          ProgressDialog.show(context, message: 'Updating, please wait!');
        }

        if (state is UserUpdateSuccess) {
          ProgressDialog.dismiss(context);

          final confirmed = await showConfirmationDialog(
            context: context,
            message: 'User Mobile number Updated!\nYou need to login again!',
            confirmText: 'OK',
          );

          print("Dialog result: $confirmed");

          if (confirmed == true && context.mounted) {
            final navContext = context;
            CustomNavigation.instance.pop(navContext);
            SnackBarHelper.showSnackBar(navContext, 'Updated Successfully');

            Future.microtask(() {
              CustomNavigation.instance.pushAndRemove(
                context: navContext,
                screen: LoginScreen(),
              );
            });
          }
        } else if (state is UserUpdateFailure) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(
            context,
            'Error while updating mobile number',
          );
        }
      },
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
              'Update User Mobile Number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 1.1,
              ),
            ),
            SizedBox(height: spacingBwtView * 2),
            CustomTextField(
              hintText: 'New Number',
              controller: newController,
              isNumber: true,
              maxLength: 10,
              errorText: newError,
            ),
            const VerticalSpace(),
            CustomTextField(
              hintText: 'Re-enter Number',
              controller: reenterController,
              isNumber: true,
              maxLength: 10,
              errorText: newError,
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
                  child: const Text(
                    "Submit",
                  ),
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
      currentError = null;
      newError = null;
    });

    final newNumber = newController.text.trim();
    final reentered = reenterController.text.trim();

    if (newNumber.length != 10) {
      setState(() => newError = 'Enter valid 10-digit number');
      return;
    }

    if (newNumber != reentered) {
      setState(() => newError = 'Numbers do not match');
      return;
    }

    ProgressDialog.show(context);

    if (context.mounted) {
      ProgressDialog.dismiss(context);
    }

    context.read<UserCubit>().updateUser(
      userId: widget.userId,
      value: newNumber,
      key: widget.formKey,
    );
  }
}
