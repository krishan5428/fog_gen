import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';

import '../../constants/app_colors.dart';
import '../../core/repo/user_repo.dart';
import '../../utils/snackbar_helper.dart';
import '../cubit/forgotPass/forget_pswd_cubit.dart';
import '../cubit/forgotPass/forgot_pass_state.dart';
import '../widgets/form_section.dart';

void forgotPasswordDialog(BuildContext context) {
  final mobileController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => ForgetPswdCubit(repository: context.read<UserRepo>()),
        child: BlocConsumer<ForgetPswdCubit, ForgetPswdState>(
          listener: (context, state) {
            if (state is ForgetPswdStateLoading) {
              ProgressDialog.show(context);
            } else {
              ProgressDialog.dismiss(context);
            }
            if (state is ForgetPswdStateError) {
              SnackBarHelper.showSnackBar(context, state.error);
            }
            if (state is ForgetPswdStateSuccess) {
              SnackBarHelper.showSnackBar(context, state.msg);
              Navigator.of(dialogContext).pop();
            }
          },
          builder: (context, state) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: const Text("Forgot Password"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormSection(
                        label: 'Enter Mobile Number',
                        controller: mobileController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.length != 10) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: AppColors.black),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.colorPrimary,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: state is ForgetPswdStateLoading
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      context
                                          .read<ForgetPswdCubit>()
                                          .forgetPassword(
                                            mobile: mobileController.text
                                                .trim(),
                                          );
                                    }
                                  },
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
