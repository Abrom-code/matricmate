import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/screens/widgets/archive_challenge_card.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_empty_states.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_subject_filter_bar.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengeArchiveScreen extends StatefulWidget {
  const ChallengeArchiveScreen({
    super.key,
    this.subjectId,
    this.subjectTitle,
  });

  final int? subjectId;
  final String? subjectTitle;

  @override
  State<ChallengeArchiveScreen> createState() => _ChallengeArchiveScreenState();
}

class _ChallengeArchiveScreenState extends State<ChallengeArchiveScreen> {
  late final ChallengeArchiveController _ctrl;
  final _tag = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      ChallengeArchiveController(
        subjectId: widget.subjectId,
        subjectTitle: widget.subjectTitle,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<ChallengeArchiveController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_ctrl.selectedSubjectTitle)),
        actions: [
          Obx(() {
            if (_ctrl.isManualRefreshing.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: AppCircularButtonLoading(color: AppColors.primary),
                ),
              );
            }
            return IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _ctrl.manualRefresh(),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.challenges.isEmpty) {
          return const AppCircularLoading(
            title: 'Loading challenges...',
          );
        }

        final displayed = _ctrl.displayedChallenges;
        final subjects = _ctrl.studentSubjects;

        return Column(
          children: [
            // ── Horizontal Subject Filter Chips ───────────────────────────
            ChallengeSubjectFilterBar(
              ctrl: _ctrl,
              dark: dark,
              subjects: subjects,
            ),

            // ── Main Challenges List / Empty State ────────────────────────
            Expanded(
              child: displayed.isEmpty
                  ? RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _ctrl.manualRefresh(),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: _ctrl.isOffline.value
                                  ? ChallengeOfflineState(
                                      dark: dark,
                                      isRefreshing:
                                          _ctrl.isManualRefreshing.value,
                                      onRefresh: () => _ctrl.manualRefresh(),
                                      title: 'No Offline Challenges',
                                      subtitle:
                                          'You are offline and have no downloaded challenges for this subject.\nConnect to the internet and tap refresh.',
                                    )
                                  : ChallengeEmptyState(
                                      title:
                                          'No ${_ctrl.selectedSubjectTitle} Available',
                                      subtitle:
                                          'New rounds and archive challenges will appear here for practice and review.',
                                      dark: dark,
                                      icon: Iconsax.archive_book_copy,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _ctrl.manualRefresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount:
                            displayed.length + (_ctrl.isOffline.value ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSizes.spaceBtwItems),
                        itemBuilder: (context, idx) {
                          if (_ctrl.isOffline.value && idx == 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_off_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Offline mode: Showing ${displayed.length} downloaded challenge(s).',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final actualIndex =
                              _ctrl.isOffline.value ? idx - 1 : idx;
                          final challenge = displayed[actualIndex];

                          return ArchiveChallengeCard(
                            challenge: challenge,
                            ctrl: _ctrl,
                            dark: dark,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
