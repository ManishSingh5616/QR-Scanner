import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../utils/qr_utils.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  bool scanned = false;
  bool torch = false;

  // ✅ Save history (no duplicates)
  Future<void> saveHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];

    if (list.isEmpty || list.first != value) {
      list.insert(0, value);
    }

    await prefs.setStringList("history", list);
  }

  // ⚠️ Detect HTTP warning
  Future<bool> showHttpWarning(String code) async {
    if (code.startsWith("http://")) {
      return await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⚠ Unsafe Link"),
          content: Text(
              "This link is not secure:\n\n$code\n\nDo you want to continue?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Open"),
            ),
          ],
        ),
      ) ??
          false;
    }
    return true;
  }

  // ✅ Handle scan safely
  Future<void> handle(String? code) async {
    if (code == null || scanned) return;

    scanned = true;

    try {
      await saveHistory(code);

      if (!mounted) return;

      // ⚠️ HTTP check
      final allow = await showHttpWarning(code);
      if (!allow) {
        scanned = false;
        return;
      }

      await QRUtils.handleQR(context, code);
    } catch (e) {
      debugPrint("Error: $e");
    }

    scanned = false;
  }

  // 📷 Gallery Scan (ML Kit)
  Future<void> scanFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final barcodeScanner = BarcodeScanner();

      final barcodes = await barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        for (final barcode in barcodes) {
          final code = barcode.rawValue;

          if (code != null) {
            await handle(code);
            break; // handle first valid result only
          }
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code found in image")),
        );
      }

      barcodeScanner.close();
    } catch (e) {
      debugPrint("Gallery Scan Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to scan image")),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📷 Camera Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;

              for (final barcode in barcodes) {
                final code = barcode.rawValue;

                if (code != null) {
                  handle(code);
                  break;
                }
              }
            },
          ),

          // 🌑 Dark overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🟩 Scan box border
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 🔘 Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 📷 Gallery button
                FloatingActionButton(
                  heroTag: "gallery",
                  onPressed: scanFromGallery,
                  child: const Icon(Icons.photo),
                ),

                // 🔦 Torch
                FloatingActionButton(
                  heroTag: "torch",
                  onPressed: () {
                    controller.toggleTorch();
                    setState(() => torch = !torch);
                  },
                  child: Icon(
                    torch ? Icons.flash_on : Icons.flash_off,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}