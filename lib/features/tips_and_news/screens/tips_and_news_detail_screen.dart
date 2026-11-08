import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/exam/question_content_renderer.dart';
import 'package:matricmate/features/tips_and_news/controllers/tips_and_news_controller.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

class TipsAndNewsDetailScreen extends StatefulWidget {
  const TipsAndNewsDetailScreen({super.key, required this.item});

  final TipsAndNewsModel item;

  @override
  State<TipsAndNewsDetailScreen> createState() => _TipsAndNewsDetailScreenState();
}

class _TipsAndNewsDetailScreenState extends State<TipsAndNewsDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read immediately on viewing
    TipsAndNewsController.instance.markAsRead(widget.item.id);
  }

  void _shareContent() {
    // ignore: deprecated_member_use
    Share.share(
      '${widget.item.title}\n\n${widget.item.content}\n\n— via MatricMate',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final item = widget.item;
    final isNews = item.isNews;

    final catColor = isNews ? const Color(0xFF0284C7) : const Color(0xFFD97706);
    final catBg = isNews
        ? (dark ? const Color(0xFF0284C7).withValues(alpha: 0.18) : const Color(0xFFE0F2FE))
        : (dark ? const Color(0xFFD97706).withValues(alpha: 0.18) : const Color(0xFFFEF3C7));

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          isNews ? 'News' : 'Study Tip',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share_copy, size: 20),
            tooltip: 'Share',
            onPressed: _shareContent,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Meta Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNews ? Iconsax.volume_high_copy : Iconsax.lamp_on_copy,
                        size: 13,
                        color: catColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isNews ? 'News' : 'Tip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.readingTimeMinutes} min read',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Article Title (supports BBCode, bold, color tags as used on explanations)
            QuestionContentRenderer(
              text: item.title,
              baseStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : AppColors.textPrimary,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 14),

            // Author and Date Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isNews ? const Color(0xFF0284C7) : AppColors.primary,
                    child: Text(
                      item.author.isNotEmpty ? item.author[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.author,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy • h:mm a').format(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Cover Image (if available)
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  item.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      color: dark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Article Body Content (Unified explanation formatting: font color, LaTeX, tables, BBCode, markup)
            QuestionContentRenderer(
              text: item.content,
              baseStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.65,
                letterSpacing: 0.1,
                color: dark
                    ? AppColors.white.withValues(alpha: 0.85)
                    : AppColors.darkerGrey,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

