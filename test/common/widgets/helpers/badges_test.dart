import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/common/widgets/helpers/badges.dart';

void main() {
  group('ExamBadgeHelper', () {
    test('maps score boundaries to the expected achievement', () {
      expect(ExamBadgeHelper.getBadge(0.9).label, 'Top Scorer');
      expect(ExamBadgeHelper.getBadge(0.8).label, 'Distinction');
      expect(ExamBadgeHelper.getBadge(0.7).label, 'Excellent');
      expect(ExamBadgeHelper.getBadge(0.6).label, 'Very Good');
      expect(ExamBadgeHelper.getBadge(0.59).label, 'Good');
    });

    test('clamps scores outside the valid range', () {
      expect(ExamBadgeHelper.getBadge(2).icon, Icons.emoji_events);
      expect(ExamBadgeHelper.getBadge(-1).color, Colors.grey);
    });
  });
}
