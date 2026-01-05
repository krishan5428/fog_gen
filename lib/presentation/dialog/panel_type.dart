import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/navigation.dart';
import '../screens/add_ip_gprs_panel.dart';
import '../widgets/vertical_gap.dart';

class PanelTypeDialog extends StatelessWidget {
  const PanelTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with background color
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Select FOG PANEL Type',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildCard(
                    imagePath: 'assets/images/pro_logo.png',
                    title: 'fog_gen_new Pro',
                    aspectRatio: 6 / 3,
                    onTap: () {
                      CustomNavigation.instance.pop(context);
                      CustomNavigation.instance.push(
                        context: context,
                        screen: const AddPanelFormScreen(
                          panelType: 'FOGGER PANEL',
                          panelName: 'fog_gen_new Pro',
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    imagePath: 'assets/images/nexus_logo.png',
                    title: 'fog_gen_new Nexus',
                    aspectRatio: 6 / 3,
                    onTap: () {
                      CustomNavigation.instance.pop(context);
                      CustomNavigation.instance.push(
                        context: context,
                        screen: const AddPanelFormScreen(
                          panelType: 'FOGGER PANEL',
                          panelName: 'fog_gen_new Nexus',
                        ),
                      );
                    },
                  ),
                  _buildCard(
                    imagePath: 'assets/images/edge_logo.png',
                    title: 'fog_gen_new Edge',
                    aspectRatio: 6 / 3,
                    onTap: () {
                      CustomNavigation.instance.pop(context);
                      CustomNavigation.instance.push(
                        context: context,
                        screen: const AddPanelFormScreen(
                          panelType: 'FOGGER PANEL',
                          panelName: 'fog_gen_new Edge',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Floating close button
          Positioned(
            top: -10,
            right: -10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String imagePath,
    required String title,
    required double aspectRatio,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
                const VerticalSpace(),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
