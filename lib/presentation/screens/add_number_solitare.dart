import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/constants/strings.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/utils/silent_sms.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../bottom_sheet_dialog/add_number.dart';
import '../viewModel/panel_view_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/vertical_gap.dart';

class AddNumberSolitarePage extends StatelessWidget {
  const AddNumberSolitarePage({super.key});

  List<String> getNumbers(PanelData panel) {
    final allNumbers = [
      panel.mobileNumber1,
      panel.mobileNumber2,
      panel.mobileNumber3,
      panel.mobileNumber4,
      panel.mobileNumber5,
      panel.mobileNumber6,
      panel.mobileNumber7,
      panel.mobileNumber8,
      panel.mobileNumber9,
      panel.mobileNumber10,
    ];

    if (neuronPanels.contains(panel.panelName)) {
      return allNumbers.sublist(0, 9); // show only first 9 numbers
    } else {
      return allNumbers; // show all 10 numbers for 4GCOM or others
    }
  }

  List<String> getExistingNumbers(PanelData panel) {
    return getNumbers(
      panel,
    ).where((num) => num.trim().isNotEmpty && num != "0000000000").toList();
  }

  Future<void> _sendDeleteMsg(
    BuildContext context,
    PanelViewModel viewModel,
    PanelData panel,
    int index,
  ) async {
    final message =
        neuronPanels.contains(panel.panelName)
            ? "Do you want to DELETE MOBILE NUMBER ${index + 1}?"
            : "Do you want to DELETE USER0$index number?";
    final confirm = await showConfirmationDialog(
      context: context,
      message: message,
    );

    if (confirm == true) {
      final success = await viewModel.updateMobileNumber(
        panel.panelSimNumber,
        "0000000000",
        index,
      );

      if (success) {
        if (neuronPanels.contains(panel.panelName)) {
          String message = '';
          index += 1;
          if (index == 2) {
            message = '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+910000000000*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
          } else if (index == 3) {
            message = '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+910000000000*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
          } else if (index == 4) {
            message = '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+910000000000*
#05-+91${panel.mobileNumber4}*
>
''';
          } else if (index == 5) {
            message = '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+910000000000*
>
''';
          } else if (index == 6) {
            message = '''
< 1234 TEL NO
#06-+910000000000*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
          } else if (index == 7) {
            message = '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+910000000000*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
          } else if (index == 8) {
            message = '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+910000000000*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
          } else if (index == 9) {
            message = '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+910000000000*
#10-+91${panel.mobileNumber9}*
>
''';
          } else if (index == 10) {
            message = '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+910000000000*
>
''';
          } else {
            message = "";
          }
          await sendSmsSilently(panel.panelSimNumber, message);
        } else {
          await sendSmsSilently(
            panel.panelSimNumber,
            'SECURICO 1234 REMOVE USER0$index END',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete number.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PanelViewModel>(
      builder: (context, viewModel, child) {
        final panel = viewModel.currentPanel;

        if (panel == null) {
          return const Scaffold(body: Center(child: Text("No panel selected")));
        }

        final numbers = getNumbers(panel);
        final existingNumbers = getExistingNumbers(panel);

        return Scaffold(
          appBar: const CustomAppBar(pageName: 'Add Number', isFilter: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const VerticalSpace(),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      panel.adminMobileNumber,
                      style: const TextStyle(
                        color: AppColors.colorPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const VerticalSpace(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    final number = numbers[index];
                    final isEmpty =
                        number == "0000000000" || number.trim().isEmpty;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 1,
                        horizontal: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              number,
                              style: const TextStyle(
                                color: AppColors.colorPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                () => showAddNumberBottomSheet(
                                  context,
                                  panel,
                                  index + 1,
                                  viewModel,
                                  existingNumbers: existingNumbers,
                                ),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.litePrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.colorPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                isEmpty
                                    ? null
                                    : () => _sendDeleteMsg(
                                      context,
                                      viewModel,
                                      panel,
                                      index + 1,
                                    ),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    isEmpty
                                        ? Colors.grey
                                        : AppColors.litePrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.delete,
                                color: isEmpty ? Colors.white : AppColors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
