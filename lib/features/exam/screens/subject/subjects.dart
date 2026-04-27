import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/appbar/status_title.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/app_drawer.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectController = SubjectsController.instance;
    final syncController = Get.put(SyncingController());

    return Scaffold(
      key: subjectController.scaffoldKey,
      drawer: AppDrawer(),
      appBar: Appbar(
        title: AppbarStatusTitle(title: "MatricMate"),
        leadingIcon: Icons.menu,
        leadingOnPressed: () {
          subjectController.scaffoldKey.currentState!.openDrawer();
        },
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.defaultSpace / 2),
            child: IconButton(
              onPressed: () => syncController.syncAll(),
              icon: Icon(
                Icons.refresh,
                size: AppSizes.iconMd * 1.2,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (UserController.instance.userFetching.value ||
            subjectController.isLoading.value ||
            syncController.refreshing.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSizes.spaceBtwItems),
                Text('Loading...'),
              ],
            ),
          );
        }

        final isNaturalStream =
            subjectController.selectedStream.value == "natural";
        final filteredSubjects = subjectController.subjects.where((subject) {
          return subject.isCommon || subject.isNatural == isNaturalStream;
        }).toList();
        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                if (isInactive)
                  PremiumBanner(
                    onTap: () {
                      Get.bottomSheet(
                        const PremiumBottomSheet(),
                        isScrollControlled: true,
                      );
                    },
                  ),
                if (isInactive) const SizedBox(height: AppSizes.spaceBtwItems),

                if (isPending)
                  TextButton(
                    onPressed: () {
                      Get.to(() => const PaymentVerificationScreen());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Check Payment Status",
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Icon(Icons.call_made),
                      ],
                    ),
                  ),
                if (isPending) const SizedBox(height: AppSizes.spaceBtwItems),
                GridLayout(
                  itemCount: filteredSubjects.length,
                  itemBuilder: (_, index) {
                    final subject = filteredSubjects[index];

                    return SubjectContainer(
                      title: subject.name,
                      image: AppHelperFuntions.getSubjectImage(subject.name),
                      isDownloaded: subject.isDownloaded,
                      onPressed: () => subjectController.downloadSubject(
                        subject.name,
                        subject.id,
                      ),
                      onTap: () => subject.isDownloaded
                          ? Get.toNamed(
                              Routes.chapter,
                              arguments: {
                                'title': subject.name,
                                'id': subject.id,
                              },
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
