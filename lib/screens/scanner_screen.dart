import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
as mlkit;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/qr_utils.dart';
import '../services/qr_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() =>
      _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {

  ///  BANNER AD
  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  void loadBannerAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,

      /// TEST AD
      adUnitId:
      'ca-app-pub-3940256099942544/6300978111',

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isBannerLoaded = true;
          });
        },

        onAdFailedToLoad: (ad, error) {
          debugPrint(
            "Banner failed: ${error.message}",
          );
          ad.dispose();
        },
      ),

      request: const AdRequest(),
    );
    bannerAd!.load();
  }

  late final MobileScannerController controller;

  bool scanned = false;
  bool torch = false;

  double _currentZoom = 0.2;
  double _startZoom = 0.2;

  static const Color primaryColor =
  Color(0xFF4B68FF);

  @override
  void initState() {
    super.initState();

    loadBannerAd();

    controller = MobileScannerController(
      detectionSpeed:
      DetectionSpeed.normal,
      formats: [BarcodeFormat.qrCode],
    );

    controller.setZoomScale(_currentZoom);
  }

  Future<void> handle(String? code) async {
    if (code == null || scanned) return;

    scanned = true;

    // Show the result immediately
    if (!mounted) return;
    QRUtils.handleQR(context, code);

    // Save to Firestore in the background
    QRService.instance
        .recordScanned(
      qrType: "Scanned QR",
      title: "Scanned Code",
      data: code,
    )
        .catchError((e) {
      debugPrint("Firestore save failed: $e");
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        scanned = false;
      }
    });
  }

  Future scanFromGallery() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final inputImage =
    mlkit.InputImage.fromFilePath(
      image.path,
    );

    final scanner =
    mlkit.BarcodeScanner();

    try {
      final barcodes =
      await scanner.processImage(
        inputImage,
      );

      if (barcodes.isNotEmpty) {
        final code =
            barcodes.first.rawValue;

        if (code != null) {
          await handle(code);
        }
      }

      else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "No QR found in image",
            ),
          ),
        );
      }
    }

    catch (e) {
      debugPrint(
        "Gallery scan error: $e",
      );
    }

    scanner.close();
  }

  @override
  void dispose() {
    bannerAd?.dispose();

    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
            ),

            SizedBox(width: 8),

            Text(
              "QuickQR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        centerTitle: true,

        iconTheme:
        const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Stack(
        children: [

          /// 📷 CAMERA
          GestureDetector(
            behavior: HitTestBehavior.opaque,

            onScaleStart: (details) {
              _startZoom = _currentZoom;
            },

            onScaleUpdate:
                (details) async {

              double newZoom =
                  _startZoom *
                      details.scale;

              if (_startZoom == 0.0) {
                newZoom =
                    details.scale - 1;
              }

              newZoom =
                  newZoom.clamp(0.0, 1.0);

              _currentZoom = newZoom;

              await controller
                  .setZoomScale(
                _currentZoom,
              );
            },

            child: MobileScanner(
              controller: controller,

              onDetect: (capture) {
                if (capture
                    .barcodes
                    .isEmpty) {
                  return;
                }

                final code = capture
                    .barcodes
                    .first
                    .rawValue;

                if (code != null) {
                  handle(code);
                }
              },
            ),
          ),

          /// 🌑 DARK OVERLAY
          ClipPath(
            clipper:
            ScannerOverlayClipper(),

            child: Container(
              color:
              Colors.black.withOpacity(0.5),
            ),
          ),

          /// 🔝 TOP AD
          if (isBannerLoaded)
            Positioned(
              top: 95,
              left: 0,
              right: 0,

              child: Container(
                alignment: Alignment.center,

                child: SizedBox(
                  width: bannerAd!
                      .size
                      .width
                      .toDouble(),

                  height: bannerAd!
                      .size
                      .height
                      .toDouble(),

                  child:
                  AdWidget(ad: bannerAd!),
                ),
              ),
            ),

          /// 🔲 SCAN BOX
          Center(
            child: Container(
              width: 260,
              height: 260,

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),

                borderRadius:
                BorderRadius.circular(
                  24,
                ),
              ),
            ),
          ),

          /// 📝 HELPER TEXT
          Center(
            child: Transform.translate(
              offset:
              const Offset(0, 160),

              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                decoration:
                BoxDecoration(
                  color: Colors.black45,

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  "Align QR code within frame",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          /// 🎛️ BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,

            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),

              decoration:
              BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(
                  30,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.1),

                    blurRadius: 20,

                    offset:
                    const Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [

                  /// 🖼️ GALLERY
                  TextButton.icon(
                    onPressed:
                    scanFromGallery,

                    icon: const Icon(
                      Icons.image_outlined,
                      color: Colors.black87,
                    ),

                    label: const Text(
                      "Gallery",

                      style: TextStyle(
                        color:
                        Colors.black87,

                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 24,
                    color:
                    Colors.grey[300],
                  ),

                  /// 🔦 FLASH
                  IconButton(
                    onPressed: () {
                      controller
                          .toggleTorch();

                      setState(() {
                        torch = !torch;
                      });
                    },

                    icon: Icon(
                      torch
                          ? Icons.flash_on
                          : Icons.flash_off,

                      color: torch
                          ? primaryColor
                          : Colors.black87,
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

class ScannerOverlayClipper
    extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {

    final path = Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    const cut = 260.0;

    final left =
        (size.width - cut) / 2;

    final top =
        (size.height - cut) / 2;

    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            top,
            cut,
            cut,
          ),

          const Radius.circular(24),
        ),
      );

    return Path.combine(
      PathOperation.difference,
      path,
      hole,
    );
  }

  @override
  bool shouldReclip(
      CustomClipper<Path> oldClipper,
      ) {
    return false;
  }
}