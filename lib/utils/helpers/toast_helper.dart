import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastHelper {
  ToastHelper._();

  static void success(String message) {
    _show(message, Colors.green);
  }

  static void error(String message) {
    _show(message, Colors.red);
  }

  static void warning(String message) {
    _show(message, Colors.orange);
  }

  static void info(String message) {
    _show(message, Colors.blue);
  }

  static void _show(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
