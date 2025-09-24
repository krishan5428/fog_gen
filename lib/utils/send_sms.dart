import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> sendSms({
  required BuildContext context,
  required String phoneNumber,
  required String message,
}) async {
  final encodedMessage = Uri.encodeComponent(message);
  final Uri smsUri = Uri.parse('sms:$phoneNumber?body=$encodedMessage');

  try {
    final bool launched = await launchUrl(
      smsUri,
      mode: LaunchMode.platformDefault,
    );
    if (!launched) {
      throw 'Could not launch SMS';
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not launch SMS app')));
  }
}
