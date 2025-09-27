import 'dart:developer' as developer;
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<bool> sendSms(String phone, String message) async {
  try {
    final encodedMessage = Uri.encodeComponent(message);

    final smsUri = Uri.parse(
      Platform.isIOS
          ? 'sms:$phone&body=$encodedMessage'
          : 'sms:$phone?body=$encodedMessage',
    );

    final launched = await launchUrl(
      smsUri,
      mode: LaunchMode.externalApplication,
    );

    if (launched) {
      developer.log("SMS launch successful → $phone : $message",
          name: 'sendSms');
    }

    return launched;
  } catch (e, stacktrace) {
    developer.log(
      "Error launching SMS composer",
      name: 'sendSms',
      error: e,
      stackTrace: stacktrace,
    );
    return false;
  }
}
