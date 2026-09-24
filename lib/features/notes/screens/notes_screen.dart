import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      if (notes.isEmpty) {
        return _buildEmptyState(
          dark: dark,
          title: 'No Notes Available',
          subtitle: 'Notes for this subject will appear once added.',
        );
      }

      return ListView.builder(
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

          if (notes.isEmpty) {
            return _buildEmptyState(
              dark: dark,
              title:
                  isGeneral ? 'No General Notes' : 'No Notes for Grade $grade',
              subtitle: isGeneral
                  ? 'Formulas, multi-grade summaries, and resources will appear here.'
                  : 'Chapter notes for Grade $grade are coming soon.',
            );
          }

          final totalCount = notes.length;
          final downloadedCount = notes.where((n) => n.isDownloaded).length;
          final allDownloaded = downloadedCount == totalCount;
          final isBulkDownloading =
              controller.isGradeDownloading[grade] ?? false;
          final bulkProgress = controller.gradeDownloadProgress[grade];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: notes.length + 1,
            itemBuilder: (context, itemIndex) {
              // Top item: Bulk download banner
              if (itemIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildGradeBulkBanner(
                    context: context,
                    dark: dark,
                    grade: grade,
                    totalCount: totalCount,
                    downloadedCount: downloadedCount,
                    allDownloaded: allDownloaded,
                    isBulkDownloading: isBulkDownloading,
                    bulkProgress: bulkProgress,
                  ),
                );
              }

              final note = notes[itemIndex - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoteTile(
                  note: note,
                  onTap: () => controller.openNote(note),
                ),
              );
            },
          );
        });
      }),
    );
  }

  Widget _buildGradeBulkBanner({
    required BuildContext context,
    required bool dark,
    required int grade,
    required int totalCount,
    required int downloadedCount,
    required bool allDownloaded,
    required bool isBulkDownloading,
    required double? bulkProgress,
  }) {
    final isGeneral = grade == 0;
    final label = isGeneral ? 'General' : 'Grade $grade';

    if (allDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: dark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All $label Notes Downloaded • Ready for Offline Study',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isBulkDownloading
              ? null
              : () => controller.downloadAllGradeNotes(grade),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6)
                        .withValues(alpha: dark ? 0.25 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isBulkDownloading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              value: bulkProgress,
                              strokeWidth: 2,
                              color: const Color(0xFF8B5CF6),
                            ),
                          )
                        : const Icon(
                            Icons.download_rounded,
                            color: Color(0xFF8B5CF6),
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
                        isBulkDownloading
                            ? 'Downloading $label Notes...'
                            : 'Download All $label Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: dark ? AppColors.white : const Color(0xFF4C1D95),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBulkDownloading && bulkProgress != null
                            ? '${(bulkProgress * 100).toInt()}% completed'
                            : '$downloadedCount of $totalCount saved on device',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkGrey
                              : const Color(0xFF6D28D9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isBulkDownloading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Download All',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: dark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.document_text_copy,
                size: 40,
                color: Color(0xFF8B5CF6),
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
