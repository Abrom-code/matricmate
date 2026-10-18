import 'package:get/get.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class LeaderboardController extends GetxController {
  LeaderboardController({this.challengeId, this.audience}) {
    final userStream = UserController.instance.user.value.stream.toLowerCase().trim();
    activeStream.value = userStream.isNotEmpty ? userStream : 'natural';

    if (challengeId != null && challengeId!.isNotEmpty) {
      activeTab.value = 'challenge';
    } else {
      activeTab.value = 'weekly';
    }
  }

  final String? challengeId;
  final String? audience;
  final _repo = ChallengeRepository();

  final isLoading = false.obs;
  final isManualRefreshing = false.obs;
  final activeTab = 'challenge'.obs; // 'challenge', 'weekly', 'monthly', 'yearly'
  final activeStream = 'natural'.obs; // Locked to student's stream
  final entries = <ChallengeLeaderboardEntry>[].obs;
  final displayLimit = 10.obs;

  /// The user's personal standing, fetched separately when not in top entries.
  final Rxn<ChallengeLeaderboardEntry> _userStanding = Rxn<ChallengeLeaderboardEntry>();

  static const _initialFetchLimit = 10;

  final RxBool hasMore = false.obs;
  final RxBool isLoadingMore = false.obs;

  List<ChallengeLeaderboardEntry> get displayedEntries {
    if (activeTab.value != 'challenge') {
      return entries.take(10).toList();
    }
    return entries.toList();
  }

  Future<void> loadMore() async {
    // Only 'challenge' tab allows loading more than 10.
    // Weekly, monthly, and yearly are strictly capped at top 10.
    if (activeTab.value != 'challenge') {
      hasMore.value = false;
      return;
    }
    if (isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final requestedLimit = entries.length + 10;
      List<ChallengeLeaderboardEntry> moreEntries;

      if (activeTab.value == 'challenge' && challengeId != null) {
        final aud = audience?.toLowerCase().trim();
        final filterStream = (aud == null || aud.isEmpty || aud == 'both')
            ? null
            : aud;
        moreEntries = await _repo.fetchLeaderboard(
          challengeId: challengeId!,
          stream: filterStream,
          limit: requestedLimit,
        );
      } else {
        final period = activeTab.value == 'weekly'
            ? 'week'
            : activeTab.value == 'monthly'
                ? 'month'
                : 'year';
        moreEntries = await _repo.fetchPeriodLeaderboard(
          stream: activeStream.value,
          period: period,
          limit: requestedLimit,
        );
      }

      if (moreEntries.length <= entries.length) {
        hasMore.value = false;
      } else {
        if (moreEntries.length < requestedLimit) {
          hasMore.value = false;
        }
        entries.value = moreEntries;
      }
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  String get currentUserId => UserController.instance.user.value.id;

  /// Returns the user's entry from the top entries list, or their separately fetched standing.
  ChallengeLeaderboardEntry? get currentUserEntry {
    final inList = entries.firstWhereOrNull((e) => e.userId == currentUserId);
    if (inList != null) return inList;
    return _userStanding.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard({bool isManual = false}) async {
    if (isManual) {
      isManualRefreshing.value = true;
    } else {
      isLoading.value = true;
      entries.clear();
      displayLimit.value = _initialFetchLimit;
    }

    try {
      if (activeTab.value == 'challenge' && challengeId != null) {
        final aud = audience?.toLowerCase().trim();
        final filterStream = (aud == null || aud.isEmpty || aud == 'both')
            ? null
            : aud;

        entries.value = await _repo.fetchLeaderboard(
          challengeId: challengeId!,
          stream: filterStream,
          limit: _initialFetchLimit,
        );

        hasMore.value = entries.length >= _initialFetchLimit;

        // Fetch user standing separately if not in top results
        _userStanding.value = null;
        if (entries.every((e) => e.userId != currentUserId) && currentUserId.isNotEmpty) {
          _userStanding.value = await _repo.fetchUserChallengeStanding(
            challengeId: challengeId!,
            userId: currentUserId,
            stream: filterStream,
          );
        }
      } else {
        final period = activeTab.value == 'weekly'
            ? 'week'
            : activeTab.value == 'monthly'
                ? 'month'
                : 'year';

        final res = await _repo.fetchPeriodLeaderboard(
          stream: activeStream.value,
          period: period,
          limit: _initialFetchLimit,
        );

        entries.value = res.take(10).toList();

        // Weekly, monthly, and yearly strictly show only top 10 with no pagination
        hasMore.value = false;

        // Fetch user period standing separately if not in top results
        _userStanding.value = null;
        if (entries.every((e) => e.userId != currentUserId) && currentUserId.isNotEmpty) {
          _userStanding.value = await _repo.fetchUserPeriodStanding(
            stream: activeStream.value,
            period: period,
            userId: currentUserId,
          );
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
      isManualRefreshing.value = false;
    }
  }

  void setTab(String tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    displayLimit.value = _initialFetchLimit;
    loadLeaderboard(isManual: false);
  }

  Future<void> manualRefresh() async {
    displayLimit.value = _initialFetchLimit;
    await loadLeaderboard(isManual: true);
  }
}
