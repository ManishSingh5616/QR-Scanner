import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State {
  final controller = TextEditingController();
  final qrKey = GlobalKey();

  String data = "";

  Future<File?> captureQR() async {
    try {
      final boundary =
      qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage();
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/qr.png");

      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Generate QR")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter text or URL",
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => data = controller.text);
              },
              child: const Text("Generate"),
            ),

            const SizedBox(height: 20),

            if (data.isNotEmpty)
              RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  data: data,
                  size: 200,
                  foregroundColor: Colors.black,
                ),
              ),

            if (data.isNotEmpty) ...[
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.black),
                    onPressed: () async {
                      final file = await captureQR();
                      if (file != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Saved successfully")),
                        );
                      }
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black),
                    onPressed: () async {
                      final file = await captureQR();
                      if (file != null) {
                        Share.shareXFiles([XFile(file.path)]);
                      }
                    },
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );

  }
}

// 🔥 Used when opening from gallery link detection
class GeneratorScreenWithData extends StatelessWidget {
  final String data;

  const GeneratorScreenWithData(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated QR")),
      body: Center(
        child: QrImageView(
          data: data,
          size: 250,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}