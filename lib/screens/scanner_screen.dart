import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ambient_light/ambient_light.dart';

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
  double zoom = 0.0;

  final AmbientLight _ambientLight = AmbientLight();
  StreamSubscription<double>? _lightSub;

  @override
  void initState() {
    super.initState();

    // 🌑 Auto flashlight based on light
    _lightSub = _ambientLight.ambientLightStream.listen((lux) {
      if (lux < 10 && !torch) {
        controller.toggleTorch();
        setState(() => torch = true);
      } else if (lux > 80 && torch) {
        controller.toggleTorch();
        setState(() => torch = false);
      }
    });
  }

  // ✅ Save history
  Future<void> saveHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];

    list.remove(value);
    list.insert(0, value);

    if (list.length > 50) list.removeLast();

    await prefs.setStringList("history", list);
  }

  // ⚠ HTTP warning
  Future<bool> showHttpWarning(String code) async {
    if (code.startsWith("http://")) {
      return await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⚠ Unsafe Link"),
          content: Text("This link is not secure:\n\n$code"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Open")),
          ],
        ),
      ) ??
          false;
    }
    return true;
  }

  // ✅ Handle scan
  Future<void> handle(String? code) async {
    if (code == null || scanned) return;

    scanned = true;

    try {
      await saveHistory(code);

      if (!mounted) return;

      final allow = await showHttpWarning(code);
      if (!mounted) return;

      if (!allow) {
        scanned = false;
        return;
      }

      await QRUtils.handleQR(context, code);
    } catch (e) {
      debugPrint("Error: $e");
    }

    // ❌ REMOVE instant reset
    // scanned = false;

    // ✅ ADD DELAY (IMPORTANT)
    Future.delayed(const Duration(seconds: 3), () {
      scanned = false;
    });
  }

  // 📷 Gallery scan
  Future<void> scanFromGallery() async {
    final picker = ImagePicker();

    try {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final scanner = BarcodeScanner();

      try {
        final barcodes = await scanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue;
          if (code != null) await handle(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No QR found")),
          );
        }
      } finally {
        scanner.close();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Scan failed")),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _lightSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📷 Camera with pinch zoom
          GestureDetector(
            onScaleUpdate: (details) {
              zoom = (zoom + details.scale - 1).clamp(0.0, 1.0);
              controller.setZoomScale(zoom);
            },
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final code = barcode.rawValue;
                  if (code != null) {
                    handle(code);
                    break;
                  }
                }
              },
            ),
          ),

          // 🌑 Overlay with bright center
          ClipPath(
            clipper: ScannerOverlayClipper(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),

          // 🟩 Scan border
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

          // 🔘 Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: "gallery",
                  onPressed: scanFromGallery,
                  child: const Icon(Icons.photo),
                ),
                FloatingActionButton(
                  heroTag: "torch",
                  onPressed: () {
                    controller.toggleTorch();
                    setState(() => torch = !torch);
                  },
                  child:
                  Icon(torch ? Icons.flash_on : Icons.flash_off),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✂️ Cutout overlay
class ScannerOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path =
    Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const cut = 260.0;
    final left = (size.width - cut) / 2;
    final top = (size.height - cut) / 2;

    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cut, cut),
        const Radius.circular(16),
      ));

    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}