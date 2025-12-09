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
      create: (context) => PanelCubit(PanelRepositoryImpl()),
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
  void initState() {
    super.initState();
    getUserid();
  }

  List<String> _extractSiteNames(List<PanelData> panels) {
    return panels
        .map((panel) => panel.site.toString().trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _extractPanelSimNumbers(List<PanelData> panels) {
    return panels
        .map((panel) => panel.panelSimNumber.toString().trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> getUserid() async {
    userId = await SharedPreferenceHelper.getUserId();
    debugPrint('Got userId in panel list page: $userId');
    if (userId != null) {
      context.read<PanelCubit>().getPanel(userId: userId.toString());
    }
  }

  void _retryLoadingPanels() {
    if (userId != null) {
      context.read<PanelCubit>().getPanel(userId: userId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacingBwtView = Responsive.spacingBwtView(context);

    return BlocListener<PanelCubit, PanelState>(
      listener: (context, state) {
        if (state is PanelLoading) {
          loadFailed = false;
          ProgressDialog.show(context, message: 'Getting updated Panel Data');
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
          setState(() {
            loadFailed = true;
          });
          SnackBarHelper.showSnackBar(
            context,
            'Something went wrong! Please try again.',
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        drawer: AppDrawer(),
        appBar: CustomAppBar(
          pageName: 'Home',
          isFilter: true,
          isDash: true,
          isProfile: false,
          onFilterTap: _showPanelFilterDialog,
        ),
        body: Builder(
          builder: (_) {
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
                      width: spacingBwtView * 30,
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
                  width: spacingBwtView * 25,
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
                vertical: spacingBwtView * 0.7,
                horizontal: spacingBwtView,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...filteredPanelList.map(
                    (panel) => PanelCard(panelData: panel),
                  ),
                  VerticalSpace(height: spacingBwtView),
                  Center(
                    child: SizedBox(
                      width: spacingBwtView * 25,
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
          },
        ),
      ),
    );
  }

  void _showPanelTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const PanelTypeDialog();
      },
    );
  }

  void _showPanelFilterDialog() async {
    final selectedFilter = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return PanelFilterDialog(initialFilter: currentFilterType);
      },
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
      return (panel.panelType.toUpperCase()) == filterType.toUpperCase();
    }).toList();
  }
}
