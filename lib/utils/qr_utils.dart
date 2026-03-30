import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

// 🔥 NEW IMPORTS
import '../utils/share_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRUtils {
  static const MethodChannel _channel = MethodChannel('wifi_connect');

  // 🚀 Main handler
  static Future<void> handleQR(BuildContext context, String code) async {
    code = code.trim();

    try {
      // 💰 UPI Payment
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

      // 🌐 Links → NOW SHOW OPTIONS (FIXED)
      else if (code.startsWith("http://") ||
          code.startsWith("https://")) {
        _showResultActions(context, code);
      }

      // 📄 Everything else
      else {
        _showResultActions(context, code);
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

  // 📄 OLD Text dialog (kept)
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

  // 🔥 RESULT ACTIONS (MAIN FEATURE)
  static void _showResultActions(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 25,
          runSpacing: 25,
          children: [

            // 🌐 OPEN (only for links)
            if (text.startsWith("http"))
              _action(
                icon: Icons.open_in_browser,
                label: "Open",
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse(text),
                      mode: LaunchMode.externalApplication);
                },
              ),

            // 📤 SHARE
            _action(
              icon: Icons.share,
              label: "Share",
              onTap: () {
                Navigator.pop(context);
                ShareUtils.shareText(text);
              },
            ),

            // 📋 COPY
            _action(
              icon: Icons.copy,
              label: "Copy",
              onTap: () {
                Navigator.pop(context);
                ShareUtils.copy(context, text);
              },
            ),

            // 🔳 QR CODE
            _action(
              icon: Icons.qr_code,
              label: "QR Code",
              onTap: () {
                Navigator.pop(context);
                _showQR(context, text);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 Action UI
  static Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  // 🔳 QR Preview
  static void _showQR(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("QR Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: text, size: 200),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
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