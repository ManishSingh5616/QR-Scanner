import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:ambient_light/ambient_light.dart';

import '../utils/qr_utils.dart';
import 'generator_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController controller;

  bool scanned = false;
  bool torch = false;
  bool autoFlashEnabled = true;

  double _currentZoom = 0.2;
  double _startZoom = 0.2;

  final AmbientLight _ambientLight = AmbientLight();
  StreamSubscription? _lightSub;

  static const Color primaryColor = Color(0xFF4B68FF);

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      formats: [BarcodeFormat.qrCode],
    );

    /// 📸 initial zoom
    controller.setZoomScale(_currentZoom);

    /// 💡 auto flash
    _lightSub = _ambientLight.ambientLightStream.listen((lux) {
      if (!autoFlashEnabled) return;

      if (lux < 25 && !torch) {
        controller.toggleTorch();
        setState(() => torch = true);
      } else if (lux > 60 && torch) {
        controller.toggleTorch();
        setState(() => torch = false);
      }
    });
  }

  Future saveHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("history") ?? [];

    list.remove(value);
    list.insert(0, value);

    if (list.length > 50) list.removeLast();
    await prefs.setStringList("history", list);
  }

  Future handle(String? code) async {
    if (code == null || scanned) return;

    scanned = true;
    await saveHistory(code);

    if (!mounted) return;

    await QRUtils.handleQR(context, code);

    Future.delayed(const Duration(seconds: 2), () {
      scanned = false;
    });
  }

  Future scanFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final inputImage = mlkit.InputImage.fromFilePath(image.path);
    final scanner = mlkit.BarcodeScanner();

    try {
      final barcodes = await scanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null) await handle(code);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR found in image")),
        );
      }
    } catch (e) {
      debugPrint("Gallery scan error: $e");
    }

    scanner.close();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 8),
            Text("QuickQR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          /// 🎥 CAMERA + PINCH ZOOM
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              _startZoom = _currentZoom;
            },
            onScaleUpdate: (details) async {
              double newZoom = _startZoom * details.scale;
              if (_startZoom == 0.0) newZoom = details.scale - 1;
              newZoom = newZoom.clamp(0.0, 1.0);
              _currentZoom = newZoom;
              await controller.setZoomScale(_currentZoom);
            },
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final code = capture.barcodes.first.rawValue;
                if (code != null) handle(code);
              },
            ),
          ),

          /// 🌑 DARK OVERLAY
          ClipPath(
            clipper: ScannerOverlayClipper(),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          /// 🔲 EXACT CENTERED SCAN BOX
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          /// 📝 HELPER TEXT (Positioned below the centered box)
          Center(
            child: Transform.translate(
              offset: const Offset(0, 160), // Pushes text 160px down from center (130px half-box + 30px spacing)
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Align QR code within frame",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

          /// 🎛️ BOTTOM CONTROLS (Pill shaped)
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: scanFromGallery,
                    icon: const Icon(Icons.image_outlined, color: Colors.black87),
                    label: const Text("Gallery", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
                  IconButton(
                    onPressed: () {
                      autoFlashEnabled = false; // disable auto
                      controller.toggleTorch();
                      setState(() => torch = !torch);
                    },
                    icon: Icon(
                      torch ? Icons.flash_on : Icons.flash_off,
                      color: torch ? primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const cut = 260.0;
    final left = (size.width - cut) / 2;
    // Exactly perfectly centered vertically
    final top = (size.height - cut) / 2;

    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cut, cut),
        const Radius.circular(24),
      ));

    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}