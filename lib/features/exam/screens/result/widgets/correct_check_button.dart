import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';

class CorrectCheckButton extends StatelessWidget {
  const CorrectCheckButton({
    super.key,
    this.text = 'Correct',
    this.color = AppColors.primary,
    this.icon = Iconsax.tick_circle_copy,
  });
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 17),
        Text(text.toUpperCase(), style: TextStyle(color: color)),
      ],
    );
  }
}
