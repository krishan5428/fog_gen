import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fog_gen_new/presentation/screens/main/panel_sr1/panel_sr1_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../../constants/app_colors.dart';

class LayoutConfig {
  static const double spaceBetweenTimerAndDivider = 8.0;
  static const double spaceBetweenDividerAndContent = 12.0;
  static const double headerVerticalDividerHeight = 74.0;
  static const double actionButtonWidth = 180.0;
}

class PanelSR1Fragment extends StatelessWidget {
  final bool isUserEvent;
  const PanelSR1Fragment({super.key, this.isUserEvent = false});

  @override
  Widget build(BuildContext context) {
    return _PanelSR1View(isUserEvent: isUserEvent);
  }
}

class _PanelSR1View extends StatefulWidget {
  final bool isUserEvent;
  const _PanelSR1View({required this.isUserEvent});

  @override
  State<_PanelSR1View> createState() => _PanelSR1ViewState();
}

class _PanelSR1ViewState extends State<_PanelSR1View> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PanelSR1ViewModel>(
        context,
        listen: false,
      ).addListener(_handleViewModelEvents);
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<PanelSR1ViewModel>(
        context,
        listen: false,
      ).removeListener(_handleViewModelEvents);
    } catch (e) {
      // ViewModelProvider not found, likely already disposed.
    }
    super.dispose();
  }

  void _handleViewModelEvents() {
    if (!mounted) return;
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          backgroundColor: AppColors.white,
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.black,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.colorPrimary,
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PanelSR1ViewModel>();
    final signalData = _getSignalData(viewModel.signalStrengthLevel);

    return Container(
      margin: const EdgeInsets.only(left: 7, right: 7, top: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(viewModel),
          const Divider(height: 16, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Signal Strength",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(signalData.icon, color: signalData.color, size: 30),
                    const SizedBox(height: 4),
                    Text(
                      signalData.text,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: signalData.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: LayoutConfig.headerVerticalDividerHeight,
                width: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: LayoutConfig.spaceBetweenTimerAndDivider),

              // Expanded(
              //   flex: 2,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.center,
              //     children: [
              //       const Padding(
              //         padding: EdgeInsets.only(bottom: 6.0),
              //         child: Text(
              //           'Quick Controls',
              //           style: TextStyle(
              //             fontFamily: 'Montserrat',
              //             fontSize: 15,
              //             fontWeight: FontWeight.w600,
              //             color: AppColors.colorPrimary,
              //           ),
              //         ),
              //       ),
              //       _buildActionButtons(viewModel),
              //     ],
              //   ),
              // ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: LayoutConfig.spaceBetweenDividerAndContent,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Text(
                              widget.isUserEvent
                                  ? "User Status"
                                  : "Fog Machine Status",
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          widget.isUserEvent
                              ? SizedBox(
                                  width: 120.0,
                                  height: 36.0,
                                  child: Text(
                                    viewModel.userStatus,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: viewModel.userStatus == "ARMED"
                                          ? AppColors.connectionGreen
                                          : Colors.redAccent.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : _buildFoggerStatusToggle(viewModel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PanelSR1ViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDateTime(viewModel),
        // const SizedBox(width: LayoutConfig.spaceBetweenTimerAndDivider),
        // Container(
        //   height: LayoutConfig.headerVerticalDividerHeight,
        //   width: 1,
        //   color: Colors.grey.shade300,
        // ),
        // Expanded(
        //   child: Stack(
        //     children: [
        //       Padding(
        //         padding: const EdgeInsets.only(
        //           left: LayoutConfig.spaceBetweenDividerAndContent,
        //         ),
        //         child: Column(
        //           children: [
        //             Padding(
        //               padding: const EdgeInsets.only(bottom: 15.0),
        //               child: Text(
        //                 widget.isUserEvent
        //                     ? "User Status"
        //                     : "Fog Machine Status",
        //                 style: const TextStyle(
        //                   fontFamily: 'Montserrat',
        //                   fontWeight: FontWeight.w600,
        //                   fontSize: 13,
        //                   color: Colors.black,
        //                 ),
        //               ),
        //             ),
        //             widget.isUserEvent
        //                 ? SizedBox(
        //                   width: 120.0,
        //                   height: 36.0,
        //                   child: Text(
        //                     viewModel.userStatus,
        //                     style: TextStyle(
        //                       fontFamily: 'Montserrat',
        //                       color:
        //                           viewModel.userStatus == "ARMED"
        //                               ? AppColors.connectionGreen
        //                               : Colors.redAccent.shade700,
        //                       fontWeight: FontWeight.bold,
        //                       fontSize: 16,
        //                     ),
        //                   ),
        //                 )
        //                 : _buildFoggerStatusToggle(viewModel),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildFoggerStatusToggle(PanelSR1ViewModel viewModel) {
    if (viewModel.isPanelStatusLoading) {
      return Container(
        width: 120.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.colorPrimary,
            ),
          ),
        ),
      );
    }

    final bool isFoggerOn = viewModel.outputAuto1Status == "ON";

    return FlutterSwitch(
      width: 125.0,
      height: 35.0,
      valueFontSize: 11.0,
      toggleSize: 24.0,
      value: isFoggerOn,
      borderRadius: 40.0,
      padding: 4.0,
      showOnOff: true,
      activeText: "ACTIVATED",
      inactiveText: "DEACTIVATED",
      activeTextColor: Colors.white,
      inactiveTextColor: Colors.white,
      activeColor: AppColors.connectionGreen,
      onToggle: (val) {
        final action = val ? "ACTIVATE" : "DEACTIVATE";
        _showConfirmationDialog(
          context: context,
          title: "$action Fogger?",
          content: "Are you sure you want to $action the fogger?",
          onConfirm: () {
            HapticFeedback.lightImpact();
            viewModel.sendAutomationToggleCommand(1, val);
          },
        );
      },
    );
  }

  Widget _buildDateTime(PanelSR1ViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              viewModel.time,
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: AppColors.colorPrimary,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                children: [
                  Text(
                    "AM",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: viewModel.isAm
                          ? AppColors.colorPrimary
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    "PM",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: !viewModel.isAm
                          ? AppColors.colorPrimary
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              viewModel.date,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync, size: 12),
                label: const Text('SYNC', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _showConfirmationDialog(
                    context: context,
                    title: "Sync Date & Time?",
                    content:
                        "This will set the panel's time to your phone's time.",
                    onConfirm: () {
                      HapticFeedback.lightImpact();
                      viewModel.syncDateTime();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  backgroundColor: AppColors.greyDark,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  minimumSize: const Size(0, 28), // ensures compact fit
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _SignalDisplayData _getSignalData(int level) {
    switch (level) {
      case 0:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_off_outlined,
          color: Colors.grey.shade700,
          text: "No SIM",
        );
      case 1:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_alt_1_bar_rounded,
          color: Colors.redAccent.shade700,
          text: "Poor",
        );
      case 2:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_alt_2_bar_rounded,
          color: Colors.orange.shade700,
          text: "Fair",
        );
      case 3:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_alt_rounded,
          color: AppColors.connectionGreen,
          text: "Good",
        );
      case 4:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_alt_rounded,
          color: AppColors.connectionGreen,
          text: "Excellent",
        );
      default:
        return _SignalDisplayData(
          icon: Icons.signal_cellular_nodata_rounded,
          color: Colors.grey,
          text: "N/A",
        );
    }
  }
}

class _SystemErrorIndicator extends StatefulWidget {
  final PanelSR1ViewModel viewModel;
  const _SystemErrorIndicator({required this.viewModel});

  @override
  State<_SystemErrorIndicator> createState() => _SystemErrorIndicatorState();
}

class _SystemErrorIndicatorState extends State<_SystemErrorIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    // 1. Loading State
    if (viewModel.isPanelStatusLoading || viewModel.isZoneStatusLoading) {
      return Container(
        width: 120.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(50),
        ),
      );
    }

    final bool isActive = viewModel.isSystemErrorDetected;

    if (isActive) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.value = 1.0;
      }
    }

    final Color backgroundColor = isActive
        ? Colors.redAccent.shade700
        : AppColors.connectionGreen;

    final Color borderColor = isActive
        ? Colors.transparent
        : Colors.transparent;
    final Color textColor = isActive ? Colors.white : Colors.white;

    final String text = isActive ? "SYSTEM ERROR" : "SYSTEM NORMAL";

    return FadeTransition(
      opacity: isActive
          ? _animationController
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          border: isActive ? null : Border.all(color: borderColor, width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _SignalDisplayData {
  final IconData icon;
  final Color color;
  final String text;

  _SignalDisplayData({
    required this.icon,
    required this.color,
    required this.text,
  });
}
