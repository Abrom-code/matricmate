import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/shapes/rounded_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class TimerContainer extends StatelessWidget {
  const TimerContainer({
    super.key,
    required this.time,
    required this.value,
    required this.onChange,
  });
  final int time;
  final bool value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      radius: AppSizes.sm,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timed Mode',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall!.copyWith(color: AppColors.primary),
              ),
              Switch(value: value, onChanged: (_) => onChange()),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems / 2),

          Text(
            'When enabled, a $time-minute timer will apply, The test will be closed when time expires.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems / 2),
        ],
      ),
    );
  }
}
