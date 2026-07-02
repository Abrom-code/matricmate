import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/tiles/tile.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class EntranceScreen extends StatelessWidget {
  EntranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SubjectsController.instance;

    return Scaffold(
      appBar: Appbar(
        title: Text(
          'Exams',
          style: Theme.of(context).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: Obx(() {
        if (UserController.instance.userFetching.value ||
            controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading...');
        }

        final subjects = controller.filteredSubjects;

        if (subjects.isEmpty) {
          return const Center(
            child: Text(
              'No subjects yet.\nTap the sync button on the home screen.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          itemCount: subjects.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.spaceBtwItems),
          itemBuilder: (_, index) {
            final subject = subjects[index];
            final entranceCount =
                controller.entranceTestNumbers[subject.id] ?? 0;
            final modelCount =
                controller.modelTestNumbers[subject.id] ?? 0;
            final total = entranceCount + modelCount;

            return AppTile(
              icon: Iconsax.book_square_copy,
              title: subject.name,
              subTitle: Text(
                total > 0
                    ? '$entranceCount entrance · $modelCount model exams'
                    : 'No exams added yet',
                style: TextStyle(
                  color: total > 0 ? null : Colors.grey,
                ),
              ),
              onTap: () => Get.toNamed(
                Routes.entranceExams,
                arguments: {
                  'subject_id': subject.id,
                  'subject': subject.name,
                },
              ),
            );
          },
        );
      }),
    );
  }
}
