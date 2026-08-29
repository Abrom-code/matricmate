import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/appbar/sync_icon_button.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/entrance_subject_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> with RouteAware {
  SubjectsController get ctrl => SubjectsController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadPausedTests();
      if (mounted) {
        appRouteObserver.subscribe(this, ModalRoute.of(context)!);
      }
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => ctrl.loadPausedTests();

  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncingController>();
    final isDark = AppHelperFunctions.isDark(context);
    final userController = UserController.instance;

    return Scaffold(
      appBar: ModernAppbar(
        title: 'Exams',
        subtitle: 'Entrance & model exam papers',
        actions: [
          Obx(() {
            final syncing = syncController.entranceSyncing.value;
            return SyncIconButton(
              isSyncing: syncing,
              tooltip: 'Sync entrance exams',
              tooltipSyncing: 'Sync in progress…',
              onPressed: () => syncController.syncEntranceExams(),
            );
          }),
          // Paused tests (entrance + model only)
          Obx(() {
            final count = ctrl.filteredPausedTests
                .where((t) => t.testType == 'entrance' || t.testType == 'model')
                .length;
            if (count == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: '$count test${count == 1 ? '' : 's'} in progress',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(right: 8),
              onPressed: () => Get.toNamed(
                Routes.pausedTests,
                arguments: {
                  'types': ['entrance', 'model'],
                },
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 20,
                    color: AppColors.white,
                  ),
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final subjects = ctrl.filteredSubjects;
        final entranceNums = ctrl.entranceTestNumbers;
        final modelNums = ctrl.modelTestNumbers;
        final syncing = syncController.entranceSyncing.value;

        if (ctrl.isLoading.value && subjects.isEmpty) {
          return const AppCircularLoading(title: 'Loading subjects...');
        }

        if (subjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No exams yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the sync button above to fetch the latest past entrance papers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await syncController.syncEntranceExams();
                await ctrl.loadPausedTests();
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                itemCount: subjects.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Header row
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select a Subject',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Obx(() {
                                final stream = userController.user.value.stream;
                                final streamLabel = stream.isNotEmpty
                                    ? '${stream[0].toUpperCase()}${stream.substring(1)} Stream'
                                    : 'Grade 12';
                                return Text(
                                  '$streamLabel • ${subjects.length} subjects',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkGrey
                                        : AppColors.textSecondary,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  final subject = subjects[index - 1];
                  final entranceCount = entranceNums[subject.id] ?? 0;
                  final modelCount = modelNums[subject.id] ?? 0;

                  return EntranceSubjectTile(
                    subject: subject,
                    entranceCount: entranceCount,
                    modelCount: modelCount,
                    total: entranceCount + modelCount,
                  );
                },
              ),
            ),

            if (syncing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        );
      }),
    );
  }
}
