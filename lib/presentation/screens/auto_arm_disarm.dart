import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/presentation/dialog/confirmation_dialog.dart';
import 'package:fire_nex/presentation/viewModel/automation_view_model.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/presentation/widgets/app_bar.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../../data/database/app_database.dart';

class AutoArmDisarmPage extends StatefulWidget {
  const AutoArmDisarmPage({super.key, required this.panelSimNumber});

  final String panelSimNumber;

  @override
  State<AutoArmDisarmPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutoArmDisarmPage> {
  late final AutomationViewModel _automationViewModel;
  late final PanelViewModel _panelViewModel;
  String? adminCode;
  final List<AutomationTableData> _automations = [];
  bool isProcessing = false;
  bool isAutoArmEnabled = false;
  bool isAutoDisarmEnabled = false;
  bool isHolidayEnabled = false;

  @override
  void initState() {
    super.initState();
    _automationViewModel = context.read<AutomationViewModel>();
    _panelViewModel = context.read<PanelViewModel>();
    initPanelData();
    initUi();
  }

  Future<void> initUi() async {
    final automation = await _automationViewModel.getAutomationBySim(
      widget.panelSimNumber,
    );
    setState(() {
      _automations
        ..clear()
        ..addAll(automation);
      isAutoArmEnabled = automation.firstOrNull?.isArmToggled ?? false;
      isAutoDisarmEnabled = automation.firstOrNull?.isDisarmToggled ?? false;
      isHolidayEnabled = automation.firstOrNull?.isHolidayToggled ?? false;
    });
  }

  Future<void> initPanelData() async {
    final panel = await _panelViewModel.getPanelByPanelSimNumber(
      widget.panelSimNumber,
    );
    if (panel != null) {
      adminCode = panel.adminCode;
    }
  }

  Future<void> _updateArmDb(bool isEnabled) async {
    setState(() => isProcessing = true);
    try {
      await _automationViewModel.accessAutoArm(
        widget.panelSimNumber,
        isEnabled,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      showSnackBar('Auto Arm ${isEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      showSnackBar("Failed to update Auto Arm");
      setState(() => isAutoArmEnabled = !isEnabled);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _updateDisarmDb(bool isEnabled) async {
    setState(() => isProcessing = true);
    try {
      await _automationViewModel.accessAutoDisarm(
        widget.panelSimNumber,
        isEnabled,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      showSnackBar('Auto Disarm ${isEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      showSnackBar("Failed to update Auto Disarm");
      setState(() => isAutoDisarmEnabled = !isEnabled);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _resetArmDb() async {
    setState(() => isProcessing = true);

    final autoArmTime = _automations.first.autoArmTime;

    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to disable the Auto Arm?',
    );

    if (result != true) {
      setState(() => isProcessing = false);
      showSnackBar('Auto Arm disable cancelled');
      return;
    }

    try {
      await _automationViewModel.resetAutoArm(widget.panelSimNumber);

      if (autoArmTime != null && autoArmTime.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        sendSms(
          widget.panelSimNumber,
          "$adminCode AUTO ARM #$autoArmTime* DIS END",
        );
      }
      await initUi();
      showSnackBar('Auto Arm Disabled');
    } catch (e) {
      showSnackBar("Failed to update Auto Arm");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _resetDisarmDb() async {
    setState(() => isProcessing = true);

    final autoDisarmTime = _automations.first.autoDisarmTime;

    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to disable the Auto Disarm?',
    );

    if (result != true) {
      setState(() => isProcessing = false);
      showSnackBar('Auto Disarm disable cancelled');
      return;
    }

    try {
      await _automationViewModel.resetAutoDisarm(widget.panelSimNumber);

      if (autoDisarmTime != null && autoDisarmTime.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        sendSms(
          widget.panelSimNumber,
          "$adminCode AUTO ARM #$autoDisarmTime* DIS END",
        );
      }
      await initUi();
      showSnackBar('Auto Disarm Disabled');
    } catch (e) {
      showSnackBar("Failed to update Auto Disarm");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _updateHolidayDb(bool isEnabled) async {
    setState(() => isProcessing = true);
    try {
      await _automationViewModel.accessHoliday(
        widget.panelSimNumber,
        isEnabled,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      showSnackBar('Holiday ${isEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      showSnackBar("Failed to update Holiday");
      setState(() => isAutoDisarmEnabled = !isEnabled);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _resetHoliday() async {
    setState(() => isProcessing = true);

    final holiday = _automations.first.holidayTime;

    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to disable the Holiday?',
    );

    if (result != true) {
      setState(() => isProcessing = false);
      showSnackBar('Holiday disable cancelled');
      return;
    }

    try {
      await _automationViewModel.resetHoliday(widget.panelSimNumber);

      if (holiday != null && holiday.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        sendSms(
          widget.panelSimNumber,
          "$adminCode SET HOLIDAY #$holiday* DIS END",
        );
      }
      await initUi();

      showSnackBar('Holiday Disabled');
    } catch (e) {
      showSnackBar("Failed to update Holiday");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> showHolidayDayPickerDialog() async {
    final List<String> allDays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    String? selectedDay;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Holiday Day"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allDays.length,
                  itemBuilder: (context, index) {
                    final day = allDays[index];
                    final isSelected = day == selectedDay;

                    return ListTile(
                      title: Text(day),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      tileColor:
                          isSelected ? Colors.green.withOpacity(0.2) : null,
                      onTap: () {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (selectedDay != null) addHoliday(selectedDay!);
              },
              child: const Text("SAVE"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addHoliday(String time) async {
    if (adminCode == null) return showSnackBar("Admin code not available");

    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to add Holiday?',
    );

    if (result == true) {
      await _automationViewModel.addHolidayTime(widget.panelSimNumber, time);
      sendSms(
        widget.panelSimNumber,
        "$adminCode SET HOLIDAY #${time.substring(0, 3)}*  END",
      );
      final updated = await _automationViewModel.getAutomationBySim(
        widget.panelSimNumber,
      );
      setState(() {
        _automations
          ..clear()
          ..addAll(updated);
      });
      showSnackBar("Holiday added successfully");
    } else {
      showSnackBar("Holiday action cancelled");
    }
  }

  Future<void> addAutoArmTime(String time) async {
    if (adminCode == null) return showSnackBar("Admin code not available");

    final confirmed = await showConfirmationDialog(
      context: context,
      message: 'Do you want to add Auto Arm Time?',
    );

    if (confirmed == true) {
      await _automationViewModel.addAutoArmTime(widget.panelSimNumber, time);
      sendSms(
        widget.panelSimNumber,
        "$adminCode AUTO ARM #$time* ENA END",
      );
      final updated = await _automationViewModel.getAutomationBySim(
        widget.panelSimNumber,
      );
      setState(() {
        _automations
          ..clear()
          ..addAll(updated);
      });
      showSnackBar("Auto Arm added successfully");
    } else {
      // User cancelled the confirmation dialog
      showSnackBar("Auto Arm action cancelled");
      // Optionally, you can also pop the screen or perform other cleanup:
      // Navigator.of(context).pop();
    }
  }

  Future<void> addAutoDisarmTime(String time) async {
    if (adminCode == null) return showSnackBar("Admin code not available");

    await _automationViewModel.addAutoDisarmTime(widget.panelSimNumber, time);
    sendSms(
      widget.panelSimNumber,
      "$adminCode AUTO DISARM #$time*  END",
    );
    final updated = await _automationViewModel.getAutomationBySim(
      widget.panelSimNumber,
    );
    setState(() {
      _automations
        ..clear()
        ..addAll(updated);
    });
    showSnackBar("Auto Disarm added successfully");
  }

  void showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> showTimeOfDayPickerDialog({
    required String label,
    required Function(TimeOfDay) onConfirm,
  }) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: label,
    );
    if (pickedTime != null) {
      onConfirm(pickedTime);
    }
  }

  String formatTimeOfDayToHHMM(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour$minute';
  }

  String displayFormattedTime(String? hhmm) {
    if (hhmm == null || hhmm.length != 4) return 'Not Active';
    final hour = int.tryParse(hhmm.substring(0, 2)) ?? 0;
    final minute = int.tryParse(hhmm.substring(2, 4)) ?? 0;
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  String getFormattedLabelText(String? time, String prefix) {
    if (time == null || time.length != 4) return 'Not Set';
    final formatted = displayFormattedTime(time);
    return '$prefix $formatted';
  }

  String getAutoArmTimeDisplayText(String? time) {
    if (time == null || time.length != 4) {
      return 'Auto Arm time is not set';
    }

    final hour = int.tryParse(time.substring(0, 2)) ?? 0;
    final minute = int.tryParse(time.substring(2, 4)) ?? 0;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final formattedTime = timeOfDay.format(context);

    return 'The Auto Arm time is set as $formattedTime';
  }

  String getAutoDisarmTimeDisplayText(String? time) {
    if (time == null || time.length != 4) {
      return 'Auto Disarm time is not set';
    }

    final hour = int.tryParse(time.substring(0, 2)) ?? 0;
    final minute = int.tryParse(time.substring(2, 4)) ?? 0;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final formattedTime = timeOfDay.format(context);

    return 'The Auto Disarm time is set as $formattedTime';
  }

  String getHolidayDayDisplayText(String? day) {
    if (day == null || day.isEmpty) {
      return 'Holiday day is not set';
    }

    const dayNames = {
      'MONDAY': 'MONDAY',
      'TUESDAY': 'TUESDAY',
      'WEDNESDAY': 'WEDNESDAY',
      'THURSDAY': 'THURSDAY',
      'FRIDAY': 'FRIDAY',
      'SATURDAY': 'SATURDAY',
      'SUNDAY': 'SUNDAY',
    };

    final fullDayName = dayNames[day] ?? day;

    return 'Holiday is set on $fullDayName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(pageName: 'Automation Settings', isFilter: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.textGrey.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Current Status : ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorAccent,
                              ),
                            ),
                            Text(
                              isAutoArmEnabled ? "ENABLED" : "DISABLED",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isAutoArmEnabled,
                          onChanged: (val) async {
                            setState(() => isAutoArmEnabled = val);
                            if (val) {
                              await _updateArmDb(val);
                            } else {
                              await _resetArmDb();
                            }
                          },
                          activeColor: AppColors.colorPrimary,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: isAutoArmEnabled ? 1.0 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.5,
                          color: AppColors.colorPrimary,
                        ),
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Auto Arm",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.colorPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    isAutoArmEnabled
                                        ? () {
                                          showTimeOfDayPickerDialog(
                                            label: "Set Auto Arm Time",
                                            onConfirm: (pickedTime) {
                                              addAutoArmTime(
                                                formatTimeOfDayToHHMM(
                                                  pickedTime,
                                                ),
                                              );
                                            },
                                          );
                                        }
                                        : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.colorPrimary,
                                  side: const BorderSide(
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'EDIT/UPDATE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Icon(Icons.arrow_right, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            getAutoArmTimeDisplayText(
                              _automations.firstOrNull?.autoArmTime,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.colorAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            VerticalSpace(height: 20),

            Container(
              decoration: BoxDecoration(
                color: AppColors.textGrey.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Current Status : ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorAccent,
                              ),
                            ),
                            Text(
                              isAutoDisarmEnabled ? "ENABLED" : "DISABLED",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isAutoDisarmEnabled,
                          onChanged: (val) async {
                            setState(() => isAutoDisarmEnabled = val);
                            if (val) {
                              await _updateDisarmDb(val);
                            } else {
                              await _resetDisarmDb();
                            }
                          },
                          activeColor: AppColors.colorPrimary,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: isAutoDisarmEnabled ? 1.0 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.5,
                          color: AppColors.colorPrimary,
                        ),
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Auto Disarm",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.colorPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    isAutoDisarmEnabled
                                        ? () {
                                          showTimeOfDayPickerDialog(
                                            label: "Set Auto Disarm Time",
                                            onConfirm: (pickedTime) {
                                              addAutoArmTime(
                                                formatTimeOfDayToHHMM(
                                                  pickedTime,
                                                ),
                                              );
                                            },
                                          );
                                        }
                                        : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.colorPrimary,
                                  side: const BorderSide(
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'EDIT/UPDATE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Icon(Icons.arrow_right, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            getAutoDisarmTimeDisplayText(
                              _automations.firstOrNull?.autoDisarmTime,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.colorAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            VerticalSpace(height: 20),

            Container(
              decoration: BoxDecoration(
                color: AppColors.textGrey.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Current Status : ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorAccent,
                              ),
                            ),
                            Text(
                              isHolidayEnabled ? "ENABLED" : "DISABLED",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isHolidayEnabled,
                          onChanged: (val) async {
                            setState(() => isHolidayEnabled = val);
                            if (val) {
                              await _updateHolidayDb(val);
                            } else {
                              await _resetHoliday();
                            }
                          },
                          activeColor: AppColors.colorPrimary,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: isHolidayEnabled ? 1.0 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1.5,
                          color: AppColors.colorPrimary,
                        ),
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Holiday",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.colorPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    isHolidayEnabled
                                        ? () {
                                          showHolidayDayPickerDialog();
                                        }
                                        : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.colorPrimary,
                                  side: const BorderSide(
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'EDIT/UPDATE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Icon(Icons.arrow_right, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            getHolidayDayDisplayText(
                              _automations.firstOrNull?.holidayTime,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.colorAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
