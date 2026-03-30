import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ambient_light/ambient_light.dart';

import '../utils/qr_utils.dart';
import 'generator_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State {
  final MobileScannerController controller = MobileScannerController();

  bool scanned = false;
  bool torch = false;
  double zoom = 0.0;

  final AmbientLight _ambientLight = AmbientLight();
  StreamSubscription? _lightSub;

  @override
  void initState() {
    super.initState();

    _lightSub = _ambientLight.ambientLightStream.listen((lux) {
      if (lux < 15 && !torch) {
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

    Future.delayed(const Duration(seconds: 3), () {
      scanned = false;
    });

  }

  Future scanFromGallery() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final scanner = BarcodeScanner();

    final barcodes = await scanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;

      if (code != null) {
        final isLink = code.contains("http") ||
            code.contains("https") ||
            code.contains("www");

        if (isLink) {
          showModalBottomSheet(
            context: context,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.open_in_browser),
                    title: const Text("Open Link"),
                    onTap: () {
                      Navigator.pop(context);
                      handle(code);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text("Generate QR"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GeneratorScreenWithData(code),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          await handle(code);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No QR found")),
      );
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
      body: Stack(
        children: [
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

          ClipPath(
            clipper: ScannerOverlayClipper(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFF5F5F5),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

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
                  child: Image.asset(
                    "assets/icons/gallery.png",
                    width: 24,
                  ),
                ),
                FloatingActionButton(
                  heroTag: "torch",
                  onPressed: () {
                    controller.toggleTorch();
                    setState(() => torch = !torch);
                  },
                  child: Image.asset(
                    torch
                        ? "assets/icons/flash_on.png"
                        : "assets/icons/flash_off.png",
                    width: 24,
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
  bool shouldReclip(CustomClipper oldClipper) => false;
}