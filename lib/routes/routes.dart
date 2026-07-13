import 'package:get/get.dart';
import 'package:matricmate/features/authentication/screens/loading/loading.dart';
import 'package:matricmate/bindings/exam/bookmark_binding.dart';
import 'package:matricmate/bindings/auth/change_password_binding.dart';
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
import 'package:matricmate/features/authentication/screens/password_configration/forget_password.dart';
import 'package:matricmate/features/authentication/screens/password_configration/reset_password.dart';
import 'package:matricmate/features/authentication/screens/signup/signup.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/chapter/chapter.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/grade_test.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/exam_list.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/features/exam/screens/result/result.dart';
import 'package:matricmate/features/exam/screens/result/review.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/exam/screens/tests_list/chapter_test.dart';
import 'package:matricmate/features/personalization/screen/analytics/analytics_screen.dart';
import 'package:matricmate/features/personalization/screen/profile/profile.dart';
import 'package:matricmate/features/personalization/screen/update/change_password.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/routes/app_routes.dart';

class AppRoutes {
  static final pages = [
    // loading — initial route (blank while auth decides where to go)
    GetPage(name: Routes.loading, page: () => const LoadingScreen()),

    // main
    GetPage(name: Routes.navigationMenu, page: () => const NavigationMenu()),
    GetPage(name: Routes.home, page: () => SubjectsScreen()),
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
      page: () => const GradeTestsPage(),
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
      name: Routes.forgetPassword,
      page: () => const ForgetPassword(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPassword(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePassword(),
      binding: ChangePasswordBinding(),
    ),

    GetPage(
      name: Routes.entrance,
      page: () => EntranceScreen(),
      binding: EntranceBinding(),
    ),
    GetPage(
      name: Routes.entranceExams,
      page: () => const EntranceExams(),
      binding: EntranceExamsBinding(),
    ),
  ];
}
