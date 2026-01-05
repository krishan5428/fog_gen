import 'package:fog_gen_new/utils/send_sms.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ProgressDialogWithMessage {
  static bool _isShowing = false;

  // Make this STATIC so it can be used inside static show()
  static Widget _buildSmsRow(
    int index,
    String message,
    bool sent,
    bool isSending,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "SMS ${index + 1}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child:
                sent
                    ? const Icon(Icons.check, color: Colors.green)
                    : isSending
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

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
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              bool dialogMounted = true;

              // Safe setState
              void safeSetState(VoidCallback fn) {
                if (dialogMounted && context.mounted) {
                  setState(fn);
                }
              }

              // Start sending
              Future<void> sendAll() async {
                safeSetState(() => isSending = true);

                SendSms(
                  panelSimNumber,
                  messages,
                  safeSetState,
                  smsStatus,
                  onComplete: () {
                    if (_isShowing && context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    }
                  },
                ).start();
              }

              return WillPopScope(
                onWillPop: () async => false,
                child: Dialog(
                  backgroundColor: Colors.grey[200],
                  insetPadding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              itemBuilder:
                                  (ctx, index) => _buildSmsRow(
                                    index,
                                    messages[index],
                                    smsStatus[index],
                                    isSending,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (!isSending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    dialogMounted = false;
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(false);
                                  },
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
                                  onPressed: sendAll,
                                  child: const Text("Send SMS"),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
