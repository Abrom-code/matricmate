import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/tiles/tile.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/app_drawer.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class EntranceScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  EntranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubjectsController>();
    final tabController = Get.find<ExamSelectionController>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: Appbar(
        leadingIcon: Icons.menu,
        leadingOnPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        title: Text(
          'Exams',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.defaultSpace,
            ),
            child: TabBar(
              tabAlignment: TabAlignment.fill,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              controller: tabController.tabController,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: tabController.tabs
                  .map((t) => Tab(text: t['label']))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: tabController.tabController,
              children: List.generate(tabController.tabs.length, (index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceBtwItems,
                  ),
                  child: Obx(() {
                    if (UserController.instance.userFetching.value ||
                        controller.isLoading.value) {
                      return const AppCircularLoading(title: 'Loading...');
                    }

                    final filteredSubjects = controller.filteredSubjects;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...filteredSubjects.map((subject) {
                          final examNums = index == 0
                              ? controller.entranceTestNumbers[subject.id]
                              : controller.modelTestNumbers[subject.id];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.spaceBtwItems,
                            ),
                            child: AppTile(
                              icon: Iconsax.book_square_copy,
                              title: subject.name,
                              subTitle: Text(
                                "${examNums != 0 ? examNums : 'No'} ${index == 0 ? 'entrance' : 'model'} exams",
                              ),
                              onTap: () {
                                if (examNums != 0) {
                                  Get.toNamed(
                                    Routes.entranceExams,
                                    arguments: {
                                      'subject_id': subject.id,
                                      'subject': subject.name,
                                      'type': index == 0 ? 'entrance' : 'model',
                                    },
                                  );
                                } else {
                                  ToastHelper.info('No Exams Added');
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: AppSizes.spaceBtwSections),
                      ],
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
