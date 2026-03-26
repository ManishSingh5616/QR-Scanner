import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class QRUtils {
  static const MethodChannel _channel = MethodChannel('wifi_connect');

  // 🚀 Main handler
  static Future<void> handleQR(BuildContext context, String code) async {
    code = code.trim();

    try {
      // 💰 UPI Payment (FIXED)
      if (code.startsWith("upi://")) {
        final uri = Uri.parse(code);

        if (!await launchUrl(uri,
            mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No payment app found")),
          );
        }

      }

      // 📶 WiFi
      else if (code.startsWith("WIFI:")) {
        _handleWifi(context, code);
      }

      // 🌐 Links
      else if (code.startsWith("http://") ||
          code.startsWith("https://")) {
        await launchUrl(Uri.parse(code),
            mode: LaunchMode.externalApplication);
      }

      // 📄 Everything else
      else {
        _showText(context, code);
      }
    } catch (e) {
      debugPrint("QR Error: $e");
    }
  }

  // 📶 WiFi Handler
  static void _handleWifi(BuildContext context, String code) {
    final ssid = _extract(code, "S:");
    final password = _extract(code, "P:");
    final type = _extract(code, "T:");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("WiFi Network"),
        content: Text(
          "SSID: $ssid\nSecurity: $type\nPassword: $password",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // 🔥 Request permission (SAFE)
              final status = await Permission.location.request();

              if (!status.isGranted) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Location permission required"),
                  ),
                );
                return;
              }

              // 🔥 Try native connect
              await connectWifi(ssid, password);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Trying to connect..."),
                ),
              );
            },
            child: const Text("Connect"),
          ),

          // ✅ ALWAYS KEEP THIS (important fallback)
          TextButton(
            onPressed: () async {
            Navigator.pop(context);

            const platform = MethodChannel('wifi_connect');

            try {
              await platform.invokeMethod('openWifiSettings');
            } catch (e) {
              debugPrint("Error opening settings: $e");
            }
          },
            child: const Text("Open Settings"),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // 🔗 Native call
  static Future<void> connectWifi(String ssid, String password) async {
    try {
      await _channel.invokeMethod('connectWifi', {
        "ssid": ssid,
        "password": password,
      });
    } catch (e) {
      debugPrint("WiFi Error: $e");
    }
  }

  // 📄 Text dialog
  static void _showText(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  // 🔍 Extract QR data
  static String _extract(String text, String key) {
    final start = text.indexOf(key);
    if (start == -1) return "";

    final end = text.indexOf(";", start);

    return text.substring(
      start + key.length,
      end == -1 ? text.length : end,
    );
  }
}