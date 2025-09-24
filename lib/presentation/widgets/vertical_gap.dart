import 'package:flutter/material.dart';

class VerticalSpace extends StatelessWidget {
  final double height;

  const VerticalSpace({this.height = 10, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
