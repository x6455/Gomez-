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
  bool _unlocked = false;
  int _homeTapCount = 0;
  DateTime? _lastTapTime;

  final List<Widget> tabs = [
    const HomeScreen(),
    Center(child: Image.asset('images/payment.png')),
    const AppsPage(),
    const EngagePage(),
    Center(child: Image.asset('images/account.png')),
  ];

  void _handleTabChange(int index) {
    if (index == 0) {
      final now = DateTime.now();
      
      if (_lastTapTime != null && 
          now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
        _homeTapCount = 0;
      }
      
      _homeTapCount++;
      _lastTapTime = now;
      
      if (_homeTapCount >= 3) {
        setState(() {
          _unlocked = !_unlocked;
          _homeTapCount = 0;
        });
      }
      
      setState(() => _currentIndex = index);
      
    } else if (_unlocked) {
      setState(() => _currentIndex = index);
      
    } else {
      _showLoadingDialog(context);
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog(context);
        }
      });
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                'images/loading.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'System Busy. Please try again later.',
                style: TextStyle(color: Colors.black87, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _currentIndex = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: TelebirrBottomBar(
        currentIndex: _currentIndex,
        onTap: _handleTabChange,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
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