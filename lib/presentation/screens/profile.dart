import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/viewModel/user_view_model.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../bottom_sheet_dialog/user_update.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_item.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showMoreOptions(UserData user) {
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
                  UpdateUserFieldBottomSheet(
                    userId: user.id, // ✅ use from user directly
                    formKey: "name",
                    currentValue: user.name,
                  ),
                ),
              ),
              _buildOption(
                'Update Mobile Number',
                () => _openBottomSheet(
                  UpdateUserFieldBottomSheet(
                    userId: user.id,
                    formKey: "mobile",
                    currentValue: user.mobileNumber,
                  ),
                ),
              ),
              _buildOption(
                'Update Password',
                () => _openBottomSheet(
                  UpdateUserFieldBottomSheet(
                    userId: user.id,
                    formKey: "password",
                  ),
                ),
              ),
              _buildOption(
                'Update Email',
                () => _openBottomSheet(
                  UpdateUserFieldBottomSheet(
                    userId: user.id,
                    formKey: "email",
                    currentValue: user.email,
                  ),
                ),
              ),
              _buildOption('Delete User Data', () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                        'Are you sure you want to delete your user data? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  // Delete using ViewModel
                  final userViewModel = context.read<UserViewModel>();
                  await userViewModel.deleteUser(user.id);

                  // Clear saved userId
                  await SharedPreferenceHelper.clearLoginState();

                  // Navigate to login
                  CustomNavigation.instance.pushReplace(
                    context: context,
                    screen: const LoginScreen(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User data deleted successfully'),
                    ),
                  );
                }
              }),
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

  void _openBottomSheet(Widget sheet) async {
    Navigator.pop(context); // close dialog first
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => sheet,
    );
    if (updated == true) {
      setState(() {}); // refresh user data
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.read<UserViewModel>();

    return FutureBuilder<int?>(
      future: SharedPreferenceHelper.getUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data;

        return FutureBuilder<UserData?>(
          future: userId != null ? userViewModel.getUserByUserId(userId) : null,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;

            return Scaffold(
              appBar: CustomAppBar(
                pageName: 'Profile',
                isFilter: false,
                isProfile: true,
                onMoreTaps: user != null ? () => _showMoreOptions(user) : null,
              ),
              body:
                  userSnapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : user != null
                      ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              buildContactItem(
                                context,
                                icon: Icons.person,
                                text: user.name,
                              ),
                              const Divider(),
                              buildContactItem(
                                context,
                                icon: Icons.phone,
                                text: user.mobileNumber,
                              ),
                              const Divider(),
                              buildContactItem(
                                context,
                                icon: Icons.email,
                                text: user.email,
                              ),
                            ],
                          ),
                        ),
                      )
                      : const Center(child: Text('User data not available.')),
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
