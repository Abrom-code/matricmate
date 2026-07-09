import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A reusable collapsible passage/comprehension box.
///
/// Behaviour (mirrors [AppExplanationBox]):
///   • Tap anywhere on the collapsed box  → opens it.
///   • Tap the header row while expanded  → closes it.
///   • Tap inside the body text           → absorbed (does NOT close).
///
/// State is managed internally so no toggle callback is needed from the
/// parent. Pass [initiallyExpanded] to control the default open state.
class AppPassageBox extends StatefulWidget {
  const AppPassageBox({
    super.key,
    this.title,
    /// The passage text. Pass `null` while still loading — a spinner is shown.
    this.content,
    this.initiallyExpanded = false,
  });

  final String? title;
  final String? content;
  final bool initiallyExpanded;

  @override
  State<AppPassageBox> createState() => _AppPassageBoxState();
}

class _AppPassageBoxState extends State<AppPassageBox> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final displayTitle = (widget.title != null && widget.title!.isNotEmpty)
        ? widget.title!
        : 'Reading Passage';

    final bgColor = dark
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.primary.withValues(alpha: 0.06);
    final borderColor =
        AppColors.primary.withValues(alpha: dark ? 0.30 : 0.25);

    return GestureDetector(
      // Collapsed: tap anywhere → open.
      // Expanded:  this outer tap is blocked by the header's own detector.
      onTap: _expanded ? null : _toggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header — always tappable to toggle ──────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayTitle,
                        style:
                            Theme.of(context).textTheme.labelSmall!.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              // Absorb taps so body touches never bubble to the outer toggle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.content == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.md),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          widget.content!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            letterSpacing: 0.1,
                            color: dark
                                ? AppColors.white.withValues(alpha: 0.85)
                                : AppColors.darkerGrey,
                          ),
                        ),
                ),
              ),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
