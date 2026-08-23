import 'package:get/get.dart';
import 'package:matricmate/features/authentication/screens/loading/loading.dart';
import 'package:matricmate/bindings/auth/change_password_binding.dart';
import 'package:matricmate/bindings/exam/bookmark_binding.dart';
import 'package:matricmate/bindings/exam/chapter_binding.dart';
import 'package:matricmate/bindings/auth/email_verify_binding.dart';
import 'package:matricmate/bindings/auth/forgot_password_binding.dart';
import 'package:matricmate/bindings/auth/login_binding.dart';
import 'package:matricmate/bindings/exam/entrance_binding.dart';
import 'package:matricmate/bindings/exam/entrance_exams_binding.dart';
import 'package:matricmate/bindings/exam/grade_test_binding.dart';
import 'package:matricmate/bindings/exam/question_binding.dart';
import 'package:matricmate/bindings/auth/reset_password_binding.dart';
import 'package:matricmate/bindings/exam/result_binding.dart';
import 'package:matricmate/bindings/exam/review_binding.dart';
import 'package:matricmate/bindings/auth/signup_binding.dart';
import 'package:matricmate/bindings/exam/test_binding.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/features/authentication/screens/password_configuration/forget_password.dart';
import 'package:matricmate/features/authentication/screens/password_configuration/reset_password.dart';
import 'package:matricmate/features/authentication/screens/signup/signup.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/chapter/chapter.dart';
import 'package:matricmate/features/exam/screens/tests_list/grade_tests.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance_exams.dart';
import 'package:matricmate/features/exam/screens/paused_tests/paused_tests_screen.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/features/exam/screens/result/result.dart';
import 'package:matricmate/features/exam/screens/result/review.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/bindings/exam/subject_detail_binding.dart';
import 'package:matricmate/features/exam/screens/subject/subject_detail_screen.dart';
import 'package:matricmate/features/exam/screens/tests_list/chapter_test.dart';
import 'package:matricmate/features/notifications/screens/notifications_screen.dart';
import 'package:matricmate/features/personalization/screens/analytics/analytics_screen.dart';
import 'package:matricmate/features/personalization/screens/profile/profile.dart';
import 'package:matricmate/features/personalization/screens/update/change_password.dart';
import 'package:matricmate/features/personalization/screens/update/update_profile.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/bindings/exam/premium_binding.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/screens/premium/payment.dart';
import 'package:matricmate/features/exam/screens/premium/premium.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/contact_admin.dart';
import 'package:matricmate/bindings/challenges/challenge_binding.dart';
import 'package:matricmate/features/challenges/screens/challenge_home_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_archive_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';

class AppRoutes {
  static final pages = [
    // loading — initial route (blank while auth decides where to go)
    GetPage(name: Routes.loading, page: () => const LoadingScreen()),

    // main
    GetPage(name: Routes.navigationMenu, page: () => const NavigationMenu()),
    GetPage(name: Routes.home, page: () => const SubjectsScreen()),
    GetPage(
      name: Routes.subjectDetail,
      page: () => const SubjectDetailScreen(),
      binding: SubjectDetailBinding(),
    ),
    GetPage(
      name: Routes.studyPractice,
      page: () => const ChapterScreen(),
      binding: ChapterBinding(),
    ),
    GetPage(
      name: Routes.mockExams,
      page: () => const EntranceExamsScreen(),
      binding: EntranceExamsBinding(),
    ),
    GetPage(
      name: Routes.bookmark,
      page: () => BookmarkScreen(),
      binding: BookmarkBinding(),
    ),
    GetPage(
      name: Routes.chapter,
      page: () => const ChapterScreen(),
      binding: ChapterBinding(),
    ),
    GetPage(
      name: Routes.gradeTests,
      page: () => const GradeTestsScreen(),
      binding: GradeTestBinding(),
    ),
    GetPage(
      name: Routes.testLists,
      page: () => const ChapterTestScreen(),
      binding: TestBinding(),
    ),
    GetPage(
      name: Routes.questions,
      page: () => const QuestionScreen(),
      binding: QuestionBinding(),
    ),
    GetPage(
      name: Routes.result,
      page: () => const ResultScreen(),
      binding: ResultBinding(),
    ),
    GetPage(
      name: Routes.review,
      page: () => const TestReviewScreen(),
      binding: ReviewBinding(),
    ),

    // analytics
    GetPage(name: Routes.analytics, page: () => const AnalyticsScreen()),

    // profile
    GetPage(name: Routes.userProfile, page: () => const ProfileScreen()),

    // auth
    GetPage(
      name: Routes.signup,
      page: () => const SignupScreen(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: Routes.verifyEmail,
      page: () => const VerifyEmailScreen(),
      binding: EmailVerifyBinding(),
    ),
    GetPage(
      name: Routes.signIn,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgetPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPasswordScreen(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileScreen(),
    ),

    GetPage(
      name: Routes.entrance,
      page: () => const EntranceScreen(),
      binding: EntranceBinding(),
    ),
    GetPage(
      name: Routes.entranceExams,
      page: () => const EntranceExamsScreen(),
      binding: EntranceExamsBinding(),
    ),
    GetPage(
      name: Routes.premium,
      page: () => const PremiumScreen(),
      binding: PremiumBinding(),
    ),
    GetPage(
      name: Routes.payment,
      page: () => PaymentScreen(payment: Get.arguments as PaymentConfig),
      binding: PremiumBinding(),
    ),
    GetPage(
      name: Routes.paymentVerification,
      page: () => const PaymentVerificationScreen(),
      binding: PremiumBinding(),
    ),
    GetPage(name: Routes.contactAdmin, page: () => const ContactAdminScreen()),
    GetPage(name: Routes.pausedTests, page: () => const PausedTestsScreen()),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsScreen(),
    ),

    // ── Challenges (Stream & Leaderboard Challenges) ───────────────────
    GetPage(
      name: Routes.challengeHome,
      page: () => const ChallengeHomeScreen(),
      binding: ChallengeBinding(),
    ),
    GetPage(
      name: Routes.challengeAttempt,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return ChallengeAttemptScreen(
          challengeId: args['challenge_id']?.toString() ?? '',
          title: args['title']?.toString() ?? 'Challenge Attempt',
        );
      },
    ),
    GetPage(
      name: Routes.challengeLeaderboard,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return LeaderboardScreen(
          challengeId: args['challenge_id']?.toString(),
          challengeTitle: args['title']?.toString(),
          audience: args['audience']?.toString(),
        );
      },
    ),
    GetPage(
      name: Routes.challengeArchive,
      page: () => const ChallengeArchiveScreen(),
      binding: ChallengeBinding(),
    ),
    GetPage(
      name: Routes.challengePractice,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return ChallengePracticeScreen(
          challengeId: args['challenge_id']?.toString() ?? args['id']?.toString() ?? args['set_id']?.toString() ?? '',
          setId: args['set_id']?.toString(),
          title: args['title']?.toString() ?? 'Practice Challenge',
        );
      },
    ),
  ];
}
