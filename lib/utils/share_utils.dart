import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  // 📤 Share anywhere
  static void shareText(String text) {
    Share.share(text);
  }

  // 📋 Copy to clipboard
  static void copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Copied to clipboard"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF4B68FF),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }
}