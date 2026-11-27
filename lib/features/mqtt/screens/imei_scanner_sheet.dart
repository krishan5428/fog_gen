import 'dart:async';

import 'package:fog_gen_new/constants/constants.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures camera access, then opens the IMEI barcode scanner bottom sheet.
///
/// Works the same on Android and iOS:
///   * first call  -> shows the OS camera permission prompt
///   * denied      -> shows an "Open Settings" dialog and returns null
///   * granted     -> opens the scanner sheet
///
/// Returns the scanned IMEI digits, or `null` if the user dismissed the
/// sheet / denied permission / the camera could not start.
Future<String?> showImeiScanner(BuildContext context) async {
  var status = await Permission.camera.status;

  // Not asked yet -> trigger the native OS prompt (same dialog on both
  // platforms; iOS only ever shows it once per install).
  if (status.isDenied) {
    status = await Permission.camera.request();
  }

  if (!status.isGranted) {
    if (context.mounted) {
      await _showPermissionDeniedDialog(context);
    }
    return null;
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ImeiScannerSheet(),
  );
}

Future<void> _showPermissionDeniedDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            color: AppColors.colorPrimary,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Camera Access Required',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const Text(
        'Camera permission is needed to scan the IMEI barcode.\n\n'
        'Please enable camera access for this app in Settings.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            openAppSettings();
          },
          child: const Text(
            'Open Settings',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// IMEI scanner bottom-sheet widget
// Uses a real StatefulWidget so the MobileScannerController lifecycle is
// correctly tied to initState/dispose and survives camera interruptions.
//
// Some OEM devices (Vivo T4 Pro and similar) grab camera 0 within ~2-3s of
// open, killing the ML Kit analysis stream. The platform layer recovers
// internally but mobile_scanner's isRunning flag may not update during those
// internal restarts, so we combine two strategies:
//   1. _onControllerState listener  — catches cases where isRunning -> false
//   2. _recoveryTimer at 5 s        — guaranteed stop/start AFTER the OEM
//                                      interruption window, as a safety net
// Every controller call is wrapped so a failed start/stop can never crash
// the sheet; the worst case is the "Camera initializing..." overlay staying
// up, which the user can dismiss with the close button.
// ---------------------------------------------------------------------------
class _ImeiScannerSheet extends StatefulWidget {
  const _ImeiScannerSheet();

  @override
  State<_ImeiScannerSheet> createState() => _ImeiScannerSheetState();
}

class _ImeiScannerSheetState extends State<_ImeiScannerSheet> {
  MobileScannerController? _ctrl;
  bool _recovering = false;
  bool _detected = false;
  Timer? _recoveryTimer;

  @override
  void initState() {
    super.initState();
    try {
      _ctrl = MobileScannerController(
        detectionSpeed: DetectionSpeed.unrestricted,
      );
      _ctrl!.addListener(_onControllerState);
      // Safety net: force a clean stop/start 5 s after open so an OEM
      // interruption (which always completes by then) doesn't leave the
      // analysis stream dead.
      _recoveryTimer = Timer(const Duration(seconds: 5), _forceRestart);
    } catch (e) {
      debugPrint('IMEI_SCAN: controller init failed: $e');
    }
  }

  void _onControllerState() {
    final ctrl = _ctrl;
    if (ctrl == null || !mounted || _detected) return;
    final running = ctrl.value.isRunning;
    if (!running && !_recovering) {
      setState(() => _recovering = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || _ctrl == null) return;
        _ctrl!
            .start()
            .then((_) {
              if (mounted) setState(() => _recovering = false);
            })
            .catchError((_) {
              if (mounted) setState(() => _recovering = false);
            });
      });
    } else if (running && _recovering) {
      setState(() => _recovering = false);
    }
  }

  Future<void> _forceRestart() async {
    final ctrl = _ctrl;
    if (ctrl == null || !mounted || _detected) return;
    setState(() => _recovering = true);
    try {
      await ctrl.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _ctrl == null) return;
    try {
      await _ctrl!.start();
    } catch (_) {}
    if (mounted) setState(() => _recovering = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue ?? barcode.displayValue ?? '';
      if (raw.isEmpty) continue;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      // A standard IMEI is exactly 15 numeric digits. Keep scanning until a
      // code that matches is seen, so unrelated barcodes on the label are
      // ignored rather than filled into the field.
      if (digits.length != 15) continue;
      _detected = true;
      _recoveryTimer?.cancel();
      Navigator.pop(context, digits);
      return;
    }
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    _ctrl?.removeListener(_onControllerState);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(cornerRadius),
          topRight: Radius.circular(cornerRadius),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Scan IMEI Barcode",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ctrl != null)
                      ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, state, __) {
                          final torchOn = state.torchState == TorchState.on;
                          final available =
                              state.torchState != TorchState.unavailable;
                          if (!available) return const SizedBox.shrink();
                          return IconButton(
                            icon: Icon(
                              torchOn
                                  ? Icons.flashlight_on
                                  : Icons.flashlight_off,
                              color: torchOn
                                  ? Colors.yellowAccent
                                  : Colors.white,
                            ),
                            onPressed: () {
                              try {
                                ctrl.toggleTorch();
                              } catch (_) {}
                            },
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ctrl == null
                ? _cameraUnavailable()
                : Stack(
                    children: [
                      MobileScanner(
                        controller: ctrl,
                        onDetect: _onDetect,
                        onDetectError: (error, stack) {
                          debugPrint('IMEI_SCAN detect error: $error');
                        },
                        errorBuilder: (context, error) => _cameraUnavailable(
                          detail: error.errorDetails?.message,
                        ),
                      ),
                      if (_recovering)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Camera initializing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              "Point camera at the IMEI barcode on the device.\nPlease keep the scanner 8 cm to 12 cm away from the barcode.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraUnavailable({String? detail}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              detail == null || detail.isEmpty
                  ? 'Camera could not be started.\nPlease close and try again, or type the IMEI manually.'
                  : detail,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
