import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AllGradeExamsTile extends StatelessWidget {
  const AllGradeExamsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TestTile(testName: "2016 chemistry UEE", onTap: () {}),
        const SizedBox(height: AppSizes.spaceBtwItems),
        TestTile(testName: "2015 chemistry UEE", onTap: () {}),
        const SizedBox(height: AppSizes.spaceBtwItems),
        TestTile(testName: "2014 chemistry UEE", onTap: () {}),
        const SizedBox(height: AppSizes.spaceBtwItems),
        TestTile(testName: "2013 chemistry UEE", onTap: () {}),
        const SizedBox(height: AppSizes.spaceBtwItems),
        TestTile(testName: "2012 chemistry UEE", onTap: () {}),
        const SizedBox(height: AppSizes.spaceBtwItems),
      ],
    );
  }
}
