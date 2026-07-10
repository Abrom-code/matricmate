import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/search_field.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends StatefulWidget {
  BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  void initState() {
    super.initState();
    // Clear search once when screen opens, not on every rebuild
    BookmarkController.instance.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final controller = BookmarkController.instance;

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Bookmarks',
        subtitleBuilder: (_) => Obx(() {
          final count = controller.bookmarkedQuestions.length;
          return Text(
            '$count ${count == 1 ? 'item' : 'items'} saved',
            style: const TextStyle(color: AppColors.white, fontSize: 12),
          );
        }),
      ),
      body: Obx(() {
        // Show loader only on initial load when list is empty
        if (controller.isLoading.value &&
            controller.bookmarkedQuestions.isEmpty) {
          return const AppCircularLoading(title: 'Loading...');
        }

        final tabs = controller.subjects;

        return DefaultTabController(
          key: ValueKey(tabs.length),
          length: tabs.length,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  floating: true,
                  backgroundColor: dark ? AppColors.darkCard : AppColors.white,
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
                    dividerColor: dark ? AppColors.darkCard : AppColors.white,
                    tabs: tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: tabs.map((subject) {
                final filtered = controller.getBySubject(subject);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No bookmark found'));
                }
                return Container(
                  margin: const EdgeInsets.all(AppSizes.defaultSpace / 2),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.spaceBtwItems),
                    itemBuilder: (_, index) {
                      final qn = filtered[index];
                      return BookmarkContainer(qn: qn);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }
}
