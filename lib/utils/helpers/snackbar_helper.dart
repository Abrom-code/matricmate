import 'package:matricmate/common/widgets/toast/app_toast.dart';

/// Thin shim delegating to [AppToast] for snackbars and banners.
class SnackbarHelper {
  SnackbarHelper._();

  static void success(String title, String message) =>
      AppToast.success(title, message: message);

  static void error(String title, String message) =>
      AppToast.error(title, message: message);

  static void warning(String title, String message) =>
      AppToast.warning(title, message: message);

  static void info(String title, String message) =>
      AppToast.info(title, message: message);
}
