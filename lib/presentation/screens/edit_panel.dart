import 'package:fire_nex/constants/app_colors.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_bar.dart';
import '../widgets/custom_button.dart';

class EditPanelScreen extends StatefulWidget {
  const EditPanelScreen({super.key});

  @override
  State<EditPanelScreen> createState() => _EditPanelScreenState();
}

class _EditPanelScreenState extends State<EditPanelScreen> {
  late TextEditingController _siteNameController;
  late TextEditingController _simNumberController;

  @override
  void initState() {
    super.initState();
    final panel = context.read<PanelViewModel>().currentPanel;

    _siteNameController = TextEditingController(text: panel?.siteName ?? "");
    _simNumberController = TextEditingController(
      text: panel?.panelSimNumber ?? "",
    );
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _simNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PanelViewModel>(
      builder: (context, viewModel, child) {
        final panel = viewModel.currentPanel;

        if (panel == null) {
          return const Scaffold(body: Center(child: Text("No panel selected")));
        }

        return Scaffold(
          appBar: const CustomAppBar(pageName: 'Edit Panel', isFilter: false),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.litePrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info, color: AppColors.colorPrimary, size: 14),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          "Please fill out the form below with panel details...",
                          style: TextStyle(
                            color: AppColors.colorPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Form
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      // Site Name
                      TextField(
                        controller: _siteNameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Site Name",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.colorAccent,
                            ),
                          ),
                          labelStyle: TextStyle(color: AppColors.colorPrimary),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.colorPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Panel Sim Number
                      TextField(
                        controller: _simNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Panel Sim Number",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.colorAccent,
                            ),
                          ),
                          labelStyle: TextStyle(color: AppColors.colorPrimary),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.colorPrimary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: "BACK",
                              onPressed:
                                  () => CustomNavigation.instance.pop(context),
                              backgroundColor: AppColors.litePrimary,
                              foregroundColor: AppColors.colorPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              buttonText: "SAVE",
                              onPressed: () async {
                                final panel = viewModel.currentPanel;
                                if (panel != null) {
                                  final updated = await viewModel
                                      .updatePanelDetails(
                                        simNumber:
                                            _simNumberController.text.trim(),
                                        siteName:
                                            _siteNameController.text.trim(),
                                      );

                                  if (updated) {
                                    // refresh data
                                    await viewModel.refreshPanel(
                                      panel.panelSimNumber,
                                    );

                                    // show snackbar
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Panel updated successfully",
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );

                                      // wait a bit so user sees snackbar
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      CustomNavigation.instance.pop(context);
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
