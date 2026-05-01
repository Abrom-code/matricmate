import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/tiles/tile.dart';
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

    return Scaffold(
      key: scaffoldKey,
      drawer: AppDrawer(),
      appBar: Appbar(
        leadingIcon: Icons.menu,
        leadingOnPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        title: Text(
          "Entrance Exams",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spaceBtwItems),
        child: Obx(() {
          if (UserController.instance.userFetching.value ||
              controller.isLoading.value) {
            return AppCircularLoading(title: 'Loading...');
          }

          final isNaturalStream = controller.selectedStream.value == "natural";
          final filteredSubjects = controller.subjects.where((subject) {
            return subject.isCommon || subject.isNatural == isNaturalStream;
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...filteredSubjects.map((subject) {
                final examNums = controller.testNumbers[subject.id];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.spaceBtwItems,
                  ),
                  child: AppTile(
                    icon: Iconsax.book_square_copy,
                    title: subject.name,
                    subTitle: Text(
                      "${examNums != 0 ? examNums : 'No'} entrance exams",
                    ),
                    onTap: () {
                      if (examNums != 0) {
                        Get.toNamed(
                          Routes.testLists,
                          arguments: {
                            'subject_id': subject.id,
                            'subject': subject.name,
                          },
                        );
                      } else {
                        ToastHelper.info(
                          "No Exams Added",
                          "Exams will be added soon!",
                        );
                      }
                      ;
                    },
                  ),
                );
              }),
              const SizedBox(height: AppSizes.spaceBtwSections),
            ],
          );
        }),
      ),
    );
  }
}
