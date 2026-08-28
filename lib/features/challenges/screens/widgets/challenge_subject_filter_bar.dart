import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ChallengeSubjectFilterBar extends StatelessWidget {
  const ChallengeSubjectFilterBar({
    super.key,
    required this.ctrl,
    required this.dark,
    required this.subjects,
  });

  final ChallengeArchiveController ctrl;
  final bool dark;
  final List<SubjectModel> subjects;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: dark ? AppColors.dark : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: Obx(() {
          final selectedId = ctrl.selectedSubjectId.value;

          return Row(
            children: [
              // "All" Chip
              _buildSubjectChip(
                title: 'All',
                count: ctrl.challenges.length,
                isSelected: selectedId == null,
                icon: Iconsax.category_copy,
                dark: dark,
                onTap: () => ctrl.selectSubject(null),
              ),
              const SizedBox(width: 8),

              // Individual Subject Chips
              ...subjects.map((subj) {
                final isSel = selectedId == subj.id;
                final count = ctrl.countForSubject(subj.id);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSubjectChip(
                    title: subj.name,
                    count: count,
                    isSelected: isSel,
                    icon: Iconsax.book_copy,
                    dark: dark,
                    onTap: () => ctrl.selectSubject(subj.id),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSubjectChip({
    required String title,
    required int count,
    required bool isSelected,
    required IconData icon,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (dark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (dark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (dark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (dark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (dark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
