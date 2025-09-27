import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/presentation/viewModel/vendor_view_model.dart';
import 'package:fire_nex/utils/auth_helper.dart';

import '../../constants/app_colors.dart';
import '../../data/database/app_database.dart';
import '../bottom_sheet_dialog/vendor_update.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_item.dart';
import '../../utils/navigation.dart';
import 'login.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  void _showMoreOptions(VendorData vendor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'More Options',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOption(
                'Update Vendor Name',
                () => _openBottomSheet(
                  VendorUpdateBottomSheetDialog(
                    userId: vendor.id,
                    formKey: "name",
                    currentValue: vendor.name,
                  ),
                ),
              ),
              _buildOption(
                'Update Mobile Number',
                () => _openBottomSheet(
                  VendorUpdateBottomSheetDialog(
                    userId: vendor.id,
                    formKey: "mobile",
                    currentValue: vendor.mobileNumber,
                  ),
                ),
              ),
              _buildOption(
                'Update Email',
                () => _openBottomSheet(
                  VendorUpdateBottomSheetDialog(
                    userId: vendor.id,
                    formKey: "email",
                    currentValue: vendor.email,
                  ),
                ),
              ),
              _buildOption(
                'Update Address',
                () => _openBottomSheet(
                  VendorUpdateBottomSheetDialog(
                    userId: vendor.id,
                    formKey: "address",
                    currentValue: vendor.address,
                  ),
                ),
              ),
              _buildOption('Delete Vendor Data', () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                        'Are you sure you want to delete this vendor data? This cannot be undone.',
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
                  final vendorViewModel = context.read<VendorViewModel>();
                  await vendorViewModel.deleteVendor(vendor.id);

                  await SharedPreferenceHelper.clearLoginState();

                  CustomNavigation.instance.pushReplace(
                    context: context,
                    screen: const LoginScreen(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vendor data deleted successfully'),
                    ),
                  );
                }
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
      setState(() {}); // refresh vendor data
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: SharedPreferenceHelper.getUserId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userId = snapshot.data;
        final vendorViewModel = context.read<VendorViewModel>();

        // Dummy vendor
        if (userId == 999999) {
          final dummyVendor = VendorData(
            id: 999999,
            userId: 100000,
            name: "Dummy Vendor",
            mobileNumber: "+91 9123456789",
            email: "vendor@example.com",
            address: "1234 Demo Street, City, Country",
          );
          return _buildVendorProfile(dummyVendor);
        }

        return FutureBuilder<VendorData?>(
          future: vendorViewModel.getVendorByUserId(userId!),
          builder: (context, vendorSnapshot) {
            if (vendorSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
              return const Center(child: Text('Vendor data not found.'));
            }

            return _buildVendorProfile(vendorSnapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildVendorProfile(VendorData vendor) {
    return Scaffold(
      appBar: CustomAppBar(
        pageName: 'Vendor Profile',
        isFilter: false,
        isProfile: true,
        onMoreTaps: () => _showMoreOptions(vendor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              buildContactItem(context, icon: Icons.person, text: vendor.name),
              const Divider(),
              buildContactItem(
                context,
                icon: Icons.phone,
                text: vendor.mobileNumber,
              ),
              const Divider(),
              buildContactItem(context, icon: Icons.email, text: vendor.email),
              const Divider(),
              buildContactItem(
                context,
                icon: Icons.location_on,
                text: vendor.address,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String text, VoidCallback onTap) {
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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.colorPrimary,
          ),
        ),
      ),
    );
  }
}
