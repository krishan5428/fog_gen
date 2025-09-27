import 'package:fire_nex/presentation/screens/alert_module.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(pageName: 'More Settings', isFilter: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Center(
          child: Column(
            children: [
              CustomButton(
                buttonText: 'Add/Remove Numbers',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlertModulePage()),
                  );
                },
              ),
              // VerticalSpace(),
              // CustomButton(
              //   buttonText: 'Play/Record Voice Message',
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder:
              //             (context) => PlayRecoModulePage(
              //               panelSimNumber: panelSimNumber,
              //             ),
              //       ),
              //     );
              //   },
              // ),
              // VerticalSpace(),
              // CustomButton(
              //   buttonText: 'Zone Name-Wise Mappings',
              //   onPressed: () {},
              // ),
              // VerticalSpace(),
              // CustomButton(
              //   buttonText: 'Timer Settings',
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder:
              //             (context) =>
              //                 TimerPage(panelSimNumber: panelSimNumber),
              //       ),
              //     );
              //   },
              // ),
              // VerticalSpace(),
              // CustomButton(
              //   buttonText: 'Auto Arm/Disarm',
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder:
              //             (context) =>
              //                 AutoArmDisarmPage(panelSimNumber: panelSimNumber),
              //       ),
              //     );
              //   },
              // ),
              // VerticalSpace(),
              // CustomButton(
              //   buttonText: 'Notification Settings',
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => ProfilePage()),
              //     );
              //   },
              // ),
              // VerticalSpace(),
              // CustomButton(buttonText: 'Zone Enable Disable', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
