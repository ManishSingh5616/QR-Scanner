import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';
import 'screens/generator_screen.dart';
import 'profile/profile_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart'; // Make sure to import this

import 'authentication/login_screen.dart';
import 'authentication/verify_email_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  MobileAds.instance.initialize();

  // Configure Email OTP
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
    username: dotenv.env['EMAIL_USERNAME']!,
    password: dotenv.env['EMAIL_PASSWORD']!,
  );

  runApp(const MyApp());
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
        "/verify": (_) => const VerifyEmailScreen(name: '', email: '', password: ''), // Updated to accept argument if needed
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
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is not logged into Firebase, send to Login/OTP Request Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // If user is logged into Firebase, send straight to Home
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

  final screens = const [
    ScannerScreen(),
    GeneratorScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset("assets/icons/scan.png", width: 24),
            label: "Scan",
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/icons/generate.png", width: 24),
            label: "Generate",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}