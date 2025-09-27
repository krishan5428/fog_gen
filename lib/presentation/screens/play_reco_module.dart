import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';

import '../../utils/silent_sms.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/vertical_gap.dart';

class PlayRecoModulePage extends StatelessWidget {
  const PlayRecoModulePage({super.key, required this.panelSimNumber});

  final String panelSimNumber;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PanelViewModel>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(pageName: 'Play/Record Module', isFilter: false),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: FutureBuilder(
          future: viewModel.getPanelByPanelSimNumber(panelSimNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Panel data not found.'));
            }

            final panel = snapshot.data!;
            final adminCode = panel.adminCode;

            return Column(
              children: [
                CustomButton(
                  buttonText: 'Play Intrusion Message',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final result = await showConfirmationDialog(
                      context: context,
                      message: 'Do you want to Play Intrusion Message?',
                      cancelText: 'No',
                      confirmText: 'Yes',
                    );

                    if (result == true) {
                      final String message1 = '$adminCode PLAY INT MSG END';

                      ProgressDialog.show(
                        context,
                        message: 'Sending panel SMS...',
                      );

                      try {
                        await Future.delayed(const Duration(seconds: 2));
                        await Future(
                          () => sendSms(panelSimNumber, message1),
                        );

                        ProgressDialog.dismiss(context);

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Request Processed Successfully!'),
                          ),
                        );

                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => PlayRecoModulePage(
                                  panelSimNumber: panelSimNumber,
                                ),
                          ),
                        );
                      } catch (e) {
                        ProgressDialog.dismiss(context);

                        messenger.showSnackBar(
                          SnackBar(content: Text('Error sending SMS: $e')),
                        );
                      }
                    }
                  },
                ),

                VerticalSpace(),
                CustomButton(
                  buttonText: 'Play Fire Message',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final result = await showConfirmationDialog(
                      context: context,
                      message: 'Do you want to Play Fire Message?',
                      cancelText: 'No',
                      confirmText: 'Yes',
                    );

                    if (result == true) {
                      final String message1 = '$adminCode PLAY FIRE MSG END';

                      ProgressDialog.show(
                        context,
                        message: 'Sending panel SMS...',
                      );

                      try {
                        await Future.delayed(const Duration(seconds: 2));
                        await Future(
                          () => sendSms(panelSimNumber, message1),
                        );

                        ProgressDialog.dismiss(context);

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Request Processed Successfully!'),
                          ),
                        );

                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => PlayRecoModulePage(
                                  panelSimNumber: panelSimNumber,
                                ),
                          ),
                        );
                      } catch (e) {
                        ProgressDialog.dismiss(context);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error sending SMS: $e')),
                        );
                      }
                    }
                  },
                ),
                VerticalSpace(),
                CustomButton(
                  buttonText: 'Record Intrusion Message',
                  onPressed: () async {
                    final result = await showConfirmationDialog(
                      context: context,
                      message: 'Do you want to Record Intrusion Message?',
                      cancelText: 'No',
                      confirmText: 'Yes',
                    );

                    if (result == true) {
                      final String message1 = '$adminCode RECO INT MSG END';

                      ProgressDialog.show(
                        context,
                        message: 'Sending panel SMS...',
                      );

                      try {
                        await Future.delayed(const Duration(seconds: 2));
                        await Future(
                          () => sendSms(panelSimNumber, message1),
                        );

                        ProgressDialog.dismiss(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request Processed Successfully!'),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlayRecoModulePage(
                                  panelSimNumber: panelSimNumber,
                                ),
                          ),
                        );
                      } catch (e) {
                        ProgressDialog.dismiss(
                          context,
                        ); // corrected from Navigator.pop
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sending SMS: $e')),
                        );
                      }
                    }
                  },
                ),
                VerticalSpace(),
                CustomButton(
                  buttonText: 'Record Fire Message',
                  onPressed: () async {
                    final result = await showConfirmationDialog(
                      context: context,
                      message: 'Do you want to Record Fire Message?',
                      cancelText: 'No',
                      confirmText: 'Yes',
                    );

                    if (result == true) {
                      final String message1 = '$adminCode RECO FIRE MSG END';

                      ProgressDialog.show(
                        context,
                        message: 'Sending panel SMS...',
                      );

                      try {
                        await Future.delayed(const Duration(seconds: 2));
                        await Future(
                          () => sendSms(panelSimNumber, message1),
                        );

                        ProgressDialog.dismiss(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request Processed Successfully!'),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PlayRecoModulePage(
                                  panelSimNumber: panelSimNumber,
                                ),
                          ),
                        );
                      } catch (e) {
                        ProgressDialog.dismiss(
                          context,
                        ); // corrected from Navigator.pop
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sending SMS: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
