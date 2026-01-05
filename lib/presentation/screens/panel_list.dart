import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_colors.dart';
import '../../core/data/pojo/panel_data.dart';
import '../../core/data/repo_impl/panel_repository_impl.dart';
import '../../utils/auth_helper.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../cubit/mappings/panel_sim_number_cubit.dart';
import '../cubit/mappings/site_cubit.dart';
import '../cubit/panel/panel_cubit.dart';
import '../dialog/panel_filter.dart';
import '../dialog/panel_type.dart';
import '../dialog/progress.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_button.dart';
import '../widgets/panel_item.dart';
import '../widgets/vertical_gap.dart';

class PanelListPage extends StatelessWidget {
  const PanelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PanelCubit(PanelRepositoryImpl()),
      child: const PanelListUI(),
    );
  }
}

class PanelListUI extends StatefulWidget {
  const PanelListUI({super.key});

  @override
  State<PanelListUI> createState() => PanelListState();
}

class PanelListState extends State<PanelListUI> {
  String currentFilterType = 'ALL';
  int? userId;
  List<PanelData> panelList = [];
  List<PanelData> filteredPanelList = [];
  List<String> siteNames = [];
  List<String> panelSimNumbers = [];
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    getUserid();
  }

  Future<void> getUserid() async {
    final panelCubit = context.read<PanelCubit>();

    final userId = await SharedPreferenceHelper.getUserId();

    if (!mounted || userId == null) return;

    panelCubit.getPanel(userId: userId.toString());
  }

  List<String> _extractSiteNames(List<PanelData> panels) {
    return panels
        .map((panel) => panel.site.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _extractPanelSimNumbers(List<PanelData> panels) {
    return panels
        .map((panel) => panel.panelSimNumber.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _retryLoadingPanels() {
    if (userId != null) {
      context.read<PanelCubit>().getPanel(userId: userId.toString());
    }
  }

  void updatePanelInList(PanelData updatedPanel) {
    final index = panelList.indexWhere(
      (p) => p.panelSimNumber == updatedPanel.panelSimNumber,
    );
    if (index != -1) {
      setState(() {
        panelList[index] = updatedPanel;
        filteredPanelList = _filterPanels(currentFilterType);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Responsive.spacingBwtView(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(), // prevent rebuild → no jitter
      appBar: CustomAppBar(
        pageName: 'Home',
        isFilter: true,
        isDash: true,
        isProfile: false,
        onFilterTap: _showPanelFilterDialog,
      ),
      body: BlocListener<PanelCubit, PanelState>(
        listener: (context, state) {
          if (state is PanelLoading) {
            loadFailed = false;
            ProgressDialog.show(
              context,
              message: 'Getting updated Panel Data ready',
            );
          } else {
            ProgressDialog.dismiss(context);
          }

          if (state is GetPanelsSuccess) {
            setState(() {
              panelList = state.panelsData;
              filteredPanelList = _filterPanels(currentFilterType);
              siteNames = _extractSiteNames(panelList);
              panelSimNumbers = _extractPanelSimNumbers(panelList);
              loadFailed = false;
            });

            context.read<SiteCubit>().setSites(siteNames);
            context.read<PanelSimNumberCubit>().setPanelSimNumbers(
              panelSimNumbers,
            );
          } else if (state is GetPanelsFailure) {
            setState(() => loadFailed = true);
            SnackBarHelper.showSnackBar(
              context,
              'Something went wrong! Please try again.',
            );
          }
        },
        child: _buildPanelContent(context, spacing),
      ),
    );
  }

  Widget _buildPanelContent(BuildContext context, double spacing) {
    if (loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load panel data.',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: spacing * 30,
              child: CustomButton(
                buttonText: 'RETRY LOADING',
                icon: Icons.refresh,
                onPressed: _retryLoadingPanels,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredPanelList.isEmpty) {
      return Center(
        child: SizedBox(
          width: spacing * 25,
          child: CustomButton(
            buttonText: 'ADD NEW PANEL',
            icon: Icons.add,
            onPressed: _showPanelTypeDialog,
            foregroundColor: AppColors.white,
            backgroundColor: AppColors.colorPrimary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: spacing * 0.7,
        horizontal: spacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...filteredPanelList.map((panel) => PanelCard(panelData: panel)),
          VerticalSpace(height: spacing),
          Center(
            child: SizedBox(
              width: spacing * 25,
              child: CustomButton(
                buttonText: 'ADD NEW PANEL',
                icon: Icons.add,
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.colorPrimary,
                onPressed: _showPanelTypeDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanelTypeDialog() {
    showDialog(context: context, builder: (_) => const PanelTypeDialog());
  }

  void _showPanelFilterDialog() async {
    final selectedFilter = await showDialog<String>(
      context: context,
      builder: (_) => PanelFilterDialog(initialFilter: currentFilterType),
    );

    if (selectedFilter != null) {
      setState(() {
        currentFilterType = selectedFilter;
        filteredPanelList = _filterPanels(currentFilterType);
      });
    }
  }

  List<PanelData> _filterPanels(String filterType) {
    if (filterType == 'ALL') return panelList;

    return panelList.where((panel) {
      return panel.panelType.toUpperCase() == filterType.toUpperCase();
    }).toList();
  }
}
