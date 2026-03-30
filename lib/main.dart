import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';
import 'screens/generator_screen.dart';
import 'screens/history_screen.dart';

void main() {
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
      home: const Home(),
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
    HistoryScreen(),
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
            icon: Image.asset("assets/icons/history.png", width: 24),
            label: "History",
          ),
        ],
      ),
    );
  }
}