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

    test('resetFilters resets all active filter counts back to 0', () {
      controller.selectedSubject.value = 'Physics';
      controller.selectedTestType.value = 'Entrance';
      controller.selectedTimeFilter.value = TimeFilter.lastMonth;

      expect(controller.hasActiveFilters, isTrue);

      controller.selectedSubject.value = 'All Subjects';
      controller.selectedTestType.value = 'All Categories';
      controller.selectedTimeFilter.value = TimeFilter.all;

      expect(controller.activeFilterCount, 0);
      expect(controller.hasActiveFilters, isFalse);
    });

    test('holisticReadiness returns 0 when no tests and notes are completed', () {
      controller.testsCompleted.value = 0;
      controller.completedNotesCount.value = 0;
      expect(controller.holisticReadiness, 0.0);
    });
  });
}
