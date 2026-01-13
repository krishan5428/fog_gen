import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import '../presentation/dialog/progress_with_message.dart';

Future<bool?> trySendSms(
  BuildContext context,
  String device,
  PermissionStatus smsPermission,
  String simNumber,
  List<String> messages,
) async {
  final result = await ProgressDialogWithMessage.show(
    context,
    messages: messages,
    panelSimNumber: simNumber,
  );
  return result;
}
