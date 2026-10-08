import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/screens/profile/about_screen.dart';
import 'package:matricmate/features/personalization/screens/profile/widgets/legal_about_section.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('LegalAboutSection widget tests', () {
    testWidgets('Displays only About MatricET tile and omits Privacy/Licenses',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: LegalAboutSection(),
          ),
        ),
      );

      // Verify "About MatricET" is shown
      expect(find.text('About ${ProfileActionsHelper.appName}'), findsOneWidget);
      expect(find.textContaining('Version 1.0.4'), findsOneWidget);

      // Verify "Privacy Policy" and "Open Source Licenses" are NOT directly on profile section
      expect(find.text('Privacy Policy'), findsNothing);
      expect(find.text('Open Source Licenses'), findsNothing);
    });
  });

  group('AboutScreen widget tests', () {
    testWidgets('Renders hero, features, streams, and legal disclosures at bottom',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AboutScreen(),
        ),
      );

      // App title and version
      expect(find.text(ProfileActionsHelper.appName), findsWidgets);
      expect(find.text('v1.0.4'), findsOneWidget);

      // Bento Feature cards
      expect(find.text('Matric Simulator'), findsOneWidget);
      expect(find.text('Chapter Tests'), findsOneWidget);
      expect(find.text('Study Notes'), findsOneWidget);
      expect(find.text('LaTeX Math'), findsOneWidget);
      expect(find.text('Daily Streaks'), findsOneWidget);
      expect(find.text('100% Offline'), findsOneWidget);

      // Educational streams
      expect(find.text('Natural Science'), findsOneWidget);
      expect(find.text('Social Science'), findsOneWidget);

      // Legal & disclosures at the bottom
      expect(find.text('LEGAL & DISCLOSURES'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Open Source'), findsOneWidget);
    });
  });
}
