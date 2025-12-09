import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/constants/urls.dart';
import 'package:fire_nex/presentation/dialog/url_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fire_nex/presentation/dialog/progress.dart';
import 'package:fire_nex/presentation/screens/about_us.dart';
import 'package:fire_nex/presentation/screens/profile.dart';
import 'package:fire_nex/presentation/screens/vendor_profile.dart';
import 'package:fire_nex/utils/app_info.dart';
import 'package:fire_nex/utils/navigation.dart';

import '../../utils/auth_helper.dart';
import '../../utils/responsive.dart';
import '../dialog/panel_type.dart';
import '../screens/login.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AddDrawerState();
}

class _AddDrawerState extends State<AppDrawer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _version = AppInfo.instance.version;
  }

  @override
  Widget build(BuildContext context) {
    final smallTextSize = Responsive.smallTextSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.litePrimary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/sec_logo.png',
                    width: spacingBwtView * 15,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  icon: Icons.home,
                  text: "Home",
                  onTap: () {
                    CustomNavigation.instance.pop(context);
                  },
                ),
                _drawerItem(
                  icon: Icons.add_circle_outlined,
                  text: "Add Panel",
                  onTap: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return const PanelTypeDialog();
                      },
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.person,
                  text: "Profile",
                  onTap: () {
                    CustomNavigation.instance.popAndPush(
                      context: context,
                      screen: ProfilePage(),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.person_pin_rounded,
                  text: "Vendor Details",
                  onTap: () {
                    CustomNavigation.instance.popAndPush(
                      context: context,
                      screen: VendorProfilePage(),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.support_agent,
                  text: "Technical Support",
                  onTap: () {
                    CustomNavigation.instance.popAndPush(
                      context: context,
                      screen: AboutUsPage(),
                    );
                  },
                ),
                // _drawerItem(
                //   icon: Icons.contact_support,
                //   text: "Raise a Complaint",
                //   onTap: () {
                //     CustomNavigation.instance.popAndPush(
                //       context: context,
                //       screen: ComplaintHistoryPage(),
                //     );
                //   },
                // ),
                _drawerItem(
                  icon: Icons.support,
                  text: "Contact Us",
                  onTap: () {
                    showUrlDialog(context, contactUsUrl, "Contact Us");
                  },
                ),
                _drawerItem(
                  icon: Icons.business,
                  text: "About Us",
                  onTap: () {
                    showUrlDialog(context, aboutUsUrl, "About Us");
                  },
                ),
                // _drawerItem(icon: Icons.help, text: "Need Help", onTap: () {}),
                _drawerItem(
                  icon: Icons.question_answer,
                  text: "Enquiry",
                  onTap: () {
                    showUrlDialog(context, contactUsUrl, "Enquiry");
                  },
                ),
                _drawerItem(
                  icon: Icons.web,
                  text: "Official Website",
                  onTap: () {
                    showUrlDialog(context, contactUsUrl, "Official Website");
                  },
                ),
                // _drawerItem(
                //   icon: Icons.cloud_upload,
                //   text: "Backup",
                //   onTap: () {},
                // ),
                // _drawerItem(
                //   icon: Icons.cloud_download,
                //   text: "Restore",
                //   onTap: () {},
                // ),
                _drawerItem(
                  icon: Icons.logout,
                  text: "Logout",
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacingBwtView * 1.2),
            child: Text(
              "Version: $_version",
              style: TextStyle(
                color: Colors.grey,
                fontSize: smallTextSize * 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final fontSize = Responsive.fontSize(context);

    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade800, size: fontSize * 1.2),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

void _logout(BuildContext context) async {
  ProgressDialog.show(context, message: 'Logging you out!');
  await SharedPreferenceHelper.clearLoginState();

  if (!context.mounted) return;

  await Future.delayed(const Duration(seconds: 2));

  ProgressDialog.dismiss(context);

  if (!context.mounted) return;

  CustomNavigation.instance.pushAndRemove(
    context: context,
    screen: LoginScreen(),
  );
}
