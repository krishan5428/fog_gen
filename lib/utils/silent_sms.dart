import 'dart:developer' as developer;

import 'package:telephony/telephony.dart';

final Telephony telephony = Telephony.instance;
Future<bool> sendSmsSilently(String phone, String message) async {
  bool? permissionsGranted = await telephony.requestSmsPermissions;

  if (permissionsGranted ?? false) {
    try {
      await telephony.sendSms(to: phone, message: message);
      return true;
    } catch (e, stacktrace) {
      developer.log(
        "Error sending SMS",
        name: 'sendSmsSilently',
        error: e,
        stackTrace: stacktrace,
      );
      return false;
    }
  } else {
    return false;
  }
}
