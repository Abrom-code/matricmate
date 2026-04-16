import 'package:flutter/material.dart';

class RatingStarIcon extends StatelessWidget {
  const RatingStarIcon({super.key, this.isHalf = false, this.size, this.color});
  final bool isHalf;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isHalf ? Icons.star_half : Icons.star,
      size: size,
      color: color,
    );
  }
}
