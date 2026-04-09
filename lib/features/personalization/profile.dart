import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(appBar: Appbar(title: Text("Profile"), showBackArrow: true,),);
  }
}