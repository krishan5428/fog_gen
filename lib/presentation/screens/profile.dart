import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../bottom_sheet_dialog/change_email.dart';
import '../bottom_sheet_dialog/change_user_mobile_number.dart';
import '../bottom_sheet_dialog/change_user_name.dart';
import '../bottom_sheet_dialog/change_user_passcode.dart';
import '../cubit/user/user_cubit.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_item.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userId;
  String? name;
  String? phone;
  String? email;
  String? pass;

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await SharedPreferenceHelper.getUserData();
    pass = await SharedPreferenceHelper.getPass();

    setState(() {
      userId = user?.usrId.toString();
      name = user?.name ?? 'N/A';
      phone = user?.mobile ?? 'N/A';
      email = user?.email ?? 'N/A';
      isLoading = false;
    });
  }

  void _showMoreOptions() {
    final fontSize = Responsive.fontSize(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'More Options',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOption(
                'Update Username',
                    () => _openBottomSheet(
                  ChangeUserName(userId: userId!, formKey: 'name'),
                ),
              ),
              _buildOption(
                'Update Mobile Number',
                    () => _openBottomSheet(
                  ChangeUserMobileBottomSheet(
                    userId: userId!,
                    formKey: 'mobile',
                  ),
                ),
              ),
              _buildOption('Update Password', () {
                if (pass == null) return;
                _openBottomSheet(
                  ChangeUserPasswordBottomSheet(
                    userId: userId!,
                    formKey: 'password',
                    currentPassword: pass!,
                  ),
                );
              }),
              _buildOption(
                'Update Email',
                    () => _openBottomSheet(
                  ChangeEmailAddressBottomSheet(
                    userId: userId!,
                    formKey: 'email',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => CustomNavigation.instance.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.colorAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openBottomSheet(Widget bottomSheet) {
    CustomNavigation.instance.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => bottomSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);

    return Scaffold(
      appBar: CustomAppBar(
        pageName: 'Profile',
        isFilter: false,
        isProfile: true,
        onMoreTaps: _showMoreOptions,
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  buildContactItem(
                    context,
                    icon: Icons.person,
                    text: name ?? 'N/A',
                  ),
                  const Divider(),
                  buildContactItem(
                    context,
                    icon: Icons.phone,
                    text: phone ?? 'N/A',
                  ),
                  const Divider(),
                  buildContactItem(
                    context,
                    icon: Icons.email,
                    text: email ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: spacingBwtView),
        child: SafeArea(
          minimum: EdgeInsets.fromLTRB(
            spacingBwtView * 2,
            0,
            spacingBwtView * 2,
            spacingBwtView,
          ),
          child: CustomButton(
            buttonText: 'Delete Profile',
            foregroundColor: AppColors.white,
            backgroundColor: AppColors.colorPrimary,
            onPressed: _confirmDelete,
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final TextEditingController passwordController = TextEditingController();
    bool isProceedStep = false;
    String actionButtonText = 'Proceed';
    String? errorMessage;
    final spacing = Responsive.spacingBwtView(context);
    final fontSize = Responsive.fontSize(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocListener<UserCubit, UserState>(
              listener: (context, state) {
                if (!mounted) return;
                if (state is UserLoading) {
                  ProgressDialog.show(context);
                } else if (state is UserDeleteSuccess) {
                  setState(() {
                    errorMessage = 'User deleted successfully!';
                  });
                  ProgressDialog.dismiss(context);
                  _handlingDelete(context);
                } else if (state is UserDeleteFailure) {
                  ProgressDialog.dismiss(context);
                  setState(() {
                    errorMessage = state.message;
                  });
                }
              },
              child: Dialog(
                insetPadding: EdgeInsets.all(spacing * 3),
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing * 2,
                    vertical: spacing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmation',
                        style: TextStyle(fontSize: fontSize * 1.3),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        'Are you sure you want to delete your profile?\nThis action cannot be undone.',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),

                      if (isProceedStep) ...[
                        FormSection(
                          label: 'Enter Password',
                          controller: passwordController,
                          validator:
                              (value) =>
                          value == null || value.isEmpty
                              ? 'Invalid entry'
                              : null,
                        ),
                        if (errorMessage != null && errorMessage!.isNotEmpty)
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(top: spacing / 2),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],

                      SizedBox(height: spacing * 1.5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                () => CustomNavigation.instance.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.colorAccent),
                            ),
                          ),
                          SizedBox(width: spacing),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: AppColors.white,
                              backgroundColor: AppColors.colorPrimary,
                            ),
                            child: Text(
                              actionButtonText,
                              style: TextStyle(fontSize: fontSize),
                            ),
                            onPressed: () {
                              if (!isProceedStep) {
                                setState(() {
                                  isProceedStep = true;
                                  actionButtonText = 'Delete';
                                  errorMessage = null;
                                });
                              } else {
                                final password = passwordController.text.trim();
                                if (password.isEmpty) {
                                  setState(() {
                                    errorMessage =
                                    'Please enter your password.';
                                  });
                                  return;
                                }
                                setState(() {
                                  errorMessage = null;
                                });
                                context.read<UserCubit>().deleteUser(
                                  mobile: phone!,
                                  password: password,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOption(String text, VoidCallback onTap) {
    final fontSize = Responsive.fontSize(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize * 1.1,
            color: AppColors.colorPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

void _handlingDelete(context) async {
  await Future.delayed(const Duration(seconds: 1));
  await SharedPreferenceHelper.clearLoginState();
  CustomNavigation.instance.pop(context);
  CustomNavigation.instance.pushAndRemove(
    context: context,
    screen: const LoginScreen(),
  );
}
