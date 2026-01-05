import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class PanelFilterDialog extends StatefulWidget {
  final String initialFilter;
  const PanelFilterDialog({super.key, this.initialFilter = 'ALL'});

  @override
  State<PanelFilterDialog> createState() => _PanelFilterDialogState();
}

class _PanelFilterDialogState extends State<PanelFilterDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Filter Here :",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                _radioTile("ALL"),
                _radioTile("FIRE PANEL"),
                _radioTile("FIRE DIALER"),
              ],
            ),
            const SizedBox(height: 15),
            CustomButton(
              buttonText: 'DONE',
              onPressed: () {
                Navigator.of(context).pop(_selected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioTile(String label) {
    return RadioListTile<String>(
      value: label,
      groupValue: _selected,
      activeColor: AppColors.colorPrimary,
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selected = value!;
        });
      },
    );
  }
}
