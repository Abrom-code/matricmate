import 'package:flutter/material.dart';

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key, required this.examQn});

  final int examQn;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: TextAlign.justify,
      TextSpan(
        children: [
          TextSpan(
            text: "$examQn. ",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          TextSpan(
            text:
                "Use Hansen's bearing-capacity equation for current practice due to its comprehensive correction factors and compatibility with measured cu/φ and modern design codes.?",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 19),
          ),
        ],
      ),
    );
  }
}
