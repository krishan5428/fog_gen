import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/dialog/url_dialog.dart';
import 'package:fire_nex/presentation/screens/add_vendor.dart';
import 'package:fire_nex/presentation/screens/panel_list.dart';
import 'package:fire_nex/presentation/screens/signup.dart';
import 'package:fire_nex/presentation/viewModel/user_view_model.dart';
import 'package:fire_nex/presentation/viewModel/vendor_view_model.dart';
import 'package:fire_nex/utils/auth_helper.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/urls.dart';
import '../../utils/get_device_type.dart';
import '../dialog/forgot_password_dialog.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  void _handleLogin() async {
    try {
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text.trim();

      if (mobile.isEmpty || password.isEmpty) {
        SnackBarHelper.showSnackBar(
          context,
          "Please enter both mobile number and password.",
        );
        return;
      }

      final device = getDeviceType();

      if (mobile == "9899446573" && password == "123456") {
        final dummyUserId = 999999;

        await SharedPreferenceHelper.setLoginState(true, dummyUserId, device);

        SnackBarHelper.showSnackBar(context, 'Login Successful');
        CustomNavigation.instance.pushReplace(
          context: context,
          screen: PanelListPage(),
        );
        return;
      }

      // Real user check
      final userViewModel = context.read<UserViewModel>();
      final user = await userViewModel.getUserByMobileAndPassword(
        mobile,
        password,
      );

      if (!mounted) return;

      if (user != null) {
        final vendorViewModel = context.read<VendorViewModel>();
        final vendor = await vendorViewModel.getVendorByUserId(user.id);

        await SharedPreferenceHelper.setLoginState(true, user.id, device);

        SnackBarHelper.showSnackBar(context, 'Login Successful');

        CustomNavigation.instance.pushReplace(
          context: context,
          screen: vendor != null ? PanelListPage() : AddVendorPage(),
        );
      } else {
        SnackBarHelper.showSnackBar(
          context,
          'Invalid credentials. Please try again.',
        );
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(
        context,
        'An error occurred. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 150),
              Image.asset('assets/images/sec_logo.png', width: 200),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login ",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              TextField(
                keyboardType: TextInputType.phone,
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixIcon: Icon(Icons.phone, color: AppColors.colorAccent),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.colorAccent),
                  ),
                  labelStyle: TextStyle(color: AppColors.colorPrimary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.colorPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                obscureText: _obscureText,
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: AppColors.colorAccent),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.colorPrimary),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.colorAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  labelStyle: TextStyle(color: AppColors.colorPrimary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.colorPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "By continuing, you accept our ",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  RichText(
                    text: TextSpan(
                      text: ' Terms & Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.colorPrimary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              showUrlDialog(
                                context,
                                policyUrl,
                                'Terms & Privacy Policy',
                              );
                            },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              CustomButton(buttonText: 'Login', onPressed: _handleLogin),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    forgotPasswordDialog(context);
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New User?", style: TextStyle(fontSize: 11)),
                  TextButton(
                    onPressed: () {
                      CustomNavigation.instance.push(
                        context: context,
                        screen: SignUpScreen(),
                      );
                    },
                    child: Text(
                      "Sign up here!",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
