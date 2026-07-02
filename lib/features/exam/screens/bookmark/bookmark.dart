import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/search_field.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends GetView<BookmarkController> {
  BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    controller.clearSearch();

    final tabs = controller.subjects;

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: ModernAppbarWithBuilder(
          title: 'Bookmarks',
          subtitleBuilder: (_) => Obx(() {
            final count = controller.bookmarkedQuestions.length;
            return Text(
              '$count ${count == 1 ? 'item' : 'items'} saved',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            );
          }),
        ),
        body: Obx(() {
          if (UserController.instance.userFetching.value) {
            return const AppCircularLoading(title: 'Loading...');
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
                  flexibleSpace: const Padding(
                    padding: EdgeInsets.all(AppSizes.defaultSpace),
                    child: SearchField(),
                  ),
                  bottom: TabBar(
                    padding: const EdgeInsets.symmetric(
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
              children: tabs.map((subject) {
                return Obx(() {
                  final filtered = controller.getBySubject(subject);
                  if (controller.isLoading.value) {
                    return const AppCircularLoading(title: 'Loading...');
                  }
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No bookmark found'));
                  }

                  return Container(
                    margin: const EdgeInsets.all(AppSizes.defaultSpace / 2),
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.spaceBtwItems),
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
  }
}
