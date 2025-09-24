import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../widgets/app_bar.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(pageName: 'About Us', isFilter: false),
      body: Column(
        children: [
          Container(
            color: AppColors.litePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: const Row(
              children: [
                Icon(Icons.info, size: 14, color: AppColors.colorPrimary),
                SizedBox(width: 3),
                Text(
                  'All mobile numbers and emails are Clickable!',
                  style: TextStyle(fontSize: 10, color: AppColors.colorPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SectionTitle(title: 'North & East Tech Support'),
                  SupportItem(icon: Icons.call, text: '+91-9315400064'),
                  SupportItem(icon: Icons.phone, text: '012-94270000'),
                  SupportItem(icon: Icons.call, text: '+91-98117 80118'),
                  Divider(),

                  SectionTitle(title: 'West Tech Support'),
                  SupportItem(icon: Icons.call, text: '+91-9833422307'),
                  SupportItem(icon: Icons.call, text: '+91-8287811494'),
                  SupportItem(icon: Icons.call, text: '+91-9999705491'),
                  Divider(),

                  SectionTitle(title: 'South Tech Support'),
                  SupportItem(icon: Icons.call, text: '+91-7827969966'),
                  SupportItem(icon: Icons.call, text: '+91-8124211311'),
                  Divider(),

                  SectionTitle(title: 'Pre-Sales Support'),
                  SupportItem(icon: Icons.call, text: '+91-98735 75711'),
                  Divider(),

                  SectionTitle(title: 'Service and Support Escalation'),
                  SupportItem(icon: Icons.call, text: '+91-9999705491'),
                  SupportItem(
                    icon: Icons.email,
                    text: 'support@securicoelectronics.com',
                  ),
                  SupportItem(
                    icon: Icons.email,
                    text: 'info@securicoelectronics.com',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.colorAccent,
        ),
      ),
    );
  }
}

class SupportItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const SupportItem({required this.icon, required this.text, super.key});

  void _handleTap() async {
    String url;
    if (text.contains('@')) {
      url = 'mailto:$text';
    } else {
      // Remove spaces and non-numeric characters for phone numbers
      final cleanedNumber = text.replaceAll(RegExp(r'[^\d+]'), '');
      url = 'tel:$cleanedNumber';
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.colorPrimary, size: 16),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: _handleTap,
                splashColor: AppColors.colorPrimary.withAlpha(50),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.colorPrimary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.colorPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
