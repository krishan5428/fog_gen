import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../constants/app_colors.dart';
import '../panel_sr1/panel_sr1_viewmodel.dart';

class InputControlsWidget extends StatelessWidget {
  const InputControlsWidget({super.key});

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
              color: AppColors.greyDark,
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
              style: TextButton.styleFrom(foregroundColor: AppColors.colorAccent),
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
    // Get the view model instance
    final viewModel = context.watch<PanelSR1ViewModel>();

    if (viewModel.inputStatuses.length < 4) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.18),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "System Status",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            Divider(height: 24),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    const buttonTextStyle = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontSize: 12,
    );

    const buttonSize = Size(180, 36);

    final ButtonStyle panicButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.colorAccent,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      textStyle: buttonTextStyle,
      minimumSize: buttonSize,
    );

    // Input 3 (Index 2): Low Fluid - Shows LOW only when ARM ALERT
    final bool isLowFluid = viewModel.inputStatuses[2] == "ALARM";

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(left: 7, right: 7, top: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "System Status",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
          Wrap(
            spacing: 10,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: [
              _buildControlItem(
                context,
                child: ElevatedButton(
                  style: panicButtonStyle,
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title: "Trigger Panic Alarm?",
                      content: "Are you sure you want to send a panic pulse?",
                      onConfirm: () {
                        HapticFeedback.lightImpact();
                        viewModel.sendInputPulseCommand(1);
                      },
                    );
                  },
                  child: const Text("PANIC ALARM"),
                ),
              ),
              _buildControlItem(
                context,
                child: _SystemErrorIndicator(viewModel: viewModel),
              ),
              _buildControlItem(
                context,
                child: _BlinkingStatusIndicator(
                  size: buttonSize,
                  isLowFluid: isLowFluid,
                ),
              ),
              _buildControlItem(
                context,
                child: _MainsStatusIndicator(viewModel: viewModel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlItem(BuildContext context, {required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 50) / 2;

    return SizedBox(
      width: itemWidth,
      height: 36,
      child: Align(
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _MainsStatusIndicator extends StatelessWidget {
  final PanelSR1ViewModel viewModel;
  const _MainsStatusIndicator({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isPanelStatusLoading || viewModel.isZoneStatusLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        height: 32.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(50),
        ),
      );
    }

    final bool isMainsOk = viewModel.isMainsOk;
    final Color color = isMainsOk
        ? AppColors.connectionGreen
        : Colors.redAccent.shade700;
    final String text = isMainsOk ? "ON" : "OFF";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      height: 32.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        'MAINS $text',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
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

    // 2. Determine Active State
    final bool isActive = viewModel.isSystemErrorDetected;

    // 3. Handle Animation
    if (isActive) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.value = 1.0; // Reset opacity to full
      }
    }

    // 4. Define Styles
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
        height: 36,
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
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: 12,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _BlinkingStatusIndicator extends StatefulWidget {
  final Size size;
  final bool isLowFluid;

  const _BlinkingStatusIndicator({
    required this.size,
    required this.isLowFluid,
  });

  @override
  State<_BlinkingStatusIndicator> createState() =>
      _BlinkingStatusIndicatorState();
}

class _BlinkingStatusIndicatorState extends State<_BlinkingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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
    // 1. Determine Active State (Low Fluid is the "Error" state)
    final bool isActive = widget.isLowFluid;

    // 2. Handle Animation (Exact logic from SystemErrorIndicator)
    if (isActive) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.value = 1.0; // Reset opacity to full
      }
    }

    // 3. Define Styles
    // Active (Low Fluid) = Red
    // Inactive (Normal) = Green (Matches System Normal)
    final Color backgroundColor = isActive
        ? AppColors.colorAccent
        : AppColors.connectionGreen;

    final String text = isActive ? "FLUID: LOW" : "FLUID: NORMAL";

    // Use the height from the size property, but width can be flexible
    final double height = widget.size.height;

    return FadeTransition(
      opacity: isActive
          ? _animationController
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        height: height, // Use fixed height from buttonSize
        width: widget.size.width, // Use fixed width from buttonSize
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(height / 2), // Make it a pill
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.colorAccent.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}