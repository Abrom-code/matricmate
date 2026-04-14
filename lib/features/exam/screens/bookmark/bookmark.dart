import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/search_field.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final qnText =
        "Test exam question this is test exam what ohohihs ihois of hwhiothiwh o shfo aiheo oahog a hihgoiweoho ohwihihow ohowh fos Test exam question this is test exam what ohohihs ihois of hwhiothiwh o shfo aiheo oahog a hihgoiweoho ohwihihow ohowh fos Test exam question this is test exam what ohohihs ihois of hwhiothiwh o shfo aiheo oahog a hihgoiweoho ohwihihow ohowh fos";
    return DefaultTabController(
      length: 7,
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
                  tabs: [
                    Tab(text: "All"),
                    Tab(text: "English"),
                    Tab(text: "Maths"),
                    Tab(text: "Chemistry"),
                    Tab(text: "Biology"),
                    Tab(text: "Physics"),
                    Tab(text: "SAT"),
                  ],
                ),
              ),
            ];
          },
          body: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
            child: TabBarView(
              children: [
                ListView.separated(
                  itemBuilder: (_, index) {
                    return BookmarkContainer(qnText: qnText);
                  },
                  separatorBuilder: (_, index) {
                    return Divider();
                  },
                  itemCount: 10,
                ),
                Container(color: Colors.blue),
                Container(color: Colors.green),
                Container(color: Colors.green),
                Container(color: Colors.green),
                Container(color: Colors.green),
                Container(color: Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
