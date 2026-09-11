import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:matricmate/common/widgets/toast/app_toast.dart';

/// Central helper for displaying in-app toast alerts.
///
/// Delegates to [AppToast] so toasts are interactive, auto-dismiss with a timer,
/// and can be swiped left or right to dismiss.
class ToastHelper {
  ToastHelper._();

  static void success(
    String message, {
    String? subtitle,
    ToastPosition position = ToastPosition.bottomCenter,
  }) {
    Fluttertoast.cancel();
    AppToast.dismissAll();
    AppToast.success(
      message,
      message: subtitle,
      position: position,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  static void error(
    String message, {
    String? subtitle,
    ToastPosition position = ToastPosition.bottomCenter,
  }) {
    Fluttertoast.cancel();
    AppToast.dismissAll();
    AppToast.error(
      message,
      message: subtitle,
      position: position,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  static void warning(
    String message, {
    String? subtitle,
    ToastPosition position = ToastPosition.bottomCenter,
  }) {
    Fluttertoast.cancel();
    AppToast.dismissAll();
    AppToast.warning(
      message,
      message: subtitle,
      position: position,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  static void info(
    String message, {
    String? subtitle,
    ToastPosition position = ToastPosition.bottomCenter,
  }) {
    Fluttertoast.cancel();
    AppToast.dismissAll();
    AppToast.info(
      message,
      message: subtitle,
      position: position,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Cancels any active toasts immediately.
  static void cancel() {
    Fluttertoast.cancel();
    AppToast.dismissAll();
  }
}
