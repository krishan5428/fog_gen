import 'package:flutter/services.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/dialog/url_dialog.dart';
import 'package:fog_gen_new/presentation/screens/add_vendor.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/presentation/screens/signup.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/urls.dart';
import '../../core/data/repo_impl/vendor_repo_impl.dart';
import '../../utils/get_device_type.dart';
import '../cubit/user/user_cubit.dart';
import '../dialog/forgot_password_dialog.dart';
import '../dialog/progress.dart';
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

  void _handleLogin(BuildContext context) {
    final mobile = _mobileController.text.trim();
    final pass = _passwordController.text.trim();

    if (mobile.isNotEmpty && pass.isNotEmpty) {
      context.read<UserCubit>().login(mobile, pass);
    } else {
      SnackBarHelper.showSnackBar(context, 'Please enter credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final device = getDeviceType();

    return BlocListener<UserCubit, UserState>(
      listener: (context, state) async {
        if (state is UserLoading) {
          ProgressDialog.show(context);
        } else {
          ProgressDialog.dismiss(context);
          if (state is UserLoginSuccess) {
            ProgressDialog.show(context, message: 'Getting vendor data');
            final user = state.user;

            await SharedPreferenceHelper.setLoginState(
              true,
              user.usrId,
              device,
            );
            await SharedPreferenceHelper.saveUserData(user);
            await SharedPreferenceHelper.setPass(
              _passwordController.text.trim(),
            );

            debugPrint('loginUserId: ${user.usrId}');

            final vendorRepo = VendorRepoImpl();
            final vendorResponse = await vendorRepo.getVendor(
              user.usrId.toString(),
            );

            if (vendorResponse.status) {
              debugPrint(
                'Vendor List Fetched: ${vendorResponse.vendorData.length}',
              );
              if (vendorResponse.vendorData.isEmpty) {
                ProgressDialog.dismiss(context);
                CustomNavigation.instance.pushAndRemove(
                  context: context,
                  screen: const AddVendorPage(),
                );
              } else {
                final lastVendor = vendorResponse.vendorData.last;
                await SharedPreferenceHelper.saveVendorData(lastVendor);
                ProgressDialog.dismiss(context);
                CustomNavigation.instance.pushAndRemove(
                  context: context,
                  screen: const PanelListPage(),
                );
              }
            } else {
              ProgressDialog.dismiss(context);
              CustomNavigation.instance.pushAndRemove(
                context: context,
                screen: const PanelListPage(),
              );
            }
          } else if (state is UserLoginFailure) {
            SnackBarHelper.showSnackBar(context, "Something went wrong!");
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 50.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Image.asset('assets/images/logo.png', width: 120),
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
                  maxLength: 10,
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
                        recognizer: TapGestureRecognizer()
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

                CustomButton(
                  buttonText: 'Login',
                  onPressed: () {
                    _handleLogin(context);
                  },
                ),

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
      ),
    );
  }
}
