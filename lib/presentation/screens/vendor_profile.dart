import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/presentation/viewModel/vendor_view_model.dart';
import 'package:fire_nex/utils/auth_helper.dart';

import '../../data/database/app_database.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_item.dart';

class VendorProfilePage extends StatelessWidget {
  const VendorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(pageName: 'Vendor Profile', isFilter: false),
      body: FutureBuilder<int?>(
        future: SharedPreferenceHelper.getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userId = snapshot.data ?? '';
          final vendorViewModel = context.read<VendorViewModel>();

          return FutureBuilder<VendorData?>(
            future: vendorViewModel.getVendorByUserId(userId as int),
            builder: (context, vendorSnapshot) {
              if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
                return const Center(child: Text('Vendor data not found.'));
              }

              final vendor = vendorSnapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      buildContactItem(
                        context,
                        icon: Icons.person,
                        text: vendor.name,
                      ),
                      Divider(),
                      buildContactItem(
                        context,
                        icon: Icons.phone,
                        text: vendor.mobileNumber,
                      ),
                      Divider(),
                      buildContactItem(
                        context,
                        icon: Icons.email,
                        text: vendor.email,
                      ),
                      Divider(),
                      buildContactItem(
                        context,
                        icon: Icons.location_on,
                        text: vendor.address,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
