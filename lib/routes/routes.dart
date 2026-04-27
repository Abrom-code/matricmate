import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:matricmate/bindings/bookmark_binding.dart';
import 'package:matricmate/bindings/chapter_binding.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/bindings/result_binding.dart';
import 'package:matricmate/bindings/review_binding.dart';
import 'package:matricmate/bindings/test_binding.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/features/authentication/screens/password_configration/forget_password.dart';
import 'package:matricmate/features/authentication/screens/signup/signup.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/chapter/chapter.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/grade_tests_page.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/features/exam/screens/result/result.dart';
import 'package:matricmate/features/exam/screens/result/result_review.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/exam/screens/tests_list/tests_list.dart';
import 'package:matricmate/features/personalization/screen/profile/profile.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/routes/app_routes.dart';

class AppRoutes {
  static final pages = [
    // main
    GetPage(name: Routes.navigationMenu, page: () => const NavigationMenu()),
    GetPage(name: Routes.home, page: () => const SubjectsScreen()),
    GetPage(
      name: Routes.bookmark,
      page: () => const BookmarkScreen(),
      binding: BookmarkBinding(),
    ),
    GetPage(
      name: Routes.chapter,
      page: () => ChapterScreen(),
      binding: ChapterBinding(),
    ),
    GetPage(
      name: Routes.gradeTests,
      page: () => GradeTestsPage(),
      binding: TestBinding(),
    ),
    GetPage(
      name: Routes.testLists,
      page: () => TestListScreen(),
      binding: TestBinding(),
    ),
    GetPage(
      name: Routes.questions,
      page: () => QuestionScreen(),
      binding: QuestionBinding(),
    ),
    GetPage(
      name: Routes.result,
      page: () => ResultScreen(),
      binding: ResultBinding(),
    ),
    GetPage(
      name: Routes.review,
      page: () => TestReviewScreen(),
      binding: ReviewBinding(),
    ),

    // profile
    GetPage(name: Routes.userProfile, page: () => const ProfileScreen()),

    // auth
    GetPage(name: Routes.signup, page: () => const SignupScreen()),
    GetPage(name: Routes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: Routes.signIn, page: () => const LoginScreen()),
    GetPage(name: Routes.forgetPassword, page: () => const ForgetPassword()),
    // Add more GetPage entries as needed
  ];
}
