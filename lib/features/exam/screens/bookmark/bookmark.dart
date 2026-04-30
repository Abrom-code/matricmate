import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/search_field.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/app_drawer.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends GetView<BookmarkController> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    controller.clearSearch();

    return Obx(() {
      final tabs = controller.subjects;
      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          key: scaffoldKey,
          drawer: AppDrawer(),
          appBar: Appbar(
            leadingIcon: Icons.menu,
            leadingOnPressed: () {
              scaffoldKey.currentState!.openDrawer();
            },
            title: Text("Bookmarks", style: TextStyle(color: AppColors.white)),
          ),
          body: Obx(() {
            if (UserController.instance.userFetching.value) {
              return AppCircularLoading(title: 'Loading...');
            }

            return NestedScrollView(
              headerSliverBuilder: (_, innerBoxScrolled) {
                return [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: true,
                    floating: true,
                    backgroundColor: dark ? AppColors.black : AppColors.white,
                    expandedHeight: 130,
                    flexibleSpace: Padding(
                      padding: EdgeInsets.all(AppSizes.defaultSpace),
                      child: SearchField(),
                    ),
                    bottom: TabBar(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.defaultSpace / 2,
                      ),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerHeight: 50,
                      dividerColor: dark ? AppColors.black : Colors.white,
                      tabs: tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ];
              },

              body: TabBarView(
                children: controller.subjects.map((subject) {
                  return Obx(() {
                    final filtered = controller.getBySubject(subject);
                    if (controller.isLodaing.value)
                      return AppCircularLoading(title: "Loading...");
                    if (filtered.isEmpty) {
                      return Center(child: Text("No bookmark found"));
                    }

                    return Container(
                      margin: EdgeInsets.all(AppSizes.defaultSpace / 2),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: AppSizes.spaceBtwItems),
                        itemBuilder: (_, index) {
                          final qn = filtered[index];
                          return BookmarkContainer(qn: qn);
                        },
                      ),
                    );
                  });
                }).toList(),
              ),
            );
          }),
        ),
      );
    });
  }
}
