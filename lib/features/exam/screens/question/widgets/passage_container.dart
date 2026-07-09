import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class PassageContainer extends StatelessWidget {
  const PassageContainer({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final block = controller.blocks[controller.currentBlockIndex.value];
      final expanded = controller.isFullScreenPassage.value;
      final hidden = controller.isPassageHidden.value;

      final contentMaxHeight = expanded
          ? MediaQuery.of(context).size.height * 0.72
          : MediaQuery.of(context).size.height * 0.30;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.sm,
          AppSizes.md,
          0,
        ),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkerGrey.withValues(alpha: 0.45)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            _PassageHeader(
              title: block.passage?.title,
              dark: dark,
              expanded: expanded,
              hidden: hidden,
              controller: controller,
            ),

            // ── Content ───────────────────────────────────────────────
            if (!hidden)
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(maxHeight: contentMaxHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    0,
                    AppSizes.md,
                    AppSizes.md,
                  ),
                  child: Obx(() => RichTextParser.widget(
                    block.passage?.content ?? 'Loading...',
                    baseStyle: TextStyle(
                      fontSize: 15 * controller.textScale.value,
                      height: 1.75,
                      color: dark ? AppColors.grey : AppColors.darkerGrey,
                    ),
                  )),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Header row ───────────────────────────────────────────────────────────────

class _PassageHeader extends StatelessWidget {
  const _PassageHeader({
    required this.title,
    required this.dark,
    required this.expanded,
    required this.hidden,
    required this.controller,
  });

  final String? title;
  final bool dark;
  final bool expanded;
  final bool hidden;
  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.08),
        borderRadius: hidden
            ? BorderRadius.circular(AppSizes.borderRadiusLg)
            : const BorderRadius.vertical(
                top: Radius.circular(AppSizes.borderRadiusLg),
              ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.article_outlined,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: AppSizes.sm),

          // title
          Expanded(
            child: Text(
              title != null && title!.isNotEmpty ? title! : 'Reading Passage',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // text-scale controls — only when visible & expanded
          if (!hidden && expanded) ...[
            _ScaleBtn(
              icon: Icons.text_decrease,
              onTap: controller.decreaseTextScale,
            ),
            _ScaleBtn(
              icon: Icons.text_increase,
              onTap: controller.increaseTextScale,
            ),
            const SizedBox(width: AppSizes.xs),
          ],

          // expand / collapse
          GestureDetector(
            onTap: hidden
                ? controller.togglePassage          // unhide
                : controller.togglePassageSize,     // expand ↔ collapse
            child: Icon(
              hidden
                  ? Icons.keyboard_arrow_down_rounded
                  : expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          // hide / show toggle
          const SizedBox(width: AppSizes.xs),
          GestureDetector(
            onTap: controller.togglePassage,
            child: Icon(
              hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 18,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}
