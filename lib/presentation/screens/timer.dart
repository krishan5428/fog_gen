import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/silent_sms.dart';

import '../../constants/app_colors.dart';
import '../../data/database/app_database.dart';
import '../dialog/confirmation_dialog.dart';
import '../viewModel/timer_view_model.dart';
import '../widgets/app_bar.dart';
import '../widgets/timer_item.dart';
import '../widgets/vertical_gap.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.panelSimNumber});

  final String panelSimNumber;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late final TimerViewModel _timerViewModel;
  late final PanelViewModel _panelViewModel;
  String? adminCode;
  List<TimerTableData> _timers = [];

  @override
  void initState() {
    super.initState();
    _timerViewModel = context.read<TimerViewModel>();
    _panelViewModel = context.read<PanelViewModel>();
    initData();
  }

  Future<void> initData() async {
    final panel = await _panelViewModel.getPanelByPanelSimNumber(
      widget.panelSimNumber,
    );
    if (panel != null) {
      adminCode = panel.adminCode;
    }
    await loadTimers();
  }

  Future<void> loadTimers() async {
    final timers = await _timerViewModel.getTimersByPanelSim(
      widget.panelSimNumber,
    );

    print("Loaded timers: ${timers.map((e) => e.entryTime)}");
    setState(() {
      _timers = timers;
    });
  }

  Future<void> addEntryTime(String time) async {
    if (adminCode == null) {
      showSnackBar("Admin code not available");
      return;
    }

    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to set the Entry Time?',
    );

    if (result == true) {
      await _timerViewModel.addEntryTime(widget.panelSimNumber, time);
      await loadTimers();

      String message = "$adminCode ENTRY TIME #${time.padLeft(3, '0')}*  END";
      sendSms(widget.panelSimNumber, message);
      showSnackBar("Entry time added successfully");
    } else {
      showSnackBar("Entry time cancelled");
    }
  }

  Future<void> addExitTime(String time) async {
    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to set the Exit Time?',
    );

    if (result == true) {
      await _timerViewModel.addExitTime(widget.panelSimNumber, time);
      await loadTimers();

      String message = "$adminCode EXIT TIME #${time.padLeft(3, '0')}*  END";
      sendSms(widget.panelSimNumber, message);

      showSnackBar("Exit time added successfully");
    } else {
      showSnackBar("Exit time cancelled");
    }
  }

  Future<void> addSounderTime(String time) async {
    final result = await showConfirmationDialog(
      context: context,
      message: 'Do you want to set the Sounder Time?',
    );

    if (result == true) {
      await _timerViewModel.addSounderTime(widget.panelSimNumber, time);
      await loadTimers();

      String message = "$adminCode SOUNDER TIME #${time.padLeft(2, '0')}*  END";
      sendSms(widget.panelSimNumber, message);

      showSnackBar("Sounder time added successfully");
    } else {
      showSnackBar("Sounder time cancelled");
    }
  }

  void showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void showTimeInputDialog({
    required String label,
    required String rangeHint,
    required Function(String) onConfirm,
  }) {
    String inputValue = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            decoration: InputDecoration(labelText: rangeHint),
            keyboardType: TextInputType.number,
            onChanged: (value) => inputValue = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (inputValue.isNotEmpty && int.tryParse(inputValue) != null) {
                  onConfirm(inputValue);
                } else {
                  showSnackBar("Invalid input");
                }
              },
              child: const Text('YES'),
            ),
          ],
        );
      },
    );
  }

  String formatTime(dynamic time, String unit) {
    if (time == null || (time is String && time.trim().isEmpty)) {
      return 'Not Set';
    }
    return "$time $unit";
  }

  @override
  Widget build(BuildContext context) {
    final entryTime =
        (_timers.isNotEmpty)
            ? formatTime(_timers.first.entryTime, "sec.")
            : 'Not Set';
    final exitTime =
        (_timers.isNotEmpty)
            ? formatTime(_timers.first.exitTime, "sec.")
            : 'Not Set';
    final sounderTime =
        (_timers.isNotEmpty)
            ? formatTime(_timers.first.sounderTime, "min.")
            : 'Not Set';

    return Scaffold(
      appBar: CustomAppBar(pageName: 'Timer Settings', isFilter: false),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TimerItem(
              title: 'ENTRY TIME',
              entryTimeLabel: "Entry Time is ",
              entryTimeText: entryTime,
              onEditUpdate: () {
                showTimeInputDialog(
                  label: 'Entry Time',
                  rangeHint: '2 - 255 seconds',
                  onConfirm: addEntryTime,
                );
              },
            ),
            const VerticalSpace(),
            TimerItem(
              title: 'EXIT TIME',
              entryTimeLabel: "Exit Time is ",
              entryTimeText: exitTime,
              onEditUpdate: () {
                showTimeInputDialog(
                  label: 'Exit Time',
                  rangeHint: '2 - 255 seconds',
                  onConfirm: addExitTime,
                );
              },
            ),
            const VerticalSpace(),
            TimerItem(
              title: 'SOUNDER TIME',
              entryTimeLabel: "Sounder Time is ",
              entryTimeText: sounderTime,
              onEditUpdate: () {
                showTimeInputDialog(
                  label: 'Sounder Time',
                  rangeHint: '2 - 20 minutes',
                  onConfirm: addSounderTime,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
