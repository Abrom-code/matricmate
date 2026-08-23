import 'package:flutter/material.dart';

/// Global route observer for didPopNext callbacks on back navigation.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

class Routes {
  // exam
  static const home = '/';
  static const subjectDetail = '/subject-detail';
  static const studyPractice = '/study-practice';
  static const mockExams = '/mock-exams';
  static const bookmark = '/bookmark';
  static const chapter = '/chapter';
  static const gradeTests = '/gradeTests';
  static const entrance = '/entrance';
  static const entranceExams = '/entrance-exams';
  static const testLists = '/test_lists';
  static const questions = '/questions';
  static const result = '/result';
  static const review = '/review';
  static const pausedTests = '/paused-tests';

  // premium
  static const premium = '/premium';
  static const payment = '/payment';
  static const paymentVerification = '/payment-verification';
  static const contactAdmin = '/contact-admin';

  // analytics
  static const analytics = '/analytics';

  // nav
  static const navigationMenu = '/navigation-menu';

  // profile
  static const userProfile = '/user-profile';
  static const editProfile = '/edit-profile';

  // auth
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const signIn = '/sign-in';
  static const changePassword = '/change-password';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // notifications
  static const notifications = '/notifications';

  // loading
  static const loading = '/loading';

  // challenges
  static const challengeHome = '/challenge-home';
  static const challengeAttempt = '/challenge-attempt';
  static const challengeLeaderboard = '/challenge-leaderboard';
  static const challengeArchive = '/challenge-archive';
  static const challengePractice = '/challenge-practice';
}
