import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';

void main() {
  group('Challenge Sorting Logic', () {
    final now = DateTime.now();

    // Challenge 1: Live, NOT completed
    final liveUncompleted = LeaderboardChallengeModel(
      id: 'c_live_uncompleted',
      setId: 'set_1',
      title: 'Live Math Challenge (Uncompleted)',
      subjectId: 1,
      audience: 'both',
      status: 'live',
      createdAt: now.subtract(const Duration(hours: 2)),
      startsAt: now.subtract(const Duration(hours: 1)),
      endsAt: now.add(const Duration(hours: 2)),
    );

    // Challenge 2: Live, closing very soon, NOT completed
    final liveClosingSoon = LeaderboardChallengeModel(
      id: 'c_live_closing_soon',
      setId: 'set_2',
      title: 'Live Physics Challenge (Closing Soon)',
      subjectId: 2,
      audience: 'both',
      status: 'live',
      createdAt: now.subtract(const Duration(hours: 3)),
      startsAt: now.subtract(const Duration(hours: 2)),
      endsAt: now.add(const Duration(minutes: 30)),
    );

    // Challenge 3: Scheduled (starts in 3 hours)
    final scheduledSoon = LeaderboardChallengeModel(
      id: 'c_sched_soon',
      setId: 'set_3',
      title: 'Scheduled Biology Challenge (Soon)',
      subjectId: 3,
      audience: 'both',
      status: 'scheduled',
      createdAt: now.subtract(const Duration(hours: 5)),
      startsAt: now.add(const Duration(hours: 3)),
      endsAt: now.add(const Duration(hours: 5)),
    );

    // Challenge 4: Scheduled (starts tomorrow)
    final scheduledLater = LeaderboardChallengeModel(
      id: 'c_sched_later',
      setId: 'set_4',
      title: 'Scheduled Chemistry Challenge (Later)',
      subjectId: 4,
      audience: 'both',
      status: 'scheduled',
      createdAt: now.subtract(const Duration(hours: 5)),
      startsAt: now.add(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 1, hours: 2)),
    );

    // Challenge 5: Live, but COMPLETED by user
    final liveCompleted = LeaderboardChallengeModel(
      id: 'c_live_completed',
      setId: 'set_5',
      title: 'Live English Challenge (Completed)',
      subjectId: 5,
      audience: 'both',
      status: 'live',
      createdAt: now.subtract(const Duration(hours: 4)),
      startsAt: now.subtract(const Duration(hours: 2)),
      endsAt: now.add(const Duration(hours: 4)),
    );

    // Mock completed IDs set
    final completedIds = {'c_live_completed'};

    bool isCompleted(LeaderboardChallengeModel c) {
      return completedIds.contains(c.id);
    }

    int challengePriority(LeaderboardChallengeModel c) {
      final done = isCompleted(c);
      if (c.isLive && !done) {
        return 0; // Live & not completed at top
      } else if (c.isScheduled) {
        return 1; // Scheduled next
      } else if (c.isLive && done) {
        return 2; // Live but already completed
      } else {
        return 3;
      }
    }

    List<LeaderboardChallengeModel> sortChallenges(List<LeaderboardChallengeModel> list) {
      final items = List<LeaderboardChallengeModel>.from(list);
      items.sort((a, b) {
        final pA = challengePriority(a);
        final pB = challengePriority(b);
        if (pA != pB) return pA.compareTo(pB);

        if (pA == 0) {
          if (a.endsAt != null && b.endsAt != null) {
            final cmp = a.endsAt!.compareTo(b.endsAt!);
            if (cmp != 0) return cmp;
          } else if (a.endsAt != null) {
            return -1;
          } else if (b.endsAt != null) {
            return 1;
          }
          if (a.startsAt != null && b.startsAt != null) {
            return a.startsAt!.compareTo(b.startsAt!);
          }
        } else if (pA == 1) {
          if (a.startsAt != null && b.startsAt != null) {
            final cmp = a.startsAt!.compareTo(b.startsAt!);
            if (cmp != 0) return cmp;
          } else if (a.startsAt != null) {
            return -1;
          } else if (b.startsAt != null) {
            return 1;
          }
        } else if (pA == 2) {
          if (a.endsAt != null && b.endsAt != null) {
            final cmp = a.endsAt!.compareTo(b.endsAt!);
            if (cmp != 0) return cmp;
          }
        }
        return 0;
      });
      return items;
    }

    test('places live & uncompleted at top, then scheduled, then live & completed', () {
      final List<LeaderboardChallengeModel> unsorted = [
        scheduledLater,
        liveCompleted,
        scheduledSoon,
        liveUncompleted,
        liveClosingSoon,
      ];

      final sorted = sortChallenges(unsorted);

      // Expected order:
      // 1. liveClosingSoon (Priority 0, ends in 30m)
      // 2. liveUncompleted (Priority 0, ends in 2h)
      // 3. scheduledSoon (Priority 1, starts in 3h)
      // 4. scheduledLater (Priority 1, starts in 1d)
      // 5. liveCompleted (Priority 2, already completed)
      expect(sorted.map((c) => c.id).toList(), [
        'c_live_closing_soon',
        'c_live_uncompleted',
        'c_sched_soon',
        'c_sched_later',
        'c_live_completed',
      ]);
    });

    test('all live uncompleted challenges come before any scheduled challenge', () {
      final List<LeaderboardChallengeModel> unsorted = [scheduledSoon, liveUncompleted];
      final sorted = sortChallenges(unsorted);
      expect(sorted.first.id, 'c_live_uncompleted');
      expect(sorted.last.id, 'c_sched_soon');
    });

    test('scheduled challenges come before completed live challenges', () {
      final List<LeaderboardChallengeModel> unsorted = [liveCompleted, scheduledSoon];
      final sorted = sortChallenges(unsorted);
      expect(sorted.first.id, 'c_sched_soon');
      expect(sorted.last.id, 'c_live_completed');
    });
  });
}
