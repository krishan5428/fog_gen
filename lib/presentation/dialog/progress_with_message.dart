import 'package:fire_nex/utils/auth_helper.dart';
import 'package:fire_nex/utils/send_sms.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import '../../constants/app_colors.dart';

class ProgressDialogWithMessage {
  static bool _isShowing = false;

  static Future<bool?> show(
    BuildContext context, {
    String message =
        'The messages will be sent to the Panel from your phone...',
    required List<String> messages,
    required String panelSimNumber,
  }) async {
    if (messages.isEmpty) return false;
    if (_isShowing) return false;

    _isShowing = true;
    List<bool> smsStatus = List.filled(messages.length, false);
    bool isSending = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => WillPopScope(
            onWillPop: () async => false,
            child: StatefulBuilder(
              builder: (context, setState) {
                Future<void> sendAll() async {
                  setState(() => isSending = true);

                  final hasPermission = await Permission.sms.isGranted;
                  final device = await SharedPreferenceHelper.getDeviceType();

                  if (hasPermission && device == "ANDROID") {
                    final telephony = Telephony.instance;
                    for (int i = 0; i < messages.length; i++) {
                      bool sent = false;
                      try {
                        await telephony.sendSms(
                          to: panelSimNumber,
                          message: messages[i],
                        );
                        sent = true;
                      } catch (_) {
                        sent = false;
                      }

                      setState(() => smsStatus[i] = sent);
                      if (i < messages.length - 1) {
                        await Future.delayed(const Duration(seconds: 3));
                      }
                    }
                    // Auto dismiss after sending all
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_isShowing) {
                        Navigator.of(context, rootNavigator: true).pop(true);
                      }
                    });
                  } else {
                    SendSms(
                      panelSimNumber,
                      messages,
                      setState,
                      smsStatus,
                      onComplete: () {
                        if (_isShowing) {
                          Navigator.of(context, rootNavigator: true).pop(true);
                        }
                      },
                    ).start();
                  }
                }

                return Dialog(
                  backgroundColor: Colors.grey[200],
                  insetPadding: EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: messages.length,
                              itemBuilder: (ctx, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          "SMS ${index + 1}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            messages[index],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            smsStatus[index]
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                )
                                                : isSending
                                                ? const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                )
                                                : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!isSending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(
                                        ctx,
                                        rootNavigator: true,
                                      ).pop(false),
                                  child: const Text(
                                    "Revoke",
                                    style: TextStyle(
                                      color: AppColors.colorPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.colorPrimary,
                                    foregroundColor: AppColors.white,
                                  ),
                                  onPressed: () async => await sendAll(),
                                  child: const Text("Send SMS"),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );

    _isShowing = false;
    return result;
  }

  static void dismiss(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
