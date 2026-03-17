import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool torch = false;
  bool scanned = false;

  Future<void> saveHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];
    list.insert(0, value);
    await prefs.setStringList("history", list);
  }

  Future<void> handle(String? code) async {
    if (code == null || scanned) return;
    scanned = true;

    await saveHistory(code);

    if (!mounted) return;

    if (code.startsWith("http")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Open link?"),
          content: Text(code),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                scanned = false;
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse(code));
                scanned = false;
              },
              child: const Text("Open"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(code),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                scanned = false;
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            handle(barcodes.first.rawValue);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.toggleTorch();
          setState(() => torch = !torch);
        },
        child: Icon(torch ? Icons.flash_on : Icons.flash_off),
      ),
    );
  }
}