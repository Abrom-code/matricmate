import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeArchiveController extends GetxController {
  static ChallengeArchiveController get instance => Get.find();

  final _repo = ChallengeRepository();
  final _db = DatabaseService.instance;

  final isLoading = false.obs;
  final challenges = <LeaderboardChallengeModel>[].obs;
  final downloadedIds = <String>{}.obs;
  final isDownloading = <String, bool>{}.obs;

  bool get isPremium => UserController.instance.user.value.isActive;
  String get userStream => UserController.instance.user.value.stream.toLowerCase().trim();

  @override
  void onInit() {
    super.onInit();
    loadArchive();
  }

  Future<void> loadArchive() async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchClosedChallenges(stream: userStream);
      final isNatural = userStream == 'natural';

      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];

      final filtered = list.where((c) {
        final aud = c.audience.toLowerCase().trim();
        final matchesAudience = aud == 'both' || aud == userStream || userStream.isEmpty;
        if (!matchesAudience) return false;

        if (subjectsList.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            return subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
          }
        }
        return true;
      }).toList();

      challenges.value = filtered;
      await refreshDownloadStates();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDownloadStates() async {
    final downloaded = <String>{};
    for (final c in challenges) {
      final isDown = await _db.isChallengeDownloaded(c.id);
      if (isDown) downloaded.add(c.id);
    }
    downloadedIds.assignAll(downloaded);
  }

  bool isDownloaded(String challengeId) => downloadedIds.contains(challengeId);

  Future<void> downloadChallenge(LeaderboardChallengeModel challenge) async {
    if (!isPremium) {
      Get.bottomSheet(const PremiumBottomSheet(), isScrollControlled: true);
      return;
    }

    try {
      isDownloading[challenge.id] = true;
      final userId = UserController.instance.user.value.id;

      final bundle = await _repo.fetchChallengeBundle(
        challengeId: challenge.id,
        userId: userId,
      );

      await _db.insertDownloadedChallengeBundle(bundle);
      downloadedIds.add(challenge.id);
      ToastHelper.success('Downloaded for offline practice!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isDownloading[challenge.id] = false;
    }
  }

  Future<void> deleteDownload(LeaderboardChallengeModel challenge) async {
    try {
      await _db.deleteDownloadedChallenge(challenge.setId);
      downloadedIds.remove(challenge.id);
      ToastHelper.info('Removed local download');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }
}
