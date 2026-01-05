import 'package:flutter/material.dart';
import 'package:fog_gen_new/constants/app_colors.dart';

import '../widgets/vertical_gap.dart';

class ComplaintItem extends StatelessWidget {
  const ComplaintItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: MaterialCard(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTextWithIcon('For Site   : ', Icons.settings_remote),
                  _buildText('Site Name'),
                ],
              ),
              Divider(),
              Row(
                children: [
                  _buildTextWithIcon('Subject   : ', Icons.info),
                  _buildText('Subject Name'),
                ],
              ),
              Divider(),
              Row(
                children: [
                  _buildTextWithIcon('Message : ', Icons.message),
                  _buildText('Sample message content'),
                ],
              ),
              VerticalSpace(),
              _buildImageRow(),
              Divider(),
              Row(
                children: [
                  _buildTextWithIcon('Date Time :  ', Icons.calendar_month),
                  _buildText('2025-04-25 10:00 AM'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextWithIcon(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.colorPrimary),
        SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
        color: AppColors.colorPrimary,
      ),
    );
  }

  Widget _buildImageRow() {
    return Row(
      children: [
        _buildImage(),
        SizedBox(width: 10),
        _buildImage(),
        SizedBox(width: 10),
        _buildImage(),
      ],
    );
  }

  Widget _buildImage() {
    return Container(width: 100, height: 100, color: Colors.grey);
  }
}

class MaterialCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;
  final ShapeBorder shape;

  const MaterialCard({
    super.key,
    required this.child,
    required this.color,
    required this.elevation,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Card(color: color, elevation: elevation, shape: shape, child: child);
  }
}
