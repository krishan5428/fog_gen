import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/constants/strings.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/presentation/screens/add_number_solitare.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

import '../../utils/navigation.dart';
import '../dialog/ok_dialog.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/vertical_gap.dart';
import 'fire_numbers.dart';
import 'intrusion_numbers.dart';

class AlertModulePage extends StatelessWidget {
  final PanelData panelData;
  const AlertModulePage({super.key, required this.panelData});

  @override
  Widget build(BuildContext context) {
    final String panelNameKey = panelData.panelName.trim().toUpperCase();
    final bool isDialer = dialerPanels.contains(panelNameKey);

    final String adminCode = panelData.adminCode;
    final String sim = panelData.panelSimNumber;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(pageName: 'Alert Module', isFilter: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          children: [
            // -------------------------------------------------------------------
            // NON-DIALER PANELS → Only Add Number and Retrieve Number
            // -------------------------------------------------------------------
            if (!isDialer) ...[
              CustomButton(
                buttonText: 'Add Number',
                onPressed: () {
                  CustomNavigation.instance.push(
                    context: context,
                    screen: AddNumberSolitarePage(panelData: panelData),
                  );
                },
              ),
              const VerticalSpace(),

              CustomButton(
                buttonText: 'Retrieve Number',
                onPressed: () async {
                  final confirm = await showConfirmationDialog(
                    context: context,
                    message: 'Do you want to retrieve numbers from the panel?',
                  );

                  if (confirm == true) {
                    final result = await ProgressDialogWithMessage.show(
                      context,
                      messages: ['SECURICO 1234 VIEW USERS END'],
                      panelSimNumber: sim,
                    );
                    if (result == true) {
                      await showInfoDialog(
                        context: context,
                        message: 'You will receive the number list via SMS!',
                      );
                    } else {
                      SnackBarHelper.showSnackBar(context, 'Cancelled');
                    }
                  }
                },
              ),
            ],

            // -------------------------------------------------------------------
            // DIALER PANELS → ONLY Intrusion + Fire options
            // -------------------------------------------------------------------
            if (isDialer) ...[
              CustomButton(
                buttonText: 'Add / Remove Intrusion Number',
                onPressed: () {
                  CustomNavigation.instance.push(
                    context: context,
                    screen: IntrusionNumbersPage(panelData: panelData),
                  );
                },
              ),
              const VerticalSpace(),

              CustomButton(
                buttonText: 'Add / Remove Fire Number',
                onPressed: () {
                  CustomNavigation.instance.push(
                    context: context,
                    screen: FireNumbersPage(panelData: panelData),
                  );
                },
              ),
              const VerticalSpace(),

              // Retrieve Intrusion Numbers
              CustomButton(
                buttonText: 'Retrieve Intrusion Numbers',
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    message: 'Retrieve intrusion numbers?',
                  );

                  if (confirmed == true) {
                    final isSend = await ProgressDialogWithMessage.show(
                      context,
                      messages: [
                        '$adminCode RETRIEVE INT TELE 1-5 END',
                        '$adminCode RETRIEVE INT TELE 6-10 END',
                      ],
                      panelSimNumber: sim,
                    );

                    isSend == true
                        ? SnackBarHelper.showSnackBar(context, 'Request Sent')
                        : SnackBarHelper.showSnackBar(context, 'Cancelled');
                  }
                },
              ),
              const VerticalSpace(),

              // Retrieve Fire Numbers
              CustomButton(
                buttonText: 'Retrieve Fire Numbers',
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    message: 'Retrieve fire numbers?',
                  );

                  if (confirmed == true) {
                    final isSend = await ProgressDialogWithMessage.show(
                      context,
                      messages: [
                        '$adminCode RETRIEVE FIRE TELE 1-5 END',
                        '$adminCode RETRIEVE FIRE TELE 6-10 END',
                      ],
                      panelSimNumber: sim,
                    );

                    isSend == true
                        ? SnackBarHelper.showSnackBar(context, 'Request Sent')
                        : SnackBarHelper.showSnackBar(context, 'Cancelled');
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
