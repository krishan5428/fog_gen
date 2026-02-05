import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/app_colors.dart';
import '../../core/data/pojo/vendor_data.dart';
import '../../utils/auth_helper.dart';
import '../../utils/navigation.dart';
import '../../utils/responsive.dart';
import '../cubit/vendor/vendor_cubit.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_item.dart';
import '../widgets/custom_button.dart';
import 'login.dart';

class VendorProfilePage extends StatelessWidget {
  const VendorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(isDash: false,
        pageName: 'Vendor Profile',
        isFilter: false,
        isProfile: false,
      ),
      body: FutureBuilder<VendorData?>(
        future: SharedPreferenceHelper.getVendorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Vendor data not available'));
          }

          final vendor = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                buildContactItem(
                  context,
                  icon: Icons.person,
                  text: vendor.vendor_name,
                ),
                const Divider(),
                buildContactItem(
                  context,
                  icon: Icons.phone,
                  text: vendor.vendor_mobile,
                ),
                const Divider(),
                buildContactItem(
                  context,
                  icon: Icons.email,
                  text: vendor.vendor_email,
                ),
                const Divider(),
                buildContactItem(
                  context,
                  icon: Icons.location_on,
                  text: vendor.vendor_address,
                ),
              ],
            ),
          );
        },
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
            buttonText: 'Delete Vendor',
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: AppColors.white,
            onPressed: () async {
              final vendor = await SharedPreferenceHelper.getVendorData();
              if (vendor != null) {
                _confirmDelete(context, vendor.vendor_mobile);
              }
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String vendorMobile) {
    String? errorMessage;
    final spacing = Responsive.spacingBwtView(context);
    final fontSize = Responsive.fontSize(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return BlocListener<VendorCubit, VendorState>(
              listener: (context, state) {
                if (state is VendorLoading) {
                  ProgressDialog.show(context);
                } else if (state is DeleteVendorSuccess) {
                  ProgressDialog.dismiss(context);
                  setState(() {
                    errorMessage = 'Deleted successfully!';
                  });
                  _handlingDelete(context);
                } else if (state is DeleteVendorFailure) {
                  ProgressDialog.dismiss(context);
                  setState(() => errorMessage = state.message);
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
                        "Are you sure you want to delete Vendor's profile?\nThis action cannot be undone.",
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),

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

                      SizedBox(height: spacing * 1.5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
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
                            onPressed: () {
                              setState(() => errorMessage = null);
                              context.read<VendorCubit>().deleteVendor(
                                mobile: vendorMobile,
                              );
                            },
                            child: Text(
                              "DELETE",
                              style: TextStyle(fontSize: fontSize),
                            ),
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
}

void _handlingDelete(context) async {
  await Future.delayed(const Duration(seconds: 1));
  await SharedPreferenceHelper.clearLoginState();
  await SharedPreferenceHelper.clearVendorData();
  CustomNavigation.instance.pop(context);
  CustomNavigation.instance.pushAndRemove(
    context: context,
    screen: const LoginScreen(),
  );
}