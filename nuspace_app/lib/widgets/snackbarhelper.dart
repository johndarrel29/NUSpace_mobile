import 'package:flutter/material.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import '../main.dart';

class SnackbarHelper {
  static String? _lastMessage;

  static void showSnackbar(String message, {Color? backgroundColor}) {
    final messenger = MainApp.scaffoldMessengerKey.currentState;

    if (_lastMessage == message) return;
    _lastMessage = message;

    messenger?.hideCurrentSnackBar(); // Dismiss any active snackbar
    messenger?.removeCurrentSnackBar(); // Clear the queue

    messenger?.showSnackBar(
      SnackBar(
        content: CustomFont(text: message, fontSize: 14, color: Colors.white),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void showConnectivityStatus(bool isConnected) {
    final messenger = MainApp.scaffoldMessengerKey.currentState;
    final message = isConnected ? "Back Online" : "No Internet Connection";
    final color = isConnected ? Colors.green : Colors.red;

    if (_lastMessage == message) return;
    _lastMessage = message;

    messenger?.hideCurrentSnackBar();
    messenger?.removeCurrentSnackBar(); // Prevent multiple queued snackbars

    messenger?.showSnackBar(
      SnackBar(
        content: CustomFont(text: message, fontSize: 14, color: Colors.white),
        backgroundColor: color,
        duration:
            isConnected ? const Duration(seconds: 3) : const Duration(days: 1),
      ),
    );
  }
}
