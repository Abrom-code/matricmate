import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/notifications/services/notification_link_parser.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class TipsNewsCard extends StatelessWidget {
  const TipsNewsCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onPinToggle,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  final TipsAndNewsModel item;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final isNews = item.isNews;
    final catColor = isNews ? const Color(0xFF0284C7) : const Color(0xFFD97706);
    final catBg = isNews
        ? (dark ? const Color(0xFF0284C7).withValues(alpha: 0.18) : const Color(0xFFE0F2FE))
        : (dark ? const Color(0xFFD97706).withValues(alpha: 0.18) : const Color(0xFFFEF3C7));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (dark ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFEFF6FF))
            : (dark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (item.isAnyPinned
                  ? (item.isPinned
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.5))
                  : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
          width: isSelected ? 1.8 : (item.isAnyPinned ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row: Checkbox (in selection mode) + Category Badge + Pinned + Date + Unread Dot
                Row(
                  children: [
                    if (isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (dark ? AppColors.darkGrey : const Color(0xFFCBD5E1)),
                            width: 1.8,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : null,
                      ),
                    ],

                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNews ? Iconsax.volume_high_copy : Iconsax.lamp_on_copy,
                            size: 12,
                            color: catColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNews ? 'News' : 'Tip',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (item.isPinned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin_rounded, size: 11, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (item.isUserPinned && !item.isPinned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_rounded, size: 11, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              'Saved',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Date
                    Text(
                      item.formattedDate,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Unread Red Dot
                    if (!item.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],

                    // Bookmark / User Save Button
                    if (!isSelectionMode && onPinToggle != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: item.isSaved ? 'Remove from saved' : 'Save',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onPinToggle!();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              item.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 17,
                              color: item.isSaved
                                  ? const Color(0xFFF59E0B)
                                  : (dark ? AppColors.darkGrey : const Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Main Content Row (Title + Snippet + optional Thumbnail)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            RichTextParser.parse(
                              NotificationLinkParser.stripTags(item.title),
                              TextStyle(
                                fontSize: 15.5,
                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: dark ? Colors.white : AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            RichTextParser.parse(
                              NotificationLinkParser.stripTags(item.content),
                              TextStyle(
                                fontSize: 12.5,
                                color: dark
                                    ? AppColors.white.withValues(alpha: 0.70)
                                    : AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item.imageUrl!,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 68,
                              height: 68,
                              color: dark ? Colors.white10 : const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Bottom Meta: Author
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

