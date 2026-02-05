import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/presentation/screens/more_settings/telephone_no_settings_page.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:fog_gen_new/utils/responsive.dart';

import '../../widgets/app_bar.dart';
import '../../widgets/box_button.dart';
import 'more_settings_view_model.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key, required this.panelData});
  final PanelData panelData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoreSettingsViewModel(panelData: panelData),
      child: const _MoreSettingsContent(),
    );
  }
}

class _MoreSettingsContent extends StatelessWidget {
  const _MoreSettingsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MoreSettingsViewModel>();
    final panelData = vm.panelData;

    // Define Grid Options
    final List<GridOption> options = [
      GridOption(
        title: 'Add / Remove Numbers',
        icon: Icons.person_add_alt_1,
        onTap: () {
          CustomNavigation.instance.push(
            context: context,
            screen: TelephoneNoSettingsPage(panelData: panelData),
          );
        },
      ),
      GridOption(
        title: 'Panel ID',
        icon: Icons.device_hub,
        onTap: () => vm.fetchPanelID(context),
      ),
      GridOption(
        title: 'Local IP Settings',
        icon: Icons.settings_ethernet,
        onTap: () => vm.fetchLocalIPSettings(context),
      ),
      GridOption(
        title: 'Destination IP Settings',
        icon: Icons.public,
        onTap: () => _showDestinationSelectionDialog(context, vm),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(pageName: 'More Settings', isFilter: false,isDash: false,),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return GridBox(option: option);
          },
        ),
      ),
    );
  }

  void _showDestinationSelectionDialog(BuildContext context, MoreSettingsViewModel vm) {
    final fontSize = Responsive.fontSize(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            'Destination IP Settings',
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(
                title: 'CMS 1',
                onTap: () => vm.fetchDestinationIPSettings(
                  // Use main context for navigation/dialogs, not dialogContext
                  context,
                  packetArg: "001",
                  title: 'CMS 1',
                ),
              ),
              _buildOptionTile(
                title: 'CMS 2',
                onTap: () => vm.fetchDestinationIPSettings(
                  context,
                  packetArg: "002",
                  title: 'CMS 2',
                ),
              ),
              _buildOptionTile(
                title: 'PUSH SERVER',
                onTap: () => vm.fetchDestinationIPSettings(
                  context,
                  packetArg: "003",
                  title: 'PUSH SERVER',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => CustomNavigation.instance.pop(dialogContext),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.colorPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}