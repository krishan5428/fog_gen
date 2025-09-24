import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/presentation/viewModel/intrusion_view_model.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/presentation/widgets/app_bar.dart';
import 'package:fire_nex/presentation/widgets/vertical_gap.dart';

import '../dialog/add_number.dart';
import '../widgets/custom_button.dart';

class IntrusionNumbersPage extends StatefulWidget {
  const IntrusionNumbersPage({super.key, required this.panelSimNumber});

  final String panelSimNumber;

  @override
  State<IntrusionNumbersPage> createState() => _IntrusionNumbersPageState();
}

class _IntrusionNumbersPageState extends State<IntrusionNumbersPage> {
  String? adminNumber;
  late Future<List<IntrusionNumber>> _intrusionNumbersFuture;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  void _loadNumbers() {
    _intrusionNumbersFuture = context
        .read<IntrusionViewModel>()
        .getIntrusionNumbersByPanelSimNumber(widget.panelSimNumber);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<IntrusionViewModel>();

    return Scaffold(
      appBar: CustomAppBar(pageName: 'Intrusion Numbers', isFilter: false),
      body: Column(
        children: [
          const VerticalSpace(height: 10),
          FutureBuilder<PanelData?>(
            future: context.read<PanelViewModel>().getPanelByPanelSimNumber(
              widget.panelSimNumber,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final panel = snapshot.data!;
              adminNumber = panel.adminMobileNumber;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    panel.adminMobileNumber,
                    style: const TextStyle(
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<IntrusionNumber>>(
              future: _intrusionNumbersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final numbers = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: numbers.length + (numbers.length >= 9 ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == numbers.length && numbers.length < 9) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CustomButton(
                          buttonText: 'ADD New Intrusion Number',
                          icon: Icons.add,
                          onPressed:
                              adminNumber == null
                                  ? null
                                  : () async {
                                    final success = await showAddNumberDialog(
                                      context,
                                      widget.panelSimNumber,
                                      adminNumber!,
                                      viewModel,
                                    );
                                    if (success == true) {
                                      _loadNumbers();
                                      setState(() {});
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'New Intrusion Number Added successfully',
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                        ),
                      );
                    }

                    final number = numbers[index];
                    return SizedBox(
                      child: ListTile(
                        // leading: const Icon(
                        //   Icons.phone_android,
                        //   color: AppColors.colorPrimary,
                        // ),
                        title: Text(
                          number.intrusionNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.colorPrimary,
                          ),
                          onPressed: () async {
                            // TODO: Add deletion logic
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
