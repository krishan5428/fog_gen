import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/presentation/screens/logs/logs_screen.dart';
import 'package:fog_gen_new/presentation/screens/main/panel_sr1/panel_sr1_fragment.dart';
import 'package:fog_gen_new/presentation/screens/main/panel_sr1/panel_sr1_viewmodel.dart';
import 'package:fog_gen_new/presentation/screens/main/widgets/input_controls_widget.dart';
import 'package:fog_gen_new/presentation/screens/main/widgets/output_controls_widget.dart';
import 'package:fog_gen_new/presentation/screens/panel_list/panel_list.dart';
import 'package:fog_gen_new/utils/navigation.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../../constants/app_colors.dart';
import '../../../core/responses/socket_repository.dart';
import '../../widgets/app_bar.dart';
import 'main_viewmodel.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.panelData});
  final PanelData panelData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          MainViewModel(panel: panelData, socketRepository: SocketRepository()),
      child: _MainView(panelData: panelData),
    );
  }
}

class _MainView extends StatefulWidget {
  const _MainView({required this.panelData});
  final PanelData panelData;

  @override
  State<_MainView> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  final log = Logger();
  PanelSR1ViewModel? _panelSR1ViewModel;
  Timer? _inactivityTimer;
  Timer? _warningTimer;
  late MainViewModel mainViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mainViewModel = Provider.of<MainViewModel>(context, listen: false);
      mainViewModel.addListener(_handleMainViewModelEvents);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      final viewModel = mainViewModel;
      viewModel.removeListener(_handleMainViewModelEvents);
    }
    _panelSR1ViewModel?.removeListener(_handlePanelSR1ViewModelEvents);
    _panelSR1ViewModel?.dispose();
    super.dispose();
  }

  void _showToast({
    required BuildContext context,
    required ToastificationType type,
    required String title,
    required String description,
    Alignment alignment = Alignment.center,
    Color? primaryColor,
    IconData? icon,
  }) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: alignment,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      description: Text(
        description,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w400,
        ),
      ),
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: false,
      primaryColor: primaryColor,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
    );
  }

  // ---------------- Event Handlers ----------------
  void _handleMainViewModelEvents() {
    if (!mounted) return;
    final viewModel = mainViewModel;

    if (viewModel.panelSR1ViewModel != _panelSR1ViewModel) {
      _panelSR1ViewModel?.removeListener(_handlePanelSR1ViewModelEvents);
      _panelSR1ViewModel = viewModel.panelSR1ViewModel;
      _panelSR1ViewModel?.addListener(_handlePanelSR1ViewModelEvents);
    }

    if (viewModel.event == MainViewEvent.none) return;

    log.d("Handling Main UI Event: ${viewModel.event.name}");

    switch (viewModel.event) {
      case MainViewEvent.showConnectionFailedToast:
        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'Connection Failed',
          description:
              'Could not connect to the panel. Please check the network and try again.',
        );
        break;
      case MainViewEvent.dismissInactivityDialog:
        if (viewModel.isConnected) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
        break;
      case MainViewEvent.showInactivityWarningDialog:
        _showInactivityWarningDialog();
        break;
      case MainViewEvent.showAlreadyConnectedDialog:
        _showAlreadyConnectedDialog();
        break;
      case MainViewEvent.showDisconnectedToast:
        _showToast(
          context: context,
          type: ToastificationType.warning,
          title: 'Disconnected',
          description: 'The device has been disconnected.',
        );
        break;
      case MainViewEvent.showNoSiteSelectedToast:
        _showToast(
          context: context,
          type: ToastificationType.info,
          title: 'No Selection',
          description: 'Please select a panel to connect.',
        );
        break;

      case MainViewEvent.showSounderOffSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.info,
          title: 'SOUNDER SILENCED',
          description: 'The sounder has been turned off.',
          alignment: Alignment.center,
          primaryColor: AppColors.colorAccent,
          icon: Icons.volume_off,
        );
        break;

      case MainViewEvent.showCommandFailedToast:
        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'Command Failed',
          description:
              'The panel did not respond as expected. Please try again.',
          alignment: Alignment.center,
        );
        break;
      default:
        break;
    }
    viewModel.resetEvent();

    _handleConnectionStateChange();
  }

  void _showAlreadyConnectedDialog() async {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.lightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Connection Status",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "This panel appears to be already connected.",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: AppColors.colorPrimary),
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text("Force Disconnect"),
                        onPressed: () {
                          Provider.of<MainViewModel>(
                            parentContext,
                            listen: false,
                          ).forceDisconnectAndAllowReconnect();

                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePanelSR1ViewModelEvents() {
    if (!mounted) return;
    if (_panelSR1ViewModel == null) return;
    final event = _panelSR1ViewModel!.event;
    if (event == PanelSR1ViewEvent.none) return;

    log.d("Handling Panel SR1 UI Event: ${event.name}");

    switch (event) {
      case PanelSR1ViewEvent.showEvacuatePulseSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'EVACUATE ACTIVATED',
          description: 'Evacuation pulse command sent.',
          alignment: Alignment.center,
          primaryColor: const Color(0xFFA42E2F),
          icon: Icons.local_fire_department,
        );
        break;
      case PanelSR1ViewEvent.showConnectionTimeout:
        Provider.of<MainViewModel>(context, listen: false).disconnect();

        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'Connection Lost',
          description:
              'No response from panel for over 1 minute. Please check network or power.',
          alignment: Alignment.center,
          primaryColor: AppColors.colorAccent,
          icon: Icons.wifi_off,
        );
        break;

      case PanelSR1ViewEvent.showFoggerTriggerSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.success,
          title: 'FOGGER TRIGGERED',
          description: 'Fogger pulse command sent successfully.',
          alignment: Alignment.center,
          primaryColor: Colors.orange.shade800,
          icon: Icons.flare,
        );
        break;

      case PanelSR1ViewEvent.showAlarmResetSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.success,
          title: 'ALARM RESET',
          description: 'All alarms have been reset.',
          alignment: Alignment.center,
          primaryColor: AppColors.connectionGreen,
          icon: Icons.check_circle,
        );
        break;

      case PanelSR1ViewEvent.showSounderToggleSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.warning,
          title: 'SOUNDER ACTIVATED',
          description: 'The sounder has been turned on.',
          alignment: Alignment.center,
          primaryColor: AppColors.greyDark,
          icon: Icons.volume_up,
        );
        break;
      case PanelSR1ViewEvent.showSounderOffSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.info,
          title: 'SOUNDER SILENCED',
          description: 'The sounder has been turned off.',
          alignment: Alignment.center,
          primaryColor: AppColors.colorAccent,
          icon: Icons.volume_off,
        );
        break;
      case PanelSR1ViewEvent.showZoneToggleSuccessToast:
        final data = _panelSR1ViewModel!.eventData;
        if (data != null) {
          final zone = data['zoneNumber'];
          final status = data['enabled'] ? "ENABLED" : "DISABLED";
          _showToast(
            context: context,
            type: ToastificationType.info,
            title: 'Zone Status Updated',
            description: zone == 2
                ? 'Fogger (Zone 2) has been $status.'
                : 'Fire Zone $zone has been $status.',
            alignment: Alignment.center,
            primaryColor: AppColors.greyDark,
            icon: Icons.sensors,
          );
        }
        break;
      case PanelSR1ViewEvent.showAdminStatusUpdatedToast:
        final data = _panelSR1ViewModel!.eventData;
        final bool isActivated = data?['activated'] ?? false;

        _showToast(
          context: context,
          type: isActivated
              ? ToastificationType.success
              : ToastificationType.warning,
          title: isActivated ? 'Panel Activated' : 'Panel Deactivated',
          description: isActivated
              ? 'The panel has been activated.'
              : 'The panel has been deactivated.',
          alignment: Alignment.center,
          primaryColor: isActivated
              ? AppColors.connectionGreen
              : Colors.orange.shade800,
          icon: isActivated ? Icons.security : Icons.lock_open,
        );
        break;
      case PanelSR1ViewEvent.showDateTimeSyncSuccessToast:
        _showToast(
          context: context,
          type: ToastificationType.success,
          title: 'Date & Time Synced',
          description: 'Panel clock is now synced with your device.',
          alignment: Alignment.center,
          primaryColor: Colors.teal,
        );
        break;
      case PanelSR1ViewEvent.showCommandFailedToast:
        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'Command Failed',
          description:
              'The panel did not respond as expected. Please try again.',
          alignment: Alignment.center,
        );
        break;
      case PanelSR1ViewEvent.showFoggerArmedToast:
        _showToast(
          context: context,
          type: ToastificationType.success,
          title: 'Fogger Activated',
          description: 'The fogger system is now activated.',
          alignment: Alignment.center,
          primaryColor: AppColors.connectionGreen,
          icon: Icons.shield,
        );
        break;
      case PanelSR1ViewEvent.showFoggerDisarmedToast:
        _showToast(
          context: context,
          type: ToastificationType.error,
          title: 'Fogger Deactivated',
          description: 'The fogger system is now deactivated.',
          alignment: Alignment.center,
          primaryColor: AppColors.colorAccent,
          icon: Icons.shield_outlined,
        );
        break;
      case PanelSR1ViewEvent.showExhaustFanOnToast:
        _showToast(
          context: context,
          type: ToastificationType.warning,
          title: 'Exhaust Fan ON',
          description: 'The exhaust fan has been activated.',
          alignment: Alignment.center,
          primaryColor: AppColors.connectionGreen,
          icon: Icons.air,
        );
        break;
      case PanelSR1ViewEvent.showExhaustFanOffToast:
        _showToast(
          context: context,
          type: ToastificationType.info,
          title: 'Exhaust Fan OFF',
          description: 'The exhaust fan has been deactivated.',
          alignment: Alignment.center,
          primaryColor: AppColors.greyDark,
          icon: Icons.air_outlined,
        );
        break;
      case PanelSR1ViewEvent.showFoggerNotActiveToast:
        _showToast(
          context: context,
          type: ToastificationType.warning,
          title: 'System Deactivated',
          description: 'Please activate the panel system to use this feature.',
          alignment: Alignment.center,
          primaryColor: Colors.orange.shade800,
          icon: Icons.lock_outline,
        );
        break;
      case PanelSR1ViewEvent.showInputPulseSuccessToast:
        final data = _panelSR1ViewModel!.eventData;
        if (data != null) {
          final int inputNumber = data['inputNumber'];
          String title = "Input $inputNumber";
          IconData icon = Icons.input;
          Color color = AppColors.greyDark;

          if (inputNumber == 1) {
            title = "Panic Alarm";
            icon = Icons.crisis_alert;
            color = AppColors.colorAccent;
          } else if (inputNumber == 2) {
            title = "Fogger Status";
            icon = Icons.shield;
            color = AppColors.greyDark;
          } else if (inputNumber == 3) {
            title = "Low Fluid Reset";
            icon = Icons.invert_colors_on;
            color = AppColors.colorPrimary;
          } else if (inputNumber == 4) {
            title = "System Error Reset";
            icon = Icons.error;
            color = AppColors.colorPrimary;
          }

          _showToast(
            context: context,
            type: ToastificationType.info,
            title: '$title Pulsed',
            description: 'Pulse command sent successfully.',
            alignment: Alignment.center,
            primaryColor: color,
            icon: icon,
          );
        }
        break;
      default:
        break;
    }
    _panelSR1ViewModel!.resetEvent();
  }

  void _handleConnectionStateChange() {
    if (!mounted) return;
    final viewModel = mainViewModel;

    if (viewModel.isConnected) {
      _resetInactivityTimer();
    } else {
      _inactivityTimer?.cancel();
      _warningTimer?.cancel();
    }
  }

  void _resetInactivityTimer() {
    final viewModel = mainViewModel;

    if (!viewModel.isConnected) return;

    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    _inactivityTimer = Timer(
      const Duration(minutes: 3),
      _showInactivityWarningDialog,
    );
  }

  void _showInactivityWarningDialog() {
    if (!mounted) return;

    final viewModel = mainViewModel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.lightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Session Timeout",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You were inactive for 3 minutes.\n\n"
                  "You will be disconnected in 1 minute unless you stay connected.",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: AppColors.colorPrimary),
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text("Stay Connected"),
                        onPressed: () {
                          Navigator.pop(ctx);
                          viewModel.stayConnected();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainViewModel>();

    return WillPopScope(
      onWillPop: () async {
        final vm = Provider.of<MainViewModel>(context, listen: false);

        if (viewModel.isConnected) {
          vm.disconnect();
          vm.socketRepository.stopAllActivity();
        }

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        CustomNavigation.instance.pushReplace(
          context: context,
          screen: PanelListPage(),
        );

        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Provider.of<MainViewModel>(
            context,
            listen: false,
          ).onUserInteraction();
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: CustomAppBar(
            pageName: 'Dashboard',
            isFilter: false,
            isDash: false,
            isProfile: false,
            onBack: () {
              final vm = Provider.of<MainViewModel>(context, listen: false);
              vm.disconnect();

              CustomNavigation.instance.pushReplace(
                context: context,
                screen: PanelListPage(),
              );
            },
          ),
          body: Column(
            children: [
              Expanded(child: _buildMainContentWrapper(viewModel, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitializingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.colorPrimary),
          SizedBox(height: 24),
          Text(
            'Initializing Panel...',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fetching latest status and controls.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentWrapper(
    MainViewModel viewModel,
    BuildContext context,
  ) {
    if (viewModel.isConnected && viewModel.isInitializing) {
      return _buildInitializingState();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = _buildFullContent(viewModel, context);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildFullContent(MainViewModel viewModel, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildControlPanel(viewModel),
            _buildFragmentContainer(viewModel),
          ],
        ),
        viewModel.isConnected
            ? _buildControlCentre(viewModel, context)
            : _buildDisconnectedControlCentre(),
      ],
    );
  }

  Widget _buildFragmentContainer(MainViewModel viewModel) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: viewModel.isConnected
          ? _buildPanelFragment(viewModel)
          : _buildDisconnectedState(),
    );
  }

  Widget _buildPanelFragment(MainViewModel viewModel) {
    return ChangeNotifierProvider.value(
      value: viewModel.panelSR1ViewModel!,
      child: PanelSR1Fragment(isUserEvent: viewModel.isUserEvent),
    );
  }

  Widget _buildCard({Key? key, required Widget child}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDisconnectedState() => Padding(
    padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
    child: _buildCard(
      key: const ValueKey('disconnected'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Panel Disconnected',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a panel and press CONNECT to see its status.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildControlPanel(MainViewModel viewModel) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(left: 7, right: 7, top: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.isConnected ? "Selected Panel" : "Select Panel",
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildPanelSelector(viewModel),
              const SizedBox(height: 12),
              _buildConnectionStatus(viewModel),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: _buildButtonPanel(viewModel)),
      ],
    ),
  );

  Widget _buildPanelSelector(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: AppColors.colorAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        viewModel.panel.siteName,
        style: TextStyle(
          color: AppColors.colorPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Widget _buildButtonPanel(MainViewModel viewModel) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _buildActionButtons(viewModel),
    const SizedBox(height: 10),
    OutlinedButton.icon(
      icon: const Icon(Icons.volume_off, size: 16),
      label: const Text('SOUNDER OFF', style: TextStyle(fontSize: 12)),
      onPressed: () {
        HapticFeedback.lightImpact();
        viewModel.sendSounderOffAckCommand();
      },
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: AppColors.greyDark,
        side: const BorderSide(color: AppColors.greyDark, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ],
);

Widget _buildActionButtons(MainViewModel viewModel) {
  return SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: viewModel.isConnecting || viewModel.isForceCooldownActive
          ? null
          : () {
              if (viewModel.isConnected) {
                viewModel.disconnect();
                viewModel.socketRepository.stopAllActivity();
              } else {
                viewModel.connect();
              }
            },
      icon: viewModel.isConnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(viewModel.isConnected ? Icons.link_off : Icons.link),
      label: Text(
        viewModel.isForceCooldownActive
            ? "WAITING..."
            : viewModel.isConnected
            ? "DISCONNECT"
            : "CONNECT",
        style: const TextStyle(fontSize: 12),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.colorPrimary,
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: const StadiumBorder(),
      ),
    ),
  );
}

Widget _buildConnectionStatus(MainViewModel viewModel) {
  final statusColor = viewModel.isConnected
      ? AppColors.connectionGreen
      : AppColors.red.withOpacity(0.5);

  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor,
          boxShadow: [
            BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8.0),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(
        viewModel.isConnected ? "CONNECTED" : "DISCONNECTED",
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          color: statusColor,
        ),
      ),
    ],
  );
}

Widget _buildControlCentre(MainViewModel viewModel, BuildContext context) {
  // Using .value ensures we use the existing connected VM, not a new disconnected one
  return ChangeNotifierProvider.value(
    value: viewModel.panelSR1ViewModel!,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputControlsWidget(),
        OutputControlsWidget(),
        _buildButtons(context, viewModel, viewModel.panel),
      ],
    ),
  );
}

Widget _buildButtons(
  BuildContext context,
  MainViewModel viewModel,
  PanelData panelData,
) {
  return Padding(
    padding: EdgeInsets.all(10),
    child: Row(
      children: [
        Expanded(
          child: _CommandButton(
            icon: Icons.history,
            label: "LOGS",
            onTap: () {
              CustomNavigation.instance.push(
                context: context,
                screen: LogsScreen(panelData: panelData),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _CommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CommandButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.colorPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 2,
      ),
    );
  }
}

Widget _buildDisconnectedControlCentre() {
  return SizedBox(
    height: 200,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_input_component_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Controls Unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to a panel to access the Control Centre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}
