import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/responsive.dart';
import '../../../utils/snackbar_helper.dart';
import '../../cubit/panel/panel_cubit.dart';
import '../../dialog/panel_filter.dart';
import '../../dialog/panel_type.dart';
import '../../dialog/progress.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/panel_item.dart';
import '../../widgets/vertical_gap.dart';
import 'panel_list_view_model.dart';

class PanelListPage extends StatelessWidget {
  const PanelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Only inject the View Model.
    // PanelCubit will be found automatically from the global provider in main.dart.
    return ChangeNotifierProvider(
      create: (_) => PanelListViewModel(),
      child: const PanelListUI(),
    );
  }
}

class PanelListUI extends StatefulWidget {
  const PanelListUI({super.key});

  @override
  State<PanelListUI> createState() => _PanelListUIState();
}

class _PanelListUIState extends State<PanelListUI> {
  Completer<void>? _refreshCompleter;
  bool _isSwipeRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This uses the global PanelCubit found via context
      context.read<PanelListViewModel>().initialLoad(context);
    });
  }

  Future<void> _onRefresh() async {
    _refreshCompleter = Completer<void>();
    _isSwipeRefreshing = true;

    // Trigger the data fetch
    context.read<PanelListViewModel>().fetchPanels(context);

    // Keep spinner active until data returns
    return _refreshCompleter!.future;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Responsive.spacingBwtView(context);
    final viewModel = context.watch<PanelListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: const AppDrawer(),
      appBar: CustomAppBar(
        pageName: 'Home',
        isFilter: true,
        isDash: true,
        isProfile: false,
        onFilterTap: () => _showFilterDialog(context),
      ),
      // Listen to the global PanelCubit state changes
      body: BlocListener<PanelCubit, PanelState>(
        listener: (context, state) {
          final vm = context.read<PanelListViewModel>();

          if (state is PanelLoading) {
            vm.handleLoading();
            if (!_isSwipeRefreshing) {
              ProgressDialog.show(
                context,
                message: 'Getting updated Panel Data ready',
              );
            }
          } else {
            if (!_isSwipeRefreshing) {
              ProgressDialog.dismiss(context);
            }
          }

          if (state is GetPanelsSuccess) {
            vm.handleSuccess(context, state.panelsData);
            _completeRefresh();
          } else if (state is GetPanelsFailure) {
            vm.handleFailure();
            _completeRefresh();
            SnackBarHelper.showSnackBar(
              context,
              'Something went wrong! Please try again.',
            );
          }
        },
        child: _buildContent(context, viewModel, spacing),
      ),
    );
  }

  void _completeRefresh() {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete();
    }
    _refreshCompleter = null;
    _isSwipeRefreshing = false;
  }

  Widget _buildContent(
    BuildContext context,
    PanelListViewModel vm,
    double spacing,
  ) {
    // 1. Handle Failure
    if (vm.loadFailed) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
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
                      onPressed: () => vm.fetchPanels(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Handle Empty List
    if (vm.filteredPanelList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: SizedBox(
                width: spacing * 25,
                child: CustomButton(
                  buttonText: 'ADD NEW PANEL',
                  icon: Icons.add,
                  onPressed: () => _showPanelTypeDialog(context),
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.colorPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 3. Handle Main Content
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.colorPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          vertical: spacing * 0.7,
          horizontal: spacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...vm.filteredPanelList.map((panel) => PanelCard(panelData: panel)),
            VerticalSpace(height: spacing),
            Center(
              child: SizedBox(
                width: spacing * 25,
                child: CustomButton(
                  buttonText: 'ADD NEW PANEL',
                  icon: Icons.add,
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.colorPrimary,
                  onPressed: () => _showPanelTypeDialog(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPanelTypeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const PanelTypeDialog());
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final vm = context.read<PanelListViewModel>();

    final selectedFilter = await showDialog<String>(
      context: context,
      builder: (_) => PanelFilterDialog(initialFilter: vm.currentFilterType),
    );

    if (selectedFilter != null && context.mounted) {
      vm.setFilter(selectedFilter);
    }
  }
}
