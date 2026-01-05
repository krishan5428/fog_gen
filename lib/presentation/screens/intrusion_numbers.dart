import 'package:fog_gen_new/utils/intru_list_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/data/pojo/intru_list.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../utils/auth_helper.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../bottom_sheet_dialog/change_number.dart';
import '../cubit/intrusion/intru_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/app_bar.dart';
import '../widgets/item_numbers.dart';

class IntrusionNumbersPage extends StatefulWidget {
  const IntrusionNumbersPage({super.key, required this.panelData});

  final PanelData? panelData;

  @override
  State<IntrusionNumbersPage> createState() => _IntrusionNumbersPageState();
}

class _IntrusionNumbersPageState extends State<IntrusionNumbersPage> {
  int? userId;
  List<IntrusionNumber> intrusionNumberList = [];
  String? lastIntruId;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    userId = await SharedPreferenceHelper.getUserId();
    if (userId != null) {
      context.read<IntruCubit>().getIntru(userId: userId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    // final currentCount =
    //     intrusionNumberList.isNotEmpty
    //         ? intrusionNumberList.first.getValidIntrusionNumbers().length
    //         : 0;

    // final nextLabelNumber = currentCount + 1;
    // final isLimitReached = currentCount >= 10;

    return BlocListener<IntruCubit, IntruState>(
      listener: (context, state) {
        if (state is IntruLoading) {
          ProgressDialog.show(
            context,
            message: 'Getting updated Intrusion Numbers',
          );
        } else {
          ProgressDialog.dismiss(context);
        }

        if (state is GetIntruSuccess) {
          final data = state.intruData;

          if (data.isNotEmpty) {
            final lastIntru = data.reduce(
              (a, b) => a.intruId > b.intruId ? a : b,
            );

            lastIntruId = lastIntru.intruId.toString();

            setState(() {
              intrusionNumberList = [lastIntru];
            });
          }
        }

        if (state is UpdateIntruSuccess) {
          SnackBarHelper.showSnackBar(context, state.msg);
          context.read<IntruCubit>().getIntru(userId: userId.toString());
        }

        if (state is GetIntruFailure) {
          SnackBarHelper.showSnackBar(context, 'Something went error');
        }

        if (state is UpdateIntruFailure) {
          SnackBarHelper.showSnackBar(context, 'Something went error');
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(
          pageName: 'Intrusion Numbers',
          isFilter: false,
          isProfile: false,
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  intrusionNumberList.isEmpty
                      ? Center(
                        child: Text(
                          'No Intrusion Numbers Found',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(spacingBwtView * 0.7),
                        itemCount: intrusionNumberList.length,
                        itemBuilder: (context, index) {
                          final number = intrusionNumberList[index];
                          final validNumbers =
                              number.getValidIntrusionNumbers();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children:
                                validNumbers.asMap().entries.map((entry) {
                                  final currentIntruIndex = entry.key + 1;
                                  final intru = entry.value;
                                  final isIntru1 = intru == number.intru1;

                                  return NumberCard(
                                    number: intru,
                                    onEdit:
                                        isIntru1
                                            ? null
                                            : () async {
                                              final confirmed =
                                                  await showConfirmationDialog(
                                                    context: context,
                                                    message:
                                                        'Do you want to update Intrusion Number $currentIntruIndex: $intru?',
                                                    cancelText: 'No',
                                                    confirmText: 'Yes',
                                                  );
                                              if (confirmed == true) {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            16,
                                                          ),
                                                        ),
                                                  ),
                                                  builder:
                                                      (
                                                        _,
                                                      ) => ChangeNumberBottomSheet(
                                                        userId:
                                                            userId.toString(),
                                                        intruId:
                                                            number.intruId
                                                                .toString(),
                                                        count:
                                                            currentIntruIndex,
                                                        isAdd: false,
                                                        isUpdate: true,
                                                        initialNumber: intru,
                                                        existingNumbers:
                                                            intrusionNumberList
                                                                .first
                                                                .getValidIntrusionNumbers(),
                                                        panelData:
                                                            widget.panelData,
                                                      ),
                                                );
                                              }
                                            },
                                    onDelete:
                                        isIntru1
                                            ? null
                                            : () async {
                                              final confirmed =
                                                  await showConfirmationDialog(
                                                    context: context,
                                                    message:
                                                        'Do you want to delete Intrusion Number $currentIntruIndex: $intru?',
                                                    cancelText: 'No',
                                                    confirmText: 'Yes',
                                                  );

                                              if (confirmed == true) {
                                                final sms =
                                                    '${widget.panelData?.adminCode} TEL NO INTRUSION'
                                                    '#$currentIntruIndex-REMOVE* END';
                                                var result =
                                                    await ProgressDialogWithMessage.show(
                                                      context,
                                                      messages: [sms],
                                                      panelSimNumber:
                                                          widget
                                                              .panelData!
                                                              .panelSimNumber,
                                                    );
                                                if (result == true) {
                                                  context
                                                      .read<IntruCubit>()
                                                      .updateIntruNo(
                                                        userId:
                                                            userId.toString(),
                                                        count:
                                                            currentIntruIndex,
                                                        intruId:
                                                            number.intruId
                                                                .toString(),
                                                        number: '0000000000',
                                                      );
                                                }
                                              }
                                            },
                                    showEdit: !isIntru1,
                                    showDelete: !isIntru1,
                                  );
                                }).toList(),
                          );
                        },
                      ),
            ),
          ],
        ),
        // bottomNavigationBar: Padding(
        //   padding: EdgeInsets.only(bottom: spacingBwtView),
        //   child: SafeArea(
        //     minimum: EdgeInsets.fromLTRB(
        //       spacingBwtView * 2,
        //       0,
        //       spacingBwtView * 2,
        //       spacingBwtView,
        //     ),
        //     child: CustomButton(
        //       buttonText:
        //           isLimitReached
        //               ? 'Limit Reached'
        //               : 'ADD Intrusion Number $nextLabelNumber',
        //       icon: Icons.add,
        //       onPressed:
        //           isLimitReached
        //               ? null
        //               : () {
        //                 showModalBottomSheet(
        //                   context: context,
        //                   isScrollControlled: true,
        //                   shape: const RoundedRectangleBorder(
        //                     borderRadius: BorderRadius.vertical(
        //                       top: Radius.circular(16),
        //                     ),
        //                   ),
        //                   builder:
        //                       (_) => ChangeNumberBottomSheet(
        //                         userId: userId!,
        //                         count: nextLabelNumber,
        //                         intruId: lastIntruId!,
        //                         isAdd: true,
        //                         isUpdate: false,
        //                         existingNumbers:
        //                             intrusionNumberList.first
        //                                 .getValidIntrusionNumbers(),
        //                         panelData: widget.panelData,
        //                       ),
        //                 );
        //               },
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
