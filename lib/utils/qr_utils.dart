import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QRUtils {
  static Future<void> handleQR(BuildContext context, String code) async {
    if (code.startsWith("upi://")) {
      await launchUrl(Uri.parse(code));
    } else if (code.startsWith("WIFI:")) {
      _wifi(context, code);
    } else if (code.startsWith("BEGIN:VCARD")) {
      _vcard(context, code);
    } else if (code.startsWith("BEGIN:VEVENT")) {
      _event(context, code);
    } else if (code.startsWith("http")) {
      await launchUrl(Uri.parse(code));
    } else {
      _text(context, code);
    }
  }

  static void _wifi(BuildContext context, String code) {
    final ssid = _extract(code, "S:");
    final type = _extract(code, "T:");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("WiFi"),
        content: Text("SSID: $ssid\nSecurity: $type"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  static void _vcard(BuildContext context, String code) {
    final name = _extract(code, "FN:");
    final phone = _extract(code, "TEL:");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Contact"),
        content: Text("Name: $name\nPhone: $phone"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  static void _event(BuildContext context, String code) {
    final title = _extract(code, "SUMMARY:");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Event"),
        content: Text("Title: $title"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  static void _text(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(code),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  static String _extract(String text, String key) {
    final start = text.indexOf(key);
    if (start == -1) return "";
    final end = text.indexOf(";", start);
    return text.substring(start + key.length,
        end == -1 ? text.length : end);
  }
}