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
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }
}