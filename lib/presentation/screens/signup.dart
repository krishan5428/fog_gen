import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:fire_nex/utils/snackbar_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/urls.dart';
import '../cubit/user/user_cubit.dart';
import '../dialog/progress.dart';
import '../dialog/url_dialog.dart';
import '../widgets/custom_button.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

  // Future<void> _handleSignUp() async {
  //   final name = _nameController.text.trim();
  //   final mobile = _mobileController.text.trim();
  //   final email = _emailController.text.trim();
  //   final password = _passwordController.text.trim();
  //   final confirmPassword = _rePasswordController.text.trim();
  //
  //   if (name.isEmpty || mobile.isEmpty || email.isEmpty || password.isEmpty) {
  //     SnackBarHelper.showSnackBar(context, 'Please fill in all fields.');
  //     return;
  //   }
  //
  //   if (password != confirmPassword) {
  //     if (!mounted) return;
  //     SnackBarHelper.showSnackBar(context, 'Passwords do not match.');
  //     return;
  //   }
  //   final userVM = context.read<UserViewModel>();
  //   final success = await userVM.insertUser(name, email, mobile, password);
  //
  //   if (!mounted) return;
  //
  //   if (success) {
  //     SnackBarHelper.showSnackBar(context, 'User Registered Successfully!');
  //     CustomNavigation.instance.pushReplace(
  //       context: context,
  //       screen: LoginScreen(),
  //     );
  //   } else {
  //     SnackBarHelper.showSnackBar(context, 'Registered failed!');
  //   }
  // }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _rePasswordController.text.trim();

    if (name.isEmpty || mobile.isEmpty || email.isEmpty || password.isEmpty) {
      SnackBarHelper.showSnackBar(context, 'Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      SnackBarHelper.showSnackBar(context, 'Passwords do not match.');
      return;
    }

    context.read<UserCubit>().signUp(
      name: name,
      email: email,
      mobile: mobile,
      password: password,
      devInfo: "Android",
      deviceId: "device123",
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserLoading) {
          ProgressDialog.show(context);
        } else {
          ProgressDialog.dismiss(context);
          if (state is UserSignUpSuccess) {
            SnackBarHelper.showSnackBar(context, state.message);
            CustomNavigation.instance.pushAndRemove(
              context: context,
              screen: LoginScreen(),
            );
          } else if (state is UserSignUpFailure) {
            SnackBarHelper.showSnackBar(context, state.message);
          }
        }
      },

      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 70),
                Image.asset('assets/images/sec_logo.png', width: 200),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "SignUp ",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                buildTextField("Enter Name", Icons.person, _nameController),
                SizedBox(height: 20),
                buildTextField(
                  "Enter Mobile Number",
                  Icons.phone,
                  isNumber: true,
                  _mobileController,
                  maxLength: 10,
                ),
                SizedBox(height: 20),
                buildTextField(
                  "Enter Email",
                  Icons.email,
                  isEmail: true,
                  _emailController,
                ),
                SizedBox(height: 20),
                buildTextField(
                  "Enter Password",
                  Icons.password,
                  isPassword: true,
                  _passwordController,
                ),
                SizedBox(height: 20),
                buildTextField(
                  "Re-enter Password",
                  Icons.password,
                  isPassword: true,
                  _rePasswordController,
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
                CustomButton(buttonText: 'Sign up', onPressed: _handleSignUp),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Existing User?", style: TextStyle(fontSize: 11)),
                    TextButton(
                      onPressed: () {
                        CustomNavigation.instance.push(
                          context: context,
                          screen: LoginScreen(),
                        );
                      },
                      child: Text(
                        "Login here!",
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

  Widget buildTextField(
    String hintText,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isNumber = false,
    bool isEmail = false,
    int? maxLength,
  }) {
    return TextField(
      obscureText: isPassword,
      controller: controller,
      keyboardType:
          isNumber
              ? TextInputType.phone
              : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: hintText,
        prefixIcon: Icon(icon, color: AppColors.colorAccent),
        labelStyle: TextStyle(color: AppColors.colorPrimary),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorAccent),
        ),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.colorPrimary, width: 1.5),
        ),
      ),
    );
  }
}
