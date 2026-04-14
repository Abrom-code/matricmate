import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/search_field.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends GetView<BookmarkController> {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Obx(() {
      final tabs = controller.subjects;
      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: Appbar(
            title: Text("Bookmarks", style: TextStyle(color: AppColors.white)),
            centerTitle: true,
          ),
          body: NestedScrollView(
            headerSliverBuilder: (_, innerBoxScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: dark ? AppColors.black : AppColors.white,
                  expandedHeight: 150,
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
                final filtered = controller.getBySubject(subject);

                return Container(
                  margin: EdgeInsets.all(AppSizes.defaultSpace / 2),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_,_) => Divider(),
                    itemBuilder: (_, index) {
                      final qn = filtered[index];

                      return BookmarkContainer(qn: qn);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }
}
