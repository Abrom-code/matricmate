import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/buttons/drop_down_button.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/screens/chapter/chapter.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectController = SubjectsController.instance;
    return Scaffold(
      appBar: Appbar(
        title: Text(
          "MatricMate",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
        leadingIcon: Icons.menu,
        leadingOnPressed: () {},
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.defaultSpace / 2),
            child: IconButton(
              onPressed: () => subjectController.syncSubjects(),
              icon: Icon(
                Icons.refresh,
                size: AppSizes.iconMd * 1.2,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Obx(() {
            final isNaturalStream =
                subjectController.selectedStream.value == "natural";

            final filteredSubjects = subjectController.subjects.where((
              subject,
            ) {
              return subject.isCommon || subject.isNatural == isNaturalStream;
            }).toList();

            if (subjectController.isLoading.value ||
                subjectController.isRefreshing.value) {
              return CircularProgressIndicator();
            } else {
              return Column(
                children: [
                  AppDropDownField(
                    items: [
                      DropdownMenuItem(
                        value: "natural",
                        child: Text(
                          "Natural",
                          style: Theme.of(context).textTheme.titleSmall!.apply(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "social",
                        child: Text(
                          "Social",
                          style: Theme.of(context).textTheme.titleSmall!.apply(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    icon: Icons.book,
                    onChanged: (stream) =>
                        subjectController.selectedStream.value = stream,
                    initialValue: subjectController.selectedStream.value,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  GridLayout(
                    itemCount: filteredSubjects.length,
                    itemBuilder: (_, index) {
                      final subject = filteredSubjects[index];

                      return Obx(
                        () => SubjectContainer(
                          title: subject.name,
                          image: AppHelperFuntions.getSubjectImage(
                            subject.name,
                          ),
                          isDownloaded: subject.isDownloaded,
                          isDownloading:
                              subjectController.downloadingMap[subject.name] ??
                              false,
                          onPressed: () =>
                              subjectController.downloadSubject(subject.name),
                          onTap: () => subject.isDownloaded
                              ? Get.to(() => ChapterScreen(title: subject.name))
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          }),
        ),
      ),
    );
  }
}
