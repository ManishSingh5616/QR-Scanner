import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/qr_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  void loadBannerAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        bottom: false,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            // Optimized transition duration for snappier performance
                            transitionDuration: const Duration(milliseconds: 200),
                            reverseTransitionDuration: const Duration(milliseconds: 150),
                            pageBuilder: (_, animation, __) => QRFormPage(
                              title: item["title"] as String,
                              icon: item["icon"] as IconData,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item["icon"] as IconData,
                                  color: Colors.greenAccent,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item["title"] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _QRFormPageState extends State<QRFormPage> with SingleTickerProviderStateMixin {
  String qrData = "";

  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController scrollController = ScrollController();

  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController orgController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  String wifiType = "WPA/WPA2";
  String? currentHistoryId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Pre-fill prefixes for Instagram and Youtube if required
    if (widget.title == "Instagram") {
      textController.text = "https://instagram.com/";
    } else if (widget.title == "Youtube") {
      textController.text = "https://youtube.com/";
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    scrollController.dispose();
    textController.dispose();
    nameController.dispose();
    orgController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    subjectController.dispose();
    bodyController.dispose();
    eventController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    birthdayController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Widget buildField(
      String hint,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.greenAccent,
                  width: 1.5,
                ),
              ),
            ),
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

  Future<void> generateQR() async {
    FocusScope.of(context).unfocus();

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
        qrData = "WIFI:T:$wifiType;S:${textController.text};P:${phoneController.text};;";
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
        qrData = "mailto:${emailController.text}?subject=${subjectController.text}&body=${bodyController.text}";
        break;
      case "SMS":
        qrData = "sms:${phoneController.text}?body=${bodyController.text}";
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
        qrData = "https://wa.me/${countryController.text}${phoneController.text}";
        break;
      case "Instagram":
        String val = textController.text.trim();
        if (val.startsWith("https://instagram.com/https://instagram.com/")) {
          val = val.replaceFirst("https://instagram.com/https://instagram.com/", "https://instagram.com/");
        }
        if (!val.startsWith("http")) {
          qrData = "https://instagram.com/$val";
        } else {
          qrData = val;
        }
        break;
      case "Facebook":
        qrData = textController.text.startsWith("http")
            ? textController.text
            : "https://facebook.com/${textController.text}";
        break;
      case "Youtube":
        String val = textController.text.trim();
        if (val.startsWith("https://youtube.com/https://youtube.com/")) {
          val = val.replaceFirst("https://youtube.com/https://youtube.com/", "https://youtube.com/");
        }
        if (!val.startsWith("http")) {
          qrData = "https://youtube.com/$val";
        } else {
          qrData = val;
        }
        break;
      case "Spotify":
        qrData = textController.text;
        break;
    }

    currentHistoryId = await QRService.instance.recordGenerated(
      qrType: widget.title,
      title: nameController.text.isNotEmpty ? nameController.text : widget.title,
      data: qrData,
    );

    setState(() {});

    _animationController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 100));
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> saveQR() async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/qr.png');
    await file.writeAsBytes(image);
    await GallerySaver.saveImage(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR saved to gallery")),
    );
  }

  Future<void> shareQR() async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/qr.png');
    await file.writeAsBytes(image);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Widget buildContent() {
    switch (widget.title) {
      case "Text":
        return buildField("Enter text", textController, maxLines: 6);
      case "Website":
        return buildField("Enter website URL", textController);
      case "Wi-Fi":
        return Column(
          children: [
            buildField("SSID / Network name", textController),
            buildField("Password", phoneController),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      value: wifiType,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: "WPA/WPA2", child: Text("WPA/WPA2")),
                        DropdownMenuItem(value: "WEP", child: Text("WEP")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          wifiType = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case "Contacts":
        return Column(
          children: [
            buildField("Full name", nameController),
            buildField("Organisation", orgController),
            buildField("Address", addressController),
            buildField("Phone", phoneController),
            buildField("Email", emailController),
            buildField("Notes", notesController, maxLines: 4),
          ],
        );
      case "Phone":
        return buildField("Enter phone number", phoneController);
      case "E-mail":
        return Column(
          children: [
            buildField("Email address", emailController),
            buildField("Subject", subjectController),
            buildField("Body", bodyController, maxLines: 5),
          ],
        );
      case "SMS":
        return Column(
          children: [
            buildField("Phone number", phoneController),
            buildField("Message", bodyController, maxLines: 5),
          ],
        );
      case "Calendar":
        return Column(
          children: [
            buildField("Event", eventController),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => pickDate(true),
                child: Text(startDate == null ? "Choose Start Date" : startDate.toString().split(" ")[0]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => pickDate(false),
                child: Text(endDate == null ? "Choose End Date" : endDate.toString().split(" ")[0]),
              ),
            ),
            const SizedBox(height: 14),
            buildField("Location", locationController),
            buildField("Description", descriptionController, maxLines: 5),
          ],
        );
      case "My Card":
        return Column(
          children: [
            buildField("My name", nameController),
            buildField("Phone", phoneController),
            buildField("Email", emailController),
            buildField("Address", addressController),
            buildField("Birthday", birthdayController),
            buildField("Organisation", orgController),
            buildField("Notes", notesController, maxLines: 4),
          ],
        );
      case "Whatsapp":
        return Column(
          children: [
            buildField("Country code", countryController),
            buildField("Phone number", phoneController),
          ],
        );
      case "Instagram":
        return buildField("Instagram URL or ID", textController);
      case "Facebook":
        return buildField("Facebook URL or ID", textController);
      case "Youtube":
        return buildField("Channel URL or Video URL", textController);
      case "Spotify":
        return buildField("Spotify URL", textController);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            Icon(
              widget.icon,
              color: Colors.greenAccent,
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
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Generate QR",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (qrData.isNotEmpty)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Screenshot(
                            controller: screenshotController,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: qrData,
                                size: 220,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: saveQR,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text("Save"),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: shareQR,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}