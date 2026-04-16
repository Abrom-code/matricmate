import 'package:flutter/material.dart';

class CircularCheckBox extends StatelessWidget {
  const CircularCheckBox({
    super.key,
    required this.backgroundColor,
    this.iconColor,
    this.radius = 24,
  });
  final Color backgroundColor;
  final Color? iconColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(child: Icon(Icons.check, size: 14, color: iconColor)),
    );
  }
}
