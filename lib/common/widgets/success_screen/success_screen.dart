import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/icons/circular_icon.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.title,
    required this.subTitle,
    required this.onPressed,
    this.buttonText = "Continue",
  });
  final String title, subTitle, buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularIcon(
                  icon: Icons.check,
                  color: Colors.green,
                  background: Colors.transparent,
                  iconWeight: FontWeight.w900,
                  borderColor: Colors.green,
                  size: 50,
                  radius: 100,
                ),
                const SizedBox(height: AppSizes.spaceBtwSections * 2),

                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),

                Text(
                  subTitle,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.spaceBtwSections * 2),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
