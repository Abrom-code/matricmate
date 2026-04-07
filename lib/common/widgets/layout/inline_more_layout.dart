import 'package:flutter/material.dart';

class InlineReadMoreText extends StatefulWidget {
  final String text;
  final int limit;

  const InlineReadMoreText({super.key, required this.text, this.limit = 80});

  @override
  State<InlineReadMoreText> createState() => _InlineReadMoreTextState();
}

class _InlineReadMoreTextState extends State<InlineReadMoreText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > widget.limit;

    final displayText = expanded || !isLong
        ? widget.text
        : widget.text.substring(0, widget.limit);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: displayText),

          if (isLong)
            WidgetSpan(
              child: GestureDetector(
                onTap: () => setState(() => expanded = !expanded),
                child: Text(
                  expanded ? " show less" : "... read more",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
