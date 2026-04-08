import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class QuestionProgressIndicator extends StatelessWidget {
  const QuestionProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.defaultSpace),
      child: Column(
        children: [
          // Progress Indicator
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '50%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '3:25',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 10 / 20,
                  backgroundColor: Colors.grey[400],
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
