import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AppCircularLoading extends StatelessWidget {
  const AppCircularLoading({super.key, this.title = 'Loading...'});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSizes.spaceBtwItems),
          Text(title),
        ],
      ),
    );
  }
}
