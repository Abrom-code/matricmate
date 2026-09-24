import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteModel note;
  late String subjectTitle;
  late int subjectId;
  late bool isCommon;

  final RxList<TestModel> chapterTests = <TestModel>[].obs;
  final RxBool isLoadingTests = true.obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    note = args['note'] as NoteModel;
    subjectTitle = args['subject_title'] ?? 'Subject';
    subjectId = args['subject_id'] ?? note.subjectId;
    isCommon = args['is_common'] == true;

    _loadChapterTests();
  }

  Future<void> _loadChapterTests() async {
    try {
      isLoadingTests.value = true;
      if (note.chapterId != null) {
        final rows = await DatabaseService.instance.getTests(
          subjectId: subjectId,
          chapterId: note.chapterId,
        );
        chapterTests.assignAll(rows.map((r) => TestModel.fromMap(r)).toList());
      }
    } catch (_) {
      // Non-fatal
    } finally {
      isLoadingTests.value = false;
    }
  }

  void _onReadNote() {
    final user = UserController.instance.user.value;
    if (note.isPremium && !user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    if (!note.isDownloaded) {
      // Prompt student to download or offer direct online view
      Get.bottomSheet(
        _buildDownloadRequiredSheet(context),
        isScrollControlled: true,
      );
      return;
    }

    Get.toNamed(
      Routes.noteReader,
      arguments: {
        'note': note,
        'subject_title': subjectTitle,
        'chapter_tests': chapterTests.toList(),
      },
    );
  }

  Widget _buildDownloadRequiredSheet(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final ctrl = NotesController.instance;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_for_offline_rounded,
              size: 36,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download to Read Offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: dark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download ${note.title} (${note.formattedSize}) to read with full zoom and offline support.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Get.back();
                ctrl.downloadNote(note).then((_) {
                  // After download finishes, update local note reference
                  final updated = ctrl.subjectNotes
                      .firstWhereOrNull((n) => n.id == note.id);
                  if (updated != null && mounted) {
                    setState(() => note = updated);
                  }
                });
              },
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                'Download Now (${note.formattedSize})',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unit ${note.chapterNumber} Note',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$subjectTitle • Grade ${note.grade}',
              style: const TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Note Overview Card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Unit ${note.chapterNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.darkCard : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grade ${note.grade}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (note.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 13, color: Colors.amber),
                              SizedBox(width: 3),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: dark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),

                  if (note.description != null &&
                      note.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.description!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color:
                            dark ? AppColors.darkGrey : AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Metadata Badges (Pages, File Size, Offline Status)
                  Row(
                    children: [
                      if (note.formattedPages.isNotEmpty) ...[
                        _buildHeroChip(
                          dark: dark,
                          icon: Icons.menu_book_rounded,
                          label: note.formattedPages,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (note.formattedSize.isNotEmpty) ...[
                        _buildHeroChip(
                          dark: dark,
                          icon: Icons.attach_file_rounded,
                          label: note.formattedSize,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildHeroChip(
                        dark: dark,
                        icon: note.isDownloaded
                            ? Icons.check_circle_rounded
                            : Icons.cloud_outlined,
                        label: note.isDownloaded ? 'Downloaded' : 'Cloud',
                        iconColor: note.isDownloaded
                            ? AppColors.success
                            : (dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Primary "Read Note" Button ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _onReadNote,
                      icon: const Icon(Icons.menu_book_rounded, size: 20),
                      label: Text(
                        note.isDownloaded ? 'Read Chapter Note' : 'Download & Read',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section Header: Chapter Practice Tests ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter Practice Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: dark ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Test your understanding after reading',
                      style: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  if (chapterTests.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${chapterTests.length} tests',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 14),

            // ── Chapter Tests List ───────────────────────────────────────────
            Obx(() {
              if (isLoadingTests.value) {
                return const AppCircularLoading(
                  title: 'Loading chapter tests...',
                );
              }

              if (chapterTests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 32,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No specific tests linked to this unit yet.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapterTests.length,
                itemBuilder: (context, index) {
                  final test = chapterTests[index];
                  final user = UserController.instance.user.value;
                  final canAccess = TestAccessHelper.canAccess(
                    test: test,
                    user: user,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.darkSurface : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? AppColors.darkBorder
                            : AppColors.borderPrimary,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          TestAccessHelper.handleTestTap(
                            test: test,
                            user: user,
                            onStart: () {
                              Get.to(
                                () => ReadyScreen(
                                  qnCount: test.questionCount,
                                  time: test.time,
                                  testId: test.id,
                                  id: 1,
                                  examTitle: test.title,
                                  description: test.description,
                                ),
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (canAccess
                                          ? AppColors.primary
                                          : Colors.amber)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  canAccess
                                      ? Iconsax.message_question_copy
                                      : Icons.lock_rounded,
                                  color: canAccess
                                      ? AppColors.primary
                                      : Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      test.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: dark
                                            ? AppColors.textWhite
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${test.questionCount} Questions • ${test.time > 0 ? "${test.time} mins" : "Untimed"}',
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
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroChip({
    required bool dark,
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: iconColor ??
                (dark ? AppColors.darkGrey : AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
