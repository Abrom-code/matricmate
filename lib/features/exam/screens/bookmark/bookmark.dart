import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(title: Text("Bookmarks"), showBackArrow: true),
    );
  }
}
