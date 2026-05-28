import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() =>
      _GeneratorScreenState();
}

class _GeneratorScreenState
    extends State<GeneratorScreen> {

  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  void loadBannerAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,

      adUnitId:
      'ca-app-pub-3940256099942544/6300978111',

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isBannerLoaded = true;
          });
        },

        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),

      request: const AdRequest(),
    );

    bannerAd!.load();
  }

  @override
  void initState() {
    super.initState();

    loadBannerAd();
  }

  @override
  void dispose() {
    bannerAd?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {"title": "Text", "icon": Icons.text_fields},
      {"title": "Website", "icon": Icons.link},
      {"title": "Wi-Fi", "icon": Icons.wifi},
      {"title": "Contacts", "icon": Icons.contacts},
      {"title": "Phone", "icon": Icons.phone},
      {"title": "E-mail", "icon": Icons.email},
      {"title": "SMS", "icon": Icons.sms},
      {"title": "Calendar", "icon": Icons.calendar_month},
      {"title": "My Card", "icon": Icons.badge},
      {"title": "Whatsapp", "icon": Icons.wechat},
      {"title": "Instagram", "icon": Icons.photo_camera},
      {"title": "Facebook", "icon": Icons.facebook_rounded},
      {"title": "Youtube", "icon": Icons.smart_display},
      {"title": "Spotify", "icon": Icons.album},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          "Create",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
        children: [

          if (isBannerLoaded)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: bannerAd!),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 350),
                          pageBuilder: (_, animation, __) => QRFormPage(
                            title: item["title"] as String,
                            icon: item["icon"] as IconData,
                          ),
                          transitionsBuilder:
                              (_, animation, __, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item["icon"] as IconData,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item["title"] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
     ),
    );
  }
}

class QRFormPage extends StatefulWidget {
  final String title;
  final IconData icon;

  const QRFormPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  State<QRFormPage> createState() => _QRFormPageState();
}

class _QRFormPageState extends State<QRFormPage> {
  String qrData = "";

  final ScreenshotController screenshotController =
  ScreenshotController();

  final TextEditingController textController =
  TextEditingController();

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController orgController =
  TextEditingController();

  final TextEditingController addressController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController notesController =
  TextEditingController();

  final TextEditingController subjectController =
  TextEditingController();

  final TextEditingController bodyController =
  TextEditingController();

  final TextEditingController eventController =
  TextEditingController();

  final TextEditingController locationController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController birthdayController =
  TextEditingController();

  final TextEditingController countryController =
  TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String wifiType = "WPA/WPA2";

  Widget buildField(
      String hint,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1E2235),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> pickDate(bool isStart) async {
    DateTime now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void generateQR() {
    switch (widget.title) {
      case "Text":
        qrData = textController.text;
        break;

      case "Website":
        qrData = textController.text.startsWith("http")
            ? textController.text
            : "https://${textController.text}";
        break;

      case "Wi-Fi":
        qrData =
        "WIFI:T:$wifiType;S:${textController.text};P:${phoneController.text};;";
        break;

      case "Contacts":
      case "My Card":
        qrData = '''
BEGIN:VCARD
FN:${nameController.text}
ORG:${orgController.text}
TEL:${phoneController.text}
EMAIL:${emailController.text}
ADR:${addressController.text}
BDAY:${birthdayController.text}
NOTE:${notesController.text}
END:VCARD
''';
        break;

      case "Phone":
        qrData = "tel:${phoneController.text}";
        break;

      case "E-mail":
        qrData =
        "mailto:${emailController.text}?subject=${subjectController.text}&body=${bodyController.text}";
        break;

      case "SMS":
        qrData =
        "sms:${phoneController.text}?body=${bodyController.text}";
        break;

      case "Calendar":
        qrData = '''
Event: ${eventController.text}
Start: $startDate
End: $endDate
Location: ${locationController.text}
Description: ${descriptionController.text}
''';
        break;

      case "Whatsapp":
        qrData =
        "https://wa.me/${countryController.text}${phoneController.text}";
        break;

      case "Instagram":
        qrData = textController.text.startsWith("http")
            ? textController.text
            : "https://instagram.com/${textController.text}";
        break;

      case "Facebook":
        qrData = textController.text.startsWith("http")
            ? textController.text
            : "https://facebook.com/${textController.text}";
        break;

      case "Youtube":
      case "Spotify":
        qrData = textController.text;
        break;
    }

    setState(() {});
  }

  Future<void> saveQR() async {
    final Uint8List? image =
    await screenshotController.capture();

    if (image == null) return;

    final directory =
    await getTemporaryDirectory();

    final file = File('${directory.path}/qr.png');

    await file.writeAsBytes(image);

    await GallerySaver.saveImage(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("QR saved to gallery"),
      ),
    );
  }

