import 'package:flutter/material.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/screens/add_panel.dart';

import '../widgets/vertical_gap.dart';

class PanelTypeDialog extends StatelessWidget {
  const PanelTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey.shade100,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.colorPrimary,
                border: Border.all(color: AppColors.colorPrimary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Select Panel Type',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildCard(
              imagePath: 'assets/images/fire_panel.png',
              title: 'FIRE PANEL',
              aspectRatio: 8 / 3,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPanelPage(panelType: 'FIRE PANEL'),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildCard(
              imagePath: 'assets/images/dialers.png',
              title: 'FIRE DIALERS',
              aspectRatio: 8 / 3,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddPanelPage(panelType: 'FIRE DIALERS'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String imagePath,
    required String title,
    required double aspectRatio,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: AppColors.textGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
              VerticalSpace(),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.colorPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
