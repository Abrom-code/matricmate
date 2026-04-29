import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/shapes/rounded_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AttributeBox extends StatelessWidget {
  const AttributeBox({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      width: 95,
      height: 120,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(height: AppSizes.sm),

          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSizes.sm),

          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
