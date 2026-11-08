import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';

void main() {
  testWidgets('AppExplanationBox hides language toggle when only English explanation is present', (tester) async {
    final languageSelected = 'EN'.obs;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppExplanationBox(
            explanationEn: 'Photosynthesis occurs in chloroplasts.',
            explanationAm: 'No Amharic Explanation!',
            expanded: true,
            onToggle: () {},
            languageSelected: languageSelected,
            onLanguageChange: (v) => languageSelected.value = v,
          ),
        ),
      ),
    );

    // Header has Explanation title
    expect(find.text('Explanation'), findsOneWidget);

    // Language pills ('En', 'አማ') should NOT exist because Amharic is not available
    expect(find.text('En'), findsNothing);
    expect(find.text('አማ'), findsNothing);

    // English explanation is rendered
    expect(find.textContaining('Photosynthesis occurs in chloroplasts'), findsOneWidget);
  });

  testWidgets('AppExplanationBox displays English text even if languageSelected is AM when Amharic is missing', (tester) async {
    final languageSelected = 'AM'.obs;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppExplanationBox(
            explanationEn: 'Mitochondria is the powerhouse of the cell.',
            explanationAm: '',
            expanded: true,
            onToggle: () {},
            languageSelected: languageSelected,
            onLanguageChange: (v) => languageSelected.value = v,
          ),
        ),
      ),
    );

    // Toggle should be hidden
    expect(find.text('En'), findsNothing);
    expect(find.text('አማ'), findsNothing);

    // English text should be shown, not blank or placeholder
    expect(find.textContaining('Mitochondria is the powerhouse'), findsOneWidget);
  });

  testWidgets('AppExplanationBox shows toggle when both English and Amharic explanations are present', (tester) async {
    final languageSelected = 'EN'.obs;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppExplanationBox(
            explanationEn: 'Oxygen is transported by red blood cells.',
            explanationAm: 'ኦክስጅን በቀይ የደም ሴሎች ይጓጓዛል።',
            expanded: true,
            onToggle: () {},
            languageSelected: languageSelected,
            onLanguageChange: (v) => languageSelected.value = v,
          ),
        ),
      ),
    );

    // Toggle should be visible
    expect(find.text('En'), findsOneWidget);
    expect(find.text('አማ'), findsOneWidget);

    // Initially English is shown
    expect(find.textContaining('Oxygen is transported'), findsOneWidget);

    // Tap Amharic pill
    await tester.tap(find.text('አማ'));
    await tester.pumpAndSettle();

    expect(languageSelected.value, 'AM');
    expect(find.textContaining('ኦክስጅን በቀይ የደም ሴሎች'), findsOneWidget);

    // Tap English pill
    await tester.tap(find.text('En'));
    await tester.pumpAndSettle();

    expect(languageSelected.value, 'EN');
    expect(find.textContaining('Oxygen is transported'), findsOneWidget);
  });
}

