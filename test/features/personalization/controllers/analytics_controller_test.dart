import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';

void main() {
  group('AnalyticsController filter state', () {
    late AnalyticsController controller;

    setUp(() {
      controller = AnalyticsController(databaseService: DatabaseService());
    });

    test('starts with no active filters', () {
      expect(controller.activeFilterCount, 0);
      expect(controller.hasActiveFilters, isFalse);
    });

    test('counts each changed filter once', () {
      controller.selectedSubject.value = 'Physics';
      controller.selectedTestType.value = 'Entrance';
      controller.selectedTimeFilter.value = TimeFilter.lastMonth;
      controller.selectedGrade.value = GradeFilter.grade12;
      controller.selectedStream.value = StreamFilter.natural;
      controller.selectedScore.value = ScoreFilter.good;
      controller.selectedTimed.value = TimedFilter.timedOnly;

      expect(controller.activeFilterCount, 7);
      expect(controller.hasActiveFilters, isTrue);
    });
  });
}
