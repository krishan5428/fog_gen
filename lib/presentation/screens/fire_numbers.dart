import 'package:fire_nex/utils/fire_list_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/data/pojo/fire_list.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../utils/auth_helper.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../bottom_sheet_dialog/change_number.dart';
import '../cubit/fire/fire_cubit.dart';
import '../dialog/confirmation_dialog.dart';
import '../dialog/progress.dart';
import '../dialog/progress_with_message.dart';
import '../widgets/app_bar.dart';
import '../widgets/item_numbers.dart';

class FireNumbersPage extends StatefulWidget {
  const FireNumbersPage({super.key, required this.panelData});

  final PanelData? panelData;

  @override
  State<FireNumbersPage> createState() => _FireNumbersPageState();
}

class _FireNumbersPageState extends State<FireNumbersPage> {
  int? userId;
  List<FireNumber> fireNumbersList = [];
  String? lastFireId;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    userId = await SharedPreferenceHelper.getUserId();
    if (userId != null) {
      context.read<FireCubit>().getFireNumbers(userId: userId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Responsive.fontSize(context);
    final spacingBwtView = Responsive.spacingBwtView(context);

    // final currentCount =
    //     fireNumbersList.isNotEmpty
    //         ? fireNumbersList.first.getValidFireNumbers().length
    //         : 0;
    //
    // final nextLabelNumber = currentCount + 1;
    // final isLimitReached = currentCount >= 10;

    return BlocListener<FireCubit, FireState>(
      listener: (context, state) {
        if (state is FireLoading) {
          ProgressDialog.show(context, message: 'Getting updated Fire Numbers');
        } else {
          ProgressDialog.dismiss(context);
        }

        if (state is GetFireSuccess) {
          final data = state.fireData;

          if (data.isNotEmpty) {
            final lastIntru = data.reduce(
              (a, b) => a.fireId > b.fireId ? a : b,
            );

            lastFireId = lastIntru.fireId.toString();

            setState(() {
              fireNumbersList = [lastIntru];
            });
          }
        }

        if (state is UpdateFireSuccess) {
          SnackBarHelper.showSnackBar(context, state.msg);
          context.read<FireCubit>().getFireNumbers(userId: userId.toString());
        }

        if (state is GetFireFailure) {
          debugPrint('GetFireFailure:$state.message');
          SnackBarHelper.showSnackBar(context, 'Something went error');
        }

        if (state is UpdateFireFailure) {
          debugPrint('UpdateFireFailure:$state.message');
          SnackBarHelper.showSnackBar(context, 'Something went error');
        }
      },

      child: Scaffold(
        appBar: const CustomAppBar(
          pageName: 'Fire Numbers',
          isFilter: false,
          isProfile: false,
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  fireNumbersList.isEmpty
                      ? Center(
                        child: Text(
                          'No Fire Numbers Found',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(spacingBwtView * 0.7),
                        itemCount: fireNumbersList.length,
                        itemBuilder: (context, index) {
                          final number = fireNumbersList[index];
                          final validNumbers = number.getValidFireNumbers();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children:
                                validNumbers.asMap().entries.map((entry) {
                                  final currentFireIndex = entry.key + 1;
                                  final fire = entry.value;
                                  final isFire1 = fire == number.fire1;

                                  return NumberCard(
                                    number: fire,
                                    onEdit:
                                        isFire1
                                            ? null
                                            : () async {
                                              final confirmed =
                                                  await showConfirmationDialog(
                                                    context: context,
                                                    message:
                                                        'Do you want to update Fire Number $currentFireIndex: $fire?',
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
                                                        count: currentFireIndex,
                                                        fireId: lastFireId!,
                                                        isAdd: false,
                                                        isUpdate: true,
                                                        initialNumber: fire,
                                                        existingNumbers:
                                                            fireNumbersList
                                                                .first
                                                                .getValidFireNumbers(),
                                                        panelData:
                                                            widget.panelData,
                                                      ),
                                                );
                                              }
                                            },
                                    onDelete:
                                        isFire1
                                            ? null
                                            : () async {
                                              final confirmed =
                                                  await showConfirmationDialog(
                                                    context: context,
                                                    message:
                                                        'Do you want to delete Fire Number $currentFireIndex: $fire?',
                                                    cancelText: 'No',
                                                    confirmText: 'Yes',
                                                  );

                                              if (confirmed == true) {
                                                final sms =
                                                    '${widget.panelData?.adminCode} TEL NO FIRE'
                                                    '#$currentFireIndex-REMOVE* END';

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
                                                      .read<FireCubit>()
                                                      .updateFireNo(
                                                        userId:
                                                            userId.toString(),
                                                        count: currentFireIndex,
                                                        fireId:
                                                            number.fireId
                                                                .toString(),
                                                        number: '0000000000',
                                                      );
                                                }
                                              }
                                            },
                                    showEdit: !isFire1,
                                    showDelete: !isFire1,
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
        //               : 'ADD Fire Number $nextLabelNumber',
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
        //                         fireId: lastFireId!,
        //                         isAdd: true,
        //                         isUpdate: false,
        //                         existingNumbers:
        //                             fireNumbersList.first.getValidFireNumbers(),
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
