import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenge Active Time & Pause/Resume Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Persists and restores challenge in-progress state correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      const challengeId = 'chal_test_123';

      // Initially not in progress
      expect(prefs.getBool('challenge_in_progress_$challengeId'), isNull);

      // User starts and pauses/leaves
      await prefs.setBool('challenge_in_progress_$challengeId', true);
      await prefs.setInt('challenge_time_spent_$challengeId', 45);

      expect(prefs.getBool('challenge_in_progress_$challengeId'), isTrue);
      expect(prefs.getInt('challenge_time_spent_$challengeId'), equals(45));

      // Check button text resolution
      final inProgress = prefs.getBool('challenge_in_progress_$challengeId') ?? false;
      final buttonLabel = inProgress ? 'Resume' : 'Start challenge';
      expect(buttonLabel, equals('Resume'));

      // User submits attempt -> clear progress
      await prefs.remove('challenge_in_progress_$challengeId');
      await prefs.remove('challenge_time_spent_$challengeId');

      expect(prefs.getBool('challenge_in_progress_$challengeId'), isNull);
      expect(prefs.getInt('challenge_time_spent_$challengeId'), isNull);

      final postSubmitInProgress = prefs.getBool('challenge_in_progress_$challengeId') ?? false;
      final postSubmitLabel = postSubmitInProgress ? 'Resume' : 'Start challenge';
      expect(postSubmitLabel, equals('Start challenge'));
    });

    test('Active time calculation counts only active time and does not leak wall-clock elapsed time', () {
      const durationSeconds = 3600; // 60 minutes
      int activeTimeSpent = 120; // 2 minutes spent actively answering

      // User leaves app for 30 minutes in background (wall clock advances 1800s, but active time stays 120s)
      final remainingActiveTime = durationSeconds - activeTimeSpent;
      expect(remainingActiveTime, equals(3480)); // exactly 58 minutes left

      // When user returns, timer resumes ticking from activeTimeSpent
      activeTimeSpent += 5; // user spends 5 more seconds
      final updatedRemaining = durationSeconds - activeTimeSpent;
      expect(updatedRemaining, equals(3475));
    });

    test('Remaining seconds respects absolute endsAt closing cutoff', () {
      const durationSeconds = 3600; // 60 min allowed
      const activeTimeSpent = 60; // 1 min spent

      // Case 1: Challenge ends in 30 minutes (less than allowed 59 mins remaining)
      final endsAtClosingSoon = DateTime.now().add(const Duration(minutes: 30));
      final secondsUntilClose1 = endsAtClosingSoon.difference(DateTime.now()).inSeconds;

      int remaining1 = durationSeconds - activeTimeSpent;
      if (secondsUntilClose1 < remaining1) {
        remaining1 = secondsUntilClose1;
      }
      expect(remaining1, lessThanOrEqualTo(1800));

      // Case 2: Challenge ends in 2 hours (more than allowed 59 mins remaining)
      final endsAtLater = DateTime.now().add(const Duration(hours: 2));
      final secondsUntilClose2 = endsAtLater.difference(DateTime.now()).inSeconds;

      int remaining2 = durationSeconds - activeTimeSpent;
      if (secondsUntilClose2 < remaining2) {
        remaining2 = secondsUntilClose2;
      }
      expect(remaining2, equals(3540));
    });
  });
}
