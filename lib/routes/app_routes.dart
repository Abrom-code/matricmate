import 'package:flutter/material.dart';

/// Global route observer — subscribe screens to get `didPopNext` callbacks
/// when the user navigates back to them.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

class Routes {
  // exam
  static const home = '/';
  static const bookmark = '/bookmark';
  static const chapter = '/chapter';
  static const gradeTests = '/gradeTests';
  static const entrance = '/entrance';
  static const entranceExams = '/entrance-exams';
  static const testLists = '/test_lists';
  static const questions = '/questions';
  static const result = '/result';
  static const review = '/review';
  static const ready = '/ready';

  // analytics
  static const analytics = '/analytics';

  // nav
  static const navigationMenu = '/navigation-menu';

  // profile
  static const userProfile = '/user-profile';
  static const updateProfile = '/update-profile';

  // auth
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const signIn = '/sign-in';
  static const changePassword = '/change-password';
  static const forgetPassword = '/forget-password';
  static const resetPassword = '/reset-password';

  // loading
  static const loading = '/loading';
}