  Future<void> shareQR() async {
    final Uint8List? image =
    await screenshotController.capture();

    if (image == null) return;

    final directory =
    await getTemporaryDirectory();

    final file = File('${directory.path}/qr.png');

    await file.writeAsBytes(image);

    await Share.shareXFiles([XFile(file.path)]);
  }

  Widget buildContent() {
    switch (widget.title) {
      case "Text":
        return buildField(
          "Enter text",
          textController,
          maxLines: 6,
        );

      case "Website":
        return buildField(
          "Enter website URL",
          textController,
        );

      case "Wi-Fi":
        return Column(
          children: [
            buildField(
              "SSID / Network name",
              textController,
            ),
            buildField(
              "Password",
              phoneController,
            ),
            DropdownButtonFormField(
              value: wifiType,
              dropdownColor:
              const Color(0xFF1E2235),
              style:
              const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor:
                const Color(0xFF1E2235),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "WPA/WPA2",
                  child: Text("WPA/WPA2"),
                ),
                DropdownMenuItem(
                  value: "WEP",
                  child: Text("WEP"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  wifiType = value!;
                });
              },
            ),
          ],
        );

      case "Contacts":
        return Column(
          children: [
            buildField(
                "Full name", nameController),
            buildField(
                "Organisation", orgController),
            buildField(
                "Address", addressController),
            buildField(
                "Phone", phoneController),
            buildField(
                "Email", emailController),
            buildField(
              "Notes",
              notesController,
              maxLines: 4,
            ),
          ],
        );

      case "Phone":
        return buildField(
          "Enter phone number",
          phoneController,
        );

      case "E-mail":
        return Column(
          children: [
            buildField(
                "Email address",
                emailController),
            buildField(
                "Subject", subjectController),
            buildField(
              "Body",
              bodyController,
              maxLines: 5,
            ),
          ],
        );

      case "SMS":
        return Column(
          children: [
            buildField(
                "Phone number",
                phoneController),
            buildField(
              "Message",
              bodyController,
              maxLines: 5,
            ),
          ],
        );

      case "Calendar":
        return Column(
          children: [
            buildField(
                "Event", eventController),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    pickDate(true),
                child: Text(
                  startDate == null
                      ? "Choose Start Date"
                      : startDate
                      .toString()
                      .split(" ")[0],
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    pickDate(false),
                child: Text(
                  endDate == null
                      ? "Choose End Date"
                      : endDate
                      .toString()
                      .split(" ")[0],
                ),
              ),
            ),

            const SizedBox(height: 14),

            buildField(
                "Location",
                locationController),

            buildField(
              "Description",
              descriptionController,
              maxLines: 5,
            ),
          ],
        );

      case "My Card":
        return Column(
          children: [
            buildField(
                "My name", nameController),
            buildField(
                "Phone", phoneController),
            buildField(
                "Email", emailController),
            buildField(
                "Address", addressController),
            buildField(
                "Birthday", birthdayController),
            buildField(
                "Organisation", orgController),
            buildField(
              "Notes",
              notesController,
              maxLines: 4,
            ),
          ],
        );

      case "Whatsapp":
        return Column(
          children: [
            buildField(
                "Country code",
                countryController),
            buildField(
                "Phone number",
                phoneController),
          ],
        );

      case "Instagram":
        return buildField(
          "Instagram URL or ID",
          textController,
        );

      case "Facebook":
        return buildField(
          "Facebook URL or ID",
          textController,
        );

      case "Youtube":
        return buildField(
          "Channel URL or Video URL",
          textController,
        );

      case "Spotify":
        return buildField(
          "Spotify URL",
          textController,
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              widget.icon,
              color: Colors.blue,
              size: 70,
            ),

            const SizedBox(height: 14),

            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            buildContent(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: generateQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Generate QR",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (qrData.isNotEmpty)
              Column(
                children: [
                  Screenshot(
                    controller:
                    screenshotController,
                    child: Container(
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                            20),
                      ),
                      child: QrImageView(
                        data: qrData,
                        size: 220,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child:
                        ElevatedButton.icon(
                          onPressed: saveQR,
                          icon: const Icon(
                              Icons.download),
                          label: const Text(
                              "Save"),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child:
                        ElevatedButton.icon(
                          onPressed: shareQR,
                          icon: const Icon(
                              Icons.share),
                          label:
                          const Text("Share"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}