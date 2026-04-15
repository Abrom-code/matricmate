import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    return TextFormField(
      onTapOutside: (e) => FocusScope.of(context).unfocus(),
      onChanged: (value) {
        BookmarkController.instance.searchQuery.value = value;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        border: buildBorder(Colors.grey),
        enabledBorder: buildBorder(
          dark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
        focusedBorder: buildBorder(AppColors.primary),
        hintText: "Search Bookmarked topics...",
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  OutlineInputBorder buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}
