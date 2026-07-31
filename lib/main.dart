import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';
import 'screens/generator_screen.dart';
import 'profile/profile_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart';
import 'authentication/login_screen.dart';
import 'authentication/verify_email_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Only initialize absolute essentials blocking the app entry
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    dotenv.load(fileName: ".env"),
  ]);

  // 2. Initialize non-critical SDKs in the background without blocking runApp
  _initBackgroundServices();

  runApp(const MyApp());
}

void _initBackgroundServices() async {
  try {
    await MobileAds.instance.initialize();

    // Configure Email OTP after dotenv is loaded
    EmailOTP.config(
      appName: 'Quick Qr',
      otpType: OTPType.numeric,
      expiry: 300000, // 5 minutes in milliseconds
      otpLength: 6,
      emailTheme: EmailTheme.v1,
    );

    EmailOTP.setSMTP(
      host: 'smtp.gmail.com',
      emailPort: EmailPort.port587,
      secureType: SecureType.tls,
      username: dotenv.env['EMAIL_USERNAME'] ?? '',
      password: dotenv.env['EMAIL_PASSWORD'] ?? '',
    );
  } catch (e) {
    debugPrint("Background service initialization error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      routes: {
        "/login": (_) => const LoginScreen(),
        "/verify": (_) => const VerifyEmailScreen(name: '', email: '', password: ''),
        "/home": (_) => const Home(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white, // Or match your splash background
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return const Home();
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;

  final List<Widget> screens = const [
    ScannerScreen(),
    GeneratorScreen(),
    ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache asset images to avoid frame drops on first tab switch
    precacheImage(const AssetImage("assets/icons/scan.png"), context);
    precacheImage(const AssetImage("assets/icons/generate.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: index,
                onTap: (i) => setState(() => index = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.greenAccent,
                unselectedItemColor: Colors.white60,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: Image.asset("assets/icons/scan.png", width: 24, color: index == 0 ? Colors.greenAccent : Colors.white60),
                    label: "Scan",
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset("assets/icons/generate.png", width: 24, color: index == 1 ? Colors.greenAccent : Colors.white60),
                    label: "Generate",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}