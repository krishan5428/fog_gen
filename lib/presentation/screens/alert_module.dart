import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/screens/add_number_solitare.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/silent_sms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialog/ok_dialog.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/vertical_gap.dart';

class AlertModulePage extends StatelessWidget {
  const AlertModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<PanelViewModel>().currentPanel;

    if (panel == null) {
      return const Scaffold(body: Center(child: Text("No panel selected")));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(pageName: 'Alert Module', isFilter: false),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          children: [
            CustomButton(
              buttonText: 'Add Number',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNumberSolitarePage(),
                  ),
                );
              },
            ),
            VerticalSpace(),
            CustomButton(
              buttonText: 'Retrieve Number',
              onPressed: () async {
                final confirm = await showConfirmationDialog(
                  context: context,
                  message: 'Do you want to retrieve numbers from Panel?',
                );

                if (confirm == true) {
                  await sendSmsSilently(
                    panel.panelSimNumber,
                    'SECURICO 1234 VIEW USERS END',
                  );

                  await showInfoDialog(
                    context: context,
                    message:
                        'You will get the number list from Panel in your Messaging app!',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
