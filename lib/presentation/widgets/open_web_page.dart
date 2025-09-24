import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openWebPage(BuildContext context, String urlString) async {
  final Uri url = Uri.parse(urlString);
  final bool launched = await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    throw Exception('Could not launch $url');
  }
}
