import 'package:fire_nex/constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_section.dart';

class AddNumbersPage extends StatelessWidget {
  const AddNumbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(pageName: 'Add Numbers', isFilter: false),
      body: Column(
        children: [
          // Info bar
          Container(
            color: AppColors.litePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: const [
                Icon(Icons.info, size: 14, color: AppColors.colorPrimary),
                SizedBox(width: 5),
                Text(
                  'Please add the panel with Specific Panel Details...',
                  style: TextStyle(color: AppColors.colorPrimary, fontSize: 10),
                ),
              ],
            ),
          ),

          Container(
            margin: EdgeInsets.only(top: 100),
            padding: EdgeInsets.only(top: 100),
            child: Expanded(
              child: Column(
                children: [
                  const FormSection(label: "Add Number 2"),
                  const FormSection(
                    label: "Add Number 3",
                    keyboardType: TextInputType.number,
                  ),
                  const FormSection(
                    label: "Add Number 4",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const FormSection(label: "Add Number 5"),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          buttonText: "BACK",
                          backgroundColor: AppColors.litePrimary,
                          foregroundColor: AppColors.colorPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          buttonText: "NEXT",
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    buttonText: 'SKIP',
                    backgroundColor: AppColors.litePrimary,
                    foregroundColor: AppColors.colorPrimary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
