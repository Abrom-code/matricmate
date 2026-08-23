import 'package:get/get.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class LeaderboardController extends GetxController {
  LeaderboardController({this.challengeId, String? audience}) {
    if (audience != null && audience.isNotEmpty && audience != 'both') {
      activeStream.value = audience.toLowerCase();
    } else {
      activeStream.value = UserController.instance.user.value.stream.toLowerCase().isNotEmpty
          ? UserController.instance.user.value.stream.toLowerCase()
          : 'natural';
    }
    if (challengeId != null && challengeId!.isNotEmpty) {
      activeTab.value = 'challenge';
    } else {
      activeTab.value = 'weekly';
    }
  }

  final String? challengeId;
  final _repo = ChallengeRepository();

  final isLoading = false.obs;
  final activeTab = 'challenge'.obs; // 'challenge', 'weekly', 'monthly'
  final activeStream = 'natural'.obs; // 'natural', 'social'
  final entries = <ChallengeLeaderboardEntry>[].obs;

  String get currentUserId => UserController.instance.user.value.id;

  ChallengeLeaderboardEntry? get currentUserEntry =>
      entries.firstWhereOrNull((e) => e.userId == currentUserId);

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    isLoading.value = true;
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
    }
  }

  void setTab(String tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    loadLeaderboard();
  }

  void setStream(String stream) {
    if (activeStream.value == stream) return;
    activeStream.value = stream;
    loadLeaderboard();
  }
}
