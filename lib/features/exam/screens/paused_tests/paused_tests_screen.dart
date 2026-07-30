import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/paused_test_info.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class PausedTestsScreen extends StatefulWidget {
  const PausedTestsScreen({super.key});

  @override
  State<PausedTestsScreen> createState() => _PausedTestsScreenState();
}

class _PausedTestsScreenState extends State<PausedTestsScreen> {
  SubjectsController get ctrl => SubjectsController.instance;

  @override
  void initState() {
    super.initState();
    ctrl.loadPausedTests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Paused Tests',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: Obx(() {
        final tests = ctrl.pausedTests;

        if (tests.isEmpty) {
          return const Center(child: Text('No paused tests'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          itemCount: tests.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.spaceBtwItems),
          itemBuilder: (_, i) => _PausedTestTile(info: tests[i]),
        );
      }),
    );
  }
}

class _PausedTestTile extends StatelessWidget {
  const _PausedTestTile({required this.info});
  final PausedTestInfo info;

  static const _accent = Colors.indigo;

  String _typeLabel(String t) {
    switch (t) {
      case 'entrance':
        return 'Entrance';
      case 'model':
        return 'Model';
      case 'chapter':
        return 'Chapter';
      case 'grade':
        return 'Grade';
      default:
        return t.isEmpty ? 'Unknown' : t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final draft = info.result;
    final total = draft.testQuestions.length;
    final answered = draft.selectedAnswers.length;
    final progress = total > 0 ? answered / total : 0.0;
    final pct = (progress * 100).round();

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.dialog(
          ReadyDialog(
            qnCount: total,
            time: info.testTime,
            testId: draft.testId,
            id: -1,
            draft: draft,
            examTitle: info.testType == 'entrance' ? info.testTitle : null,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.pause_circle_filled_rounded,
                color: _accent,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.testTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${info.subjectName} · ${_typeLabel(info.testType)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: _accent.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$answered of $total answered',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
