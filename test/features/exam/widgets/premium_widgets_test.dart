import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payement_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/pending_payment_banner.dart';
import 'package:matricmate/routes/app_routes.dart';

void main() {
  testWidgets(
    'payment tile exposes selection, recommendation, and tap behavior',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => paymentTile(
              context: context,
              title: 'Telebirr',
              subtitle: 'Pay with Telebirr',
              icon: Icons.payment,
              selected: true,
              isFeatured: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Telebirr'), findsOneWidget);
      expect(find.text('RECOMMENDED'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      await tester.tap(find.text('Telebirr'));
      expect(taps, 1);
    },
  );

  testWidgets('pending payment banner opens payment verification', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(
            name: Routes.paymentVerification,
            page: () => const Scaffold(body: Text('Verification screen')),
          ),
        ],
        home: const Scaffold(body: PendingPaymentBanner()),
      ),
    );

    expect(find.text('Payment Pending'), findsOneWidget);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Verification screen'), findsOneWidget);
  });
}
