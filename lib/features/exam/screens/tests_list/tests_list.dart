import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class TestListScreen extends StatelessWidget {
  const TestListScreen({
    super.key,
    required this.subject,
    required this.chapter,
  });
  final String subject, chapter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '$subject - $chapter'.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.apply(color: AppColors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: AppColors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          spacing: AppSizes.spaceBtwItems,
          children: [
            TestTile(testName: "Test one", onTap: () {}),
            TestTile(testName: "test two", onTap: () {}),
            TestTile(testName: "Test three", onTap: () {}),
            TestTile(testName: "Test four ", onTap: () {}),
            TestTile(testName: "Test five", onTap: () {}),
            TestTile(testName: "Test six", onTap: () {}),
          ],
        ),
      ),
    );
  }
}
