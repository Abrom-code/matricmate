import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/screens/widgets/note_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  NotesController get controller => NotesController.instance;

  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Grade 9', 'grade': 9},
    {'label': 'Grade 10', 'grade': 10},
    {'label': 'Grade 11', 'grade': 11},
    {'label': 'Grade 12', 'grade': 12},
    {'label': 'General', 'grade': 0},
  ];

  late final TabController _tabController;
  final RxInt _currentTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      _currentTabIndex.value = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = controller.title;
    final isCommon = controller.isCommon;
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Appbar.toolbarHeight(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
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
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              isCommon ? 'Section Notes & Guides' : 'Grade & Chapter Notes',
              style: const TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          _buildAppBarAction(),
        ],
        bottom: isCommon
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.white,
                    unselectedLabelColor:
                        AppColors.white.withValues(alpha: 0.70),
                    labelPadding: EdgeInsets.zero,
                    tabs: _tabs.map((t) {
                      return Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              t['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      body: isCommon
          ? _buildCommonNotesView(context, dark)
          : _buildGradedNotesView(context, dark),
    );
  }

  Widget _buildCommonNotesView(BuildContext context, bool dark) {
    return Obx(() {
      if (controller.isLoading.value && controller.subjectNotes.isEmpty) {
        return const AppCircularLoading(title: 'Loading notes...');
      }

      final notes = controller.subjectNotes;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => controller.loadSubjectNotes(forceRemote: true),
        child: notes.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: _buildEmptyState(
                    dark: dark,
                    title: 'No Notes Available',
                    subtitle: 'Notes for this subject will appear once added.',
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoteTile(
                      note: note,
                      onTap: () => controller.openNote(note),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _buildGradedNotesView(BuildContext context, bool dark) {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabs.length, (index) {
        final tab = _tabs[index];
        final grade = tab['grade'] as int;
        final isGeneral = grade == 0;

        return Obx(() {
          if (controller.isLoading.value && controller.subjectNotes.isEmpty) {
            return const AppCircularLoading(title: 'Loading notes...');
          }

          final notes = controller.getNotesByGrade(grade);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadSubjectNotes(forceRemote: true),
            child: notes.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: _buildEmptyState(
                        dark: dark,
                        title: isGeneral
                            ? 'No General Notes'
                            : 'No Notes for Grade $grade',
                        subtitle: isGeneral
                            ? 'Formulas, multi-grade summaries, and resources will appear here.'
                            : 'Chapter notes for Grade $grade are coming soon.',
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: notes.length,
                    itemBuilder: (context, itemIndex) {
                      final note = notes[itemIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NoteTile(
                          note: note,
                          onTap: () => controller.openNote(note),
                        ),
                      );
                    },
                  ),
          );
        });
      }),
    );
  }

  Widget _buildAppBarAction() {
    return Obx(() {
      final isCommon = controller.isCommon;
      final currentGrade = isCommon
          ? 0
          : (_tabs[_currentTabIndex.value]['grade'] as int);
      final gradeLabel = currentGrade == 0
          ? (isCommon ? 'Subject' : 'General')
          : 'Grade $currentGrade';

      final notes = isCommon
          ? controller.subjectNotes
          : controller.getNotesByGrade(currentGrade);

      if (notes.isEmpty) return const SizedBox.shrink();

      final totalCount = notes.length;
      final downloadedCount = notes.where((n) => n.isDownloaded).length;
      final allDownloaded = totalCount > 0 && downloadedCount == totalCount;
      final isBulkDownloading =
          controller.isGradeDownloading[currentGrade] ?? false;
      final isBusy = isBulkDownloading;
      final bulkProgress = controller.gradeDownloadProgress[currentGrade];

      if (isBusy) {
        final percent = (bulkProgress != null && bulkProgress > 0)
            ? (bulkProgress * 100).toInt()
            : null;

        return Tooltip(
          message: isBulkDownloading
              ? 'Downloading $gradeLabel notes (${percent ?? 0}%)\nTap to view progress or cancel'
              : 'Downloading note...',
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: isBulkDownloading
                    ? () => controller.showActiveDownloadProgressDialog()
                    : null,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: (bulkProgress != null && bulkProgress > 0)
                              ? bulkProgress
                              : null,
                          strokeWidth: 2.4,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      if (percent != null && percent > 0)
                        Text(
                          '$percent',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (allDownloaded) {
        return Container(
          margin: const EdgeInsets.only(right: 14),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Remove all $gradeLabel notes from device',
            onPressed: () => _confirmDeleteAllGradeNotes(
              context,
              currentGrade,
              gradeLabel,
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(right: 14),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: 'Download $gradeLabel notes ($downloadedCount/$totalCount)',
          onPressed: () => controller.downloadAllGradeNotes(currentGrade),
          icon: const Icon(
            Icons.download_for_offline_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    });
  }

  void _confirmDeleteAllGradeNotes(
    BuildContext context,
    int grade,
    String gradeLabel,
  ) {
    final dark = AppHelperFunctions.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.15 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.25 : 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Remove $gradeLabel Notes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.textWhite : AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This will remove all downloaded $gradeLabel notes from your device storage. You can re-download them anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dark ? AppColors.white : AppColors.textPrimary,
                            side: BorderSide(
                              color: dark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            controller.deleteAllGradeNotes(grade);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Remove All',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool dark,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ChallengeColors.accent
                    .withValues(alpha: dark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.document_text_copy,
                size: 40,
                color: ChallengeColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
