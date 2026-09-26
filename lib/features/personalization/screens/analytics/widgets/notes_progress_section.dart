import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NotesProgressSection extends StatelessWidget {
  const NotesProgressSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final total = controller.totalNotesCount.value;
      final completed = controller.completedNotesCount.value;
      final downloaded = controller.downloadedNotesCount.value;
      final subjectStats = controller.subjectNotesStats;
      final gradeStats = controller.gradeNotesStats;

      final pct = total > 0 ? (completed / total * 100) : 0.0;
      final remaining = (total - completed).clamp(0, total);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero: Syllabus Reading Gauge ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.25 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Iconsax.book_1_copy,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syllabus Reading Mastery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: dark
                                  ? AppColors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Chapter summaries & study guides completion',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Progress Bar + Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}% Read',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '$completed of $total Chapters',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (pct / 100).clamp(0.0, 1.0) : 0.0,
                    minHeight: 10,
                    backgroundColor: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 70
                          ? const Color(0xFF10B981)
                          : pct >= 40
                          ? const Color(0xFFF59E0B)
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Summary Badges: Read, Remaining, Downloaded
                Row(
                  children: [
                    _MiniStatPill(
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      title: '$completed Read',
                      dark: dark,
                    ),
                    const SizedBox(width: 8),
                    _MiniStatPill(
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                      title: '$remaining To Go',
                      dark: dark,
                    ),
                    const SizedBox(width: 8),
                    _MiniStatPill(
                      icon: Icons.offline_pin_rounded,
                      color: const Color(0xFF0284C7),
                      title: '$downloaded Offline',
                      dark: dark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Grade Level Breakdown (if available) ──────────────────────────
          if (gradeStats.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grade Level Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...gradeStats.map((gs) {
                    final gPct = gs.progressPct;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grade ${gs.grade}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? AppColors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                '${gs.completedNotes}/${gs.totalNotes} (${gPct.toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? AppColors.darkGrey
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: gs.totalNotes > 0
                                  ? (gPct / 100).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: dark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                gPct >= 70
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Subject-by-Subject Reading List ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subject Notes Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${subjectStats.length} Subjects',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (subjectStats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No subject notes found for current selection.',
                        style: TextStyle(
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjectStats.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 18,
                      thickness: 0.8,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final item = subjectStats[index];
                      final sPct = item.progressPct;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Get.toNamed(
                            Routes.notes,
                            arguments: {
                              'id': item.subjectId,
                              'subject_id': item.subjectId,
                              'title': item.subjectName,
                              'subject': item.subjectName,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // Circular Subject Progress Gauge
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: CircularProgressIndicator(
                                      value: item.totalNotes > 0
                                          ? (sPct / 100).clamp(0.0, 1.0)
                                          : 0.0,
                                      strokeWidth: 4,
                                      backgroundColor: dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            sPct >= 70
                                                ? const Color(0xFF10B981)
                                                : sPct >= 40
                                                ? const Color(0xFFF59E0B)
                                                : AppColors.primary,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${sPct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? AppColors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Subject Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.subjectName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? AppColors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.completedNotes} of ${item.totalNotes} notes completed'
                                      '${item.downloadedNotes > 0 ? " • ${item.downloadedNotes} offline" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: dark
                                            ? AppColors.darkGrey
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Open Button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: dark ? 0.2 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Read',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.icon,
    required this.color,
    required this.title,
    required this.dark,
  });

  final IconData icon;
  final Color color;
  final String title;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: dark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
