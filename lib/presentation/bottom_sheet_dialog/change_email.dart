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

class ChangeEmailAddressBottomSheet extends StatefulWidget {
  final String userId;
  final String formKey;

  const ChangeEmailAddressBottomSheet({
    super.key,
    required this.userId,
    required this.formKey,
  });

  @override
  State<ChangeEmailAddressBottomSheet> createState() =>
      _ChangeEmailAddressBottomSheetState();
}

class _ChangeEmailAddressBottomSheetState
    extends State<ChangeEmailAddressBottomSheet> {
  final TextEditingController _addressController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _addressController.dispose();
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
            message: 'Email Updated!\nYou need to login again!',
            confirmText: 'OK',
          );

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
          SnackBarHelper.showSnackBar(context, 'Error while updating email');
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
              'Update Email Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 1.1,
              ),
            ),

            SizedBox(height: spacingBwtView * 2),

            CustomTextField(
              hintText: 'Enter new email address',
              controller: _addressController,
              isEmail: true,
              errorText: _errorText,
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
                  onPressed: () {
                    final address = _addressController.text.trim();
                    if (address.isEmpty) {
                      setState(
                        () => _errorText = 'Email Address cannot be empty',
                      );
                      return;
                    }
                    context.read<UserCubit>().updateUser(
                      userId: widget.userId,
                      key: widget.formKey,
                      value: address,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorPrimary,
                    foregroundColor: AppColors.white,
                  ),
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
}
