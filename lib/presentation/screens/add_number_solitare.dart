import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/dialog/confirmation_dialog.dart';
import 'package:fog_gen_new/utils/auth_helper.dart';
import 'package:fog_gen_new/utils/common_classes.dart';
import 'package:fog_gen_new/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/data/pojo/panel_data.dart';
import '../bottom_sheet_dialog/add_number.dart';
import '../cubit/panel/panel_cubit.dart';
import '../widgets/app_bar.dart';
import '../widgets/vertical_gap.dart';

class AddNumberSolitarePage extends StatefulWidget {
  final PanelData panelData;
  const AddNumberSolitarePage({super.key, required this.panelData});

  @override
  State<AddNumberSolitarePage> createState() => _AddNumberSolitarePageState();
}

class _AddNumberSolitarePageState extends State<AddNumberSolitarePage> {
  late PanelData panelData;

  @override
  void initState() {
    super.initState();
    panelData = widget.panelData; // initialize once
  }

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

    return allNumbers.sublist(0, 9); // show only first 9 numbers
  }

  Future<String> getDevice() async {
    final device = await SharedPreferenceHelper.getDeviceType();
    return device;
  }

  List<String> getExistingNumbers(PanelData panel) {
    return getNumbers(
      panel,
    ).where((num) => num.trim().isNotEmpty && num != "0000000000").toList();
  }

  Future<void> _sendDeleteMsg(
    BuildContext context,
    PanelData panel,
    int index,
  ) async {
    final title = "Do you want to DELETE MOBILE NUMBER ${index + 1}?";
    final confirm = await showConfirmationDialog(
      context: context,
      message: title,
    );

    String device = await getDevice();
    final smsPermission = await Permission.sms.status;
    bool? isSend = false;

    if (confirm == true) {
      var message = '';
      index += 1;
      if (index == 2) {
        message =
            '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+910000000000*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
      } else if (index == 3) {
        message =
            '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+910000000000*
#04-+91${panel.mobileNumber3}*
#05-+91${panel.mobileNumber4}*
>
''';
      } else if (index == 4) {
        message =
            '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+910000000000*
#05-+91${panel.mobileNumber4}*
>
''';
      } else if (index == 5) {
        message =
            '''
< 1234 TEL NO
#01-+91${panel.adminMobileNumber}*
#02-+91${panel.mobileNumber1}*
#03-+91${panel.mobileNumber2}*
#04-+91${panel.mobileNumber3}*
#05-+910000000000*
>
''';
      } else if (index == 6) {
        message =
            '''
< 1234 TEL NO
#06-+910000000000*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
      } else if (index == 7) {
        message =
            '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+910000000000*
#08-+91${panel.mobileNumber7}*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
      } else if (index == 8) {
        message =
            '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+910000000000*
#09-+91${panel.mobileNumber8}*
#10-+91${panel.mobileNumber9}*
>
''';
      } else if (index == 9) {
        message =
            '''
< 1234 TEL NO
#06-+91${panel.mobileNumber5}*
#07-+91${panel.mobileNumber6}*
#08-+91${panel.mobileNumber7}*
#09-+910000000000*
#10-+91${panel.mobileNumber9}*
>
''';
      } else if (index == 10) {
        message =
            '''
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

      isSend = await trySendSms(
        context,
        device,
        smsPermission,
        panel.panelSimNumber,
        [message],
      );

      if (isSend!) {
        context.read<PanelCubit>().updatePanelData(
          userId: panel.userId,
          panelId: panel.pnlId,
          key: 'mobile_number$index',
          value: "0000000000",
        );
        SnackBarHelper.showSnackBar(context, 'Number deleted successfully!');
      } else {
        SnackBarHelper.showSnackBar(context, 'Cancelled');
      }
    } else {
      SnackBarHelper.showSnackBar(context, 'Failed to delete number.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = getNumbers(panelData);
    final existingNumbers = getExistingNumbers(panelData);

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if (state is UpdatePanelsSuccess) {
          debugPrint('delete number success');
          // _handleUpdateNumberSuccess(context, state.msg);
          setState(() {
            panelData = state.panelData;
          });
        } else if (state is UpdatePanelsFailure) {
          debugPrint('delete number failure');
          SnackBarHelper.showSnackBar(context, state.message);
        }
      },
      child: Scaffold(
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
                    widget.panelData.adminMobileNumber,
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
                          onPressed: () async {
                            final updatedPanel =
                                await showModalBottomSheet<PanelData>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppColors.lightGrey,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => AddNumberBottomSheet(
                                    panel: widget.panelData,
                                    index: index + 1,
                                    existingNumbers: existingNumbers,
                                  ),
                                );

                            if (updatedPanel != null) {
                              setState(() {
                                panelData = updatedPanel;
                              });
                            }
                          },
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
                          onPressed: isEmpty
                              ? null
                              : () => _sendDeleteMsg(
                                  context,
                                  widget.panelData,
                                  index + 1,
                                ),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isEmpty
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
      ),
    );
  }
}
