import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class GridLayout extends StatelessWidget {
  const GridLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossCount,
    this.mainAxisExtent = 150,
  });

  final int itemCount;
  final double? mainAxisExtent;
  final int? crossCount;
  final Widget? Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount ?? 2,
        mainAxisExtent: mainAxisExtent,
        mainAxisSpacing: AppSizes.gridViewSpacing,
        crossAxisSpacing: AppSizes.gridViewSpacing,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
