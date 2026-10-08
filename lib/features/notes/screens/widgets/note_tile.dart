import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/notes/screens/widgets/note_rating_sheet.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/new_tag_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
  });

  final NoteModel note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final ctrl = NotesController.instance;

    return Obx(() {
      final liveNote =
          ctrl.subjectNotes.firstWhereOrNull((n) => n.id == note.id) ?? note;
      final isDownloading = ctrl.isDownloading[liveNote.id] ?? false;
      final progress = ctrl.downloadProgress[liveNote.id];
      final user = UserController.instance.user.value;
      final isLocked = liveNote.isPremium && !user.isActive;
      final isCompleted = liveNote.isCompleted;

      final cardBg = dark ? AppColors.darkSurface : AppColors.white;
      final borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;

      final badgeText = (liveNote.grade == 0 || liveNote.chapterNumber <= 0)
          ? 'ALL'
          : (liveNote.chapterNumber < 10
              ? '0${liveNote.chapterNumber}'
              : '${liveNote.chapterNumber}');

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLocked
                    ? Colors.amber.withValues(alpha: dark ? 0.40 : 0.28)
                    : borderColor,
            width: isLocked ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              NewTagHelper.markNoteOpened(liveNote.id);
              if (isLocked) {
                onTap();
              } else if (liveNote.isDownloaded) {
                onTap();
              } else if (isDownloading) {
                // Currently downloading
              } else {
                ToastHelper.info('Please download this note first');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── Chapter / Unit Number Squircle ──────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.amber.withValues(
                                  alpha: dark ? 0.20 : 0.12,
                                )
                              : null,
                          gradient: isLocked
                              ? null
                              : isCompleted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF047857),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        ChallengeColors.accent,
                                        Color(0xFF0369A1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                          borderRadius: BorderRadius.circular(14),
                          border: isLocked
                              ? Border.all(
                                  color: Colors.amber.withValues(alpha: 0.35),
                                  width: 1,
                                )
                              : isCompleted
                                  ? Border.all(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.5),
                                      width: 1,
                                    )
                                  : null,
                          boxShadow: isLocked
                              ? null
                              : [
                                  BoxShadow(
                                    color: (isCompleted
                                            ? const Color(0xFF10B981)
                                            : ChallengeColors.accent)
                                        .withValues(alpha: 0.32),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: isLocked
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    badgeText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              )
                            : (liveNote.grade == 0 ||
                                    liveNote.chapterNumber <= 0)
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        color: AppColors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'ALL',
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'UNIT',
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${liveNote.chapterNumber}',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                      if (isCompleted && !isLocked)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardBg,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: dark ? 0.35 : 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 12.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // ── Title & Metadata ────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                liveNote.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: dark
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (liveNote.isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (liveNote.description != null &&
                                  liveNote.description!.trim().isNotEmpty)
                              ? liveNote.description!.trim()
                              : (liveNote.grade == 0
                                  ? 'Subject guide and reference notes'
                                  : 'Chapter summary and key concepts'),
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // ── Third Line: Pages, File Size in MB ─────────────────
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (liveNote.formattedPages.isNotEmpty)
                              _buildMetadataChip(
                                dark: dark,
                                text: liveNote.formattedPages,
                                icon: Icons.menu_book_rounded,
                              ),
                            if (liveNote.sizeInMB.isNotEmpty)
                              _buildMetadataChip(
                                dark: dark,
                                text: liveNote.sizeInMB,
                                icon: Icons.attach_file_rounded,
                              ),
                            if (liveNote.isCompleted)
                              _buildRatingChip(
                                context: context,
                                dark: dark,
                                note: liveNote,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Action: Download / Read / Progress ──────────────────────
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: _buildTrailingAction(
                        context: context,
                        dark: dark,
                        isLocked: isLocked,
                        isDownloading: isDownloading,
                        progress: progress,
                        note: liveNote,
                        ctrl: ctrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMetadataChip({
    required bool dark,
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10.5,
            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
          const SizedBox(width: 3.5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip({
    required BuildContext context,
    required bool dark,
    required NoteModel note,
  }) {
    final isRated = note.isRated;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          NoteRatingSheet.show(context, note: note);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isRated
                ? const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.14)
                : (dark ? AppColors.darkCard : AppColors.lightGrey),
            borderRadius: BorderRadius.circular(6),
            border: isRated
                ? Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRated ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 11,
                color: isRated
                    ? const Color(0xFFF59E0B)
                    : (dark ? AppColors.darkGrey : AppColors.textSecondary),
              ),
              const SizedBox(width: 3),
              Text(
                isRated ? '${note.userRating}/5' : 'Rate',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isRated
                      ? (dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                      : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingAction({
    required BuildContext context,
    required bool dark,
    required bool isLocked,
    required bool isDownloading,
    required double? progress,
    required NoteModel note,
    required NotesController ctrl,
  }) {
    // ── Downloading: compact circular progress ──
    if (isDownloading) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: ChallengeColors.accent,
              backgroundColor: ChallengeColors.accent.withValues(alpha: 0.15),
            ),
            if (progress != null && progress > 0)
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: ChallengeColors.accent,
                  height: 1.0,
                ),
              )
            else
              Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: ChallengeColors.accent.withValues(alpha: 0.6),
              ),
          ],
        ),
      );
    }

    // ── Locked ──
    if (isLocked) {
      return Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: dark ? AppColors.darkGrey : AppColors.grey,
      );
    }

    // ── Downloaded: popup menu ──
    if (note.isDownloaded) {
      return PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onSelected: (val) {
          if (val == 'delete') {
            ctrl.deleteDownloadedNote(note);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Remove from device',
                  style: TextStyle(fontSize: 12.5, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Not downloaded: download button ──
    return GestureDetector(
      onTap: () => ctrl.downloadNote(note),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: ChallengeColors.accent.withValues(alpha: dark ? 0.2 : 0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 17,
            color: ChallengeColors.accent,
          ),
        ),
      ),
    );
  }
}
