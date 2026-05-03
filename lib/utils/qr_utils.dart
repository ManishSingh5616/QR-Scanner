import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

// 🔥 NEW IMPORTS
import '../utils/share_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRUtils {
  static const MethodChannel _channel = MethodChannel('wifi_connect');
  static const Color primaryColor = Color(0xFF4B68FF);

  // 🚀 Main handler
  static Future<void> handleQR(BuildContext context, String code) async {
    code = code.trim();

    try {
      // 💰 UPI Payment
      if (code.startsWith("upi://")) {
        final uri = Uri.parse(code);

        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No payment app found")),
          );
        }
      }

      // 📶 WiFi
      else if (code.startsWith("WIFI:")) {
        await _handleWifi(context, code); // Added await
      }

      // 🌐 Links & 📄 Everything else
      else {
        await _showResultActions(context, code); // Added await
      }
    } catch (e) {
      debugPrint("QR Error: $e");
    }
  }

  // 📶 WiFi Handler
  static Future<void> _handleWifi(BuildContext context, String code) async {
    final ssid = _extract(code, "S:");
    final password = _extract(code, "P:");
    final type = _extract(code, "T:");

    // Added await here so it blocks until dismissed
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("WiFi Network", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("SSID", ssid),
            const SizedBox(height: 8),
            _buildDetailRow("Security", type),
            const SizedBox(height: 8),
            _buildDetailRow("Password", password),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
            child: const Text("Settings", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final status = await Permission.location.request();

              if (!status.isGranted) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location permission required")),
                );
                return;
              }

              await connectWifi(ssid, password);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Trying to connect...")),
              );
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        children: [
          TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value),
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

  // 🔥 RESULT ACTIONS (UPGRADED UI)
  static Future<void> _showResultActions(BuildContext context, String text) async {
    final isLink = text.startsWith("http://") || text.startsWith("https://");

    // Added await here so it blocks until bottom sheet is closed
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Decoded Text Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLink ? "Scanned Link" : "Scanned Text",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Grid
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                if (isLink)
                  _action(
                    icon: Icons.open_in_browser,
                    label: "Open Link",
                    color: primaryColor,
                    isPrimary: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication);
                    },
                  ),
                _action(
                  icon: Icons.copy,
                  label: "Copy",
                  onTap: () {
                    Navigator.pop(context);
                    ShareUtils.copy(context, text);
                  },
                ),
                _action(
                  icon: Icons.share,
                  label: "Share",
                  onTap: () {
                    Navigator.pop(context);
                    ShareUtils.shareText(text);
                  },
                ),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🎯 Action UI (Modern Styling)
  static Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPrimary ? color : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
                icon,
                size: 26,
                color: isPrimary ? Colors.white : color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: isPrimary ? color : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // 🔳 QR Preview (Modern Dialog)
  static void _showQR(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("QR Code", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: QrImageView(data: text, size: 200),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔍 Extract QR data
  static String _extract(String text, String key) {
    final start = text.indexOf(key);
    if (start == -1) return "";
    final end = text.indexOf(";", start);
    return text.substring(start + key.length, end == -1 ? text.length : end);
  }
}