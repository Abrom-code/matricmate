import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class ChallengePassageContainer extends StatelessWidget {
  const ChallengePassageContainer({
    super.key,
    required this.passage,
    required this.isFullScreen,
    required this.isHidden,
    required this.textScale,
    required this.outerScrollController,
    required this.onToggleSize,
    required this.onToggleHidden,
    required this.onIncreaseScale,
    required this.onDecreaseScale,
  });

  final PassageModel passage;
  final RxBool isFullScreen;
  final RxBool isHidden;
  final RxDouble textScale;
  final ScrollController outerScrollController;
  final VoidCallback onToggleSize;
  final VoidCallback onToggleHidden;
  final VoidCallback onIncreaseScale;
  final VoidCallback onDecreaseScale;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final expanded = isFullScreen.value;
      final hidden = isHidden.value;

      final contentMaxHeight = expanded
          ? MediaQuery.of(context).size.height * 0.65
          : MediaQuery.of(context).size.height * 0.28;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            _PassageHeader(
              title: passage.title,
              dark: dark,
              expanded: expanded,
              hidden: hidden,
              onToggleSize: onToggleSize,
              onToggleHidden: onToggleHidden,
              onIncreaseScale: onIncreaseScale,
              onDecreaseScale: onDecreaseScale,
            ),

            // ── Content ───────────────────────────────────────────────
            if (!hidden)
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(maxHeight: contentMaxHeight),
                child: NotificationListener<OverscrollNotification>(
                  onNotification: (notification) {
                    if (outerScrollController.hasClients) {
                      final current = outerScrollController.offset;
                      final max =
                          outerScrollController.position.maxScrollExtent;

                      if (notification.overscroll > 0) {
                        final target = (current + notification.overscroll)
                            .clamp(0.0, max);
                        outerScrollController.jumpTo(target);
                      } else if (notification.overscroll < 0) {
                        final target = (current + notification.overscroll)
                            .clamp(0.0, max);
                        outerScrollController.jumpTo(target);
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      0,
                      AppSizes.md,
                      AppSizes.md,
                    ),
                    child: Obx(
                      () => RichTextParser.widget(
                        passage.content.isNotEmpty
                            ? passage.content
                            : 'Reading passage content loading...',
                        baseStyle: TextStyle(
                          fontSize: 15 * textScale.value,
                          fontWeight: FontWeight.w400,
                          height: 1.75,
                          color: dark ? AppColors.grey : AppColors.darkerGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _PassageHeader extends StatelessWidget {
  const _PassageHeader({
    required this.title,
    required this.dark,
    required this.expanded,
    required this.hidden,
    required this.onToggleSize,
    required this.onToggleHidden,
    required this.onIncreaseScale,
    required this.onDecreaseScale,
  });

  final String? title;
  final bool dark;
  final bool expanded;
  final bool hidden;
  final VoidCallback onToggleSize;
  final VoidCallback onToggleHidden;
  final VoidCallback onIncreaseScale;
  final VoidCallback onDecreaseScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.12),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: hidden
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: dark ? 0.15 : 0.1),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.article_outlined,
            color: AppColors.primary.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: AppSizes.sm),

          // title
          Expanded(
            child: Text(
              title != null && title!.isNotEmpty ? title! : 'Reading Passage',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // text-scale controls — only when visible & expanded
          if (!hidden && expanded) ...[
            _ScaleBtn(
              icon: Icons.text_decrease,
              onTap: onDecreaseScale,
            ),
            _ScaleBtn(
              icon: Icons.text_increase,
              onTap: onIncreaseScale,
            ),
            const SizedBox(width: AppSizes.xs),
          ],

          // expand / collapse
          GestureDetector(
            onTap: hidden ? onToggleHidden : onToggleSize,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedRotation(
                turns: expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hidden
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ),

          // hide / show toggle
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onToggleHidden,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: hidden
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleBtn extends StatelessWidget {
  const _ScaleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
    );
  }
}
