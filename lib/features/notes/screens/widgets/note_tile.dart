import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
      final isDownloading = ctrl.isDownloading[note.id] ?? false;
      final progress = ctrl.downloadProgress[note.id];
      final user = UserController.instance.user.value;
      final isLocked = note.isPremium && !user.isActive;

      final cardBg = dark ? AppColors.darkSurface : AppColors.white;
      final borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDownloading
                ? const Color(0xFF8B5CF6)
                : borderColor,
            width: isDownloading ? 1.5 : 1,
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── Chapter / Unit Number Squircle ──────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLocked
                            ? [AppColors.grey, AppColors.darkGrey]
                            : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isLocked
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: isLocked
                          ? const Icon(Icons.lock_rounded,
                              color: AppColors.white, size: 22)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'UNIT',
                                  style: TextStyle(
                                    color: Color(0xFFDDD6FE),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${note.chapterNumber}',
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
                  ),

                  const SizedBox(width: 14),

                  // ── Title & Metadata ────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: dark
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.description != null &&
                            note.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            note.description!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),

                        // Chips: Pages, File Size, Type, Premium
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (note.formattedPages.isNotEmpty)
                              _buildMetadataChip(
                                dark: dark,
                                text: note.formattedPages,
                                icon: Icons.menu_book_rounded,
                              ),
                            if (note.formattedSize.isNotEmpty)
                              _buildMetadataChip(
                                dark: dark,
                                text: note.formattedSize,
                                icon: Icons.attach_file_rounded,
                              ),
                            if (note.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 11,
                                      color: Colors.amber,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Action: Download / Read / Progress ──────────────────────
                  _buildTrailingAction(
                    context: context,
                    dark: dark,
                    isDownloading: isDownloading,
                    progress: progress,
                    ctrl: ctrl,
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

  Widget _buildTrailingAction({
    required BuildContext context,
    required bool dark,
    required bool isDownloading,
    required double? progress,
    required NotesController ctrl,
  }) {
    if (isDownloading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            ),
            if (progress != null)
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B5CF6),
                ),
              ),
          ],
        ),
      );
    }

    if (note.isDownloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offline checkmark badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: dark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: AppColors.success,
                ),
                SizedBox(width: 4),
                Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          // Context menu to delete if needed
          PopupMenuButton<String>(
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
          ),
        ],
      );
    }

    // Not downloaded -> show download button
    return IconButton(
      tooltip: 'Download note',
      onPressed: () => ctrl.downloadNote(note),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: dark ? 0.2 : 0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 18,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }
}
