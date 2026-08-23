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
  final activeTab = 'challenge'.obs; // 'challenge', 'weekly', 'monthly'
  final activeStream = 'natural'.obs; // Locked to student's stream
  final entries = <ChallengeLeaderboardEntry>[].obs;

  String get currentUserId => UserController.instance.user.value.id;

  ChallengeLeaderboardEntry? get currentUserEntry =>
      entries.firstWhereOrNull((e) => e.userId == currentUserId);

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
    }

    try {
      if (activeTab.value == 'challenge' && challengeId != null) {
        entries.value = await _repo.fetchLeaderboard(
          challengeId: challengeId!,
          stream: activeStream.value,
          limit: 100,
        );
      } else if (activeTab.value == 'weekly') {
        entries.value = await _repo.fetchPeriodLeaderboard(
          stream: activeStream.value,
          period: 'week',
          limit: 100,
        );
      } else if (activeTab.value == 'monthly') {
        entries.value = await _repo.fetchPeriodLeaderboard(
          stream: activeStream.value,
          period: 'month',
          limit: 100,
        );
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
    loadLeaderboard(isManual: false);
  }

  Future<void> manualRefresh() async {
    await loadLeaderboard(isManual: true);
  }
}
