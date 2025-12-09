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

class ChangeUserPasswordBottomSheet extends StatefulWidget {
  final String userId;
  final String formKey;
  final String currentPassword;

  const ChangeUserPasswordBottomSheet({
    super.key,
    required this.userId,
    required this.formKey,
    required this.currentPassword,
  });

  @override
  State<ChangeUserPasswordBottomSheet> createState() =>
      _ChangeUserPasswordBottomSheetState();
}

class _ChangeUserPasswordBottomSheetState
    extends State<ChangeUserPasswordBottomSheet> {
  final currentCodeController = TextEditingController();
  final newCodeController = TextEditingController();
  final reenterCodeController = TextEditingController();

  String? currentCodeError;
  String? newCodeError;

  @override
  void dispose() {
    currentCodeController.dispose();
    newCodeController.dispose();
    reenterCodeController.dispose();
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
            message: 'Password Updated!\nYou need to login again!',
            confirmText: 'OK',
          );

          if (confirmed == true && context.mounted) {
            final navContext = context;
            CustomNavigation.instance.pop(navContext);
            SnackBarHelper.showSnackBar(navContext, 'Updated Successfully');

            // Delay to ensure the bottom sheet is fully removed
            Future.microtask(() {
              CustomNavigation.instance.pushAndRemove(
                context: navContext,
                screen: LoginScreen(),
              );
            });
          }
        } else if (state is UserUpdateFailure) {
          ProgressDialog.dismiss(context);
          SnackBarHelper.showSnackBar(context, 'Error while updating password');
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
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
              'Update Password',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 1.1,
              ),
            ),
            SizedBox(height: spacingBwtView * 2),
            CustomTextField(
              hintText: 'Current Password',
              controller: currentCodeController,
              errorText: currentCodeError,
            ),
            const VerticalSpace(),
            CustomTextField(
              hintText: 'New Password',
              controller: newCodeController,
              errorText: newCodeError,
            ),
            const VerticalSpace(),
            CustomTextField(
              hintText: 'Re-enter Password',
              controller: reenterCodeController,
              errorText: newCodeError,
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
      currentCodeError = null;
      newCodeError = null;
    });

    final current = currentCodeController.text.trim();
    final newCode = newCodeController.text.trim();
    final reentered = reenterCodeController.text.trim();

    if (current != widget.currentPassword) {
      setState(() {
        currentCodeError = 'Current code is incorrect';
      });
      return;
    }

    if (newCode != reentered) {
      setState(() {
        newCodeError = 'Codes do not match';
      });
      return;
    }

    context.read<UserCubit>().updateUser(
      userId: widget.userId,
      value: newCode,
      key: widget.formKey,
    );
  }
}
