import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/appbar/status_title.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final subjectController = SubjectsController.instance;
    final syncController = Get.find<SyncingController>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: Appbar(
        title: const AppbarStatusTitle(title: 'MatricMate'),
        leadingIcon: Icons.menu,
        leadingOnPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.defaultSpace / 2),
            child: IconButton(
              onPressed: () => subjectController.syncAll(),
              icon: const Icon(
                Icons.loop,
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
          return const AppCircularLoading(title: 'Loading...');
        }

        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;

        final filteredSubjects = subjectController.filteredSubjects;

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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.loop),
                        SizedBox(width: AppSizes.sm),
                        Text(
                          'Check Payment Status',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
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
                      image: AppHelperFunctions.getSubjectImage(subject.name),
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
