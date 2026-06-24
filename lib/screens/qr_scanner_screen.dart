import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telebirrbybr7/screens/bank_amount_page.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool hasPermission = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  // Request camera access on first launch
  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status.isGranted;
    });
  }

  // THE MAIN FLOW: Scan -> Wait 4s -> Fetch Saved Data -> Navigate
  Future<void> _processScan() async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });

    // 1. Wait for 4 seconds as requested
    await Future.delayed(const Duration(seconds: 4));

    // 2. Access the data saved from the Apps Page
    final prefs = await SharedPreferences.getInstance();
    String savedName = prefs.getString('saved_name') ?? 'No Name Saved';
    String savedAccount = prefs.getString('saved_account') ?? '0000000000';
    String savedBank = prefs.getString('saved_bank') ?? '';

    if (!mounted) return;

    // 3. Proceed to BankAmountPage with the saved data and flag active
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BankAmountPage(
          accountName: savedName,
          accountNumber: savedAccount,
          bankName: savedBank,
          isFromQr: true, // <-- Added parameter to trigger custom receipt flow
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              _processScan();
            },
          ),

          // 2. Dimmable Overlay with Cutout (Matching your screenshot)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(color: Colors.black),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. UI Elements (Brackets, Text, and Buttons)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    padding: const EdgeInsets.all(20),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const Spacer(),

                // Scanner Frame Brackets
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(painter: BracketPainter()),
                  ),
                ),

                const SizedBox(height: 30),

                // Dynamic Status Text
                Text(
                  isProcessing 
                      ? "Processing payment details..." 
                      : "Align QR code within frame to scan",
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),

                // Loading indicator during the 4-second wait
                if (isProcessing) 
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                const Spacer(),

                // Bottom Controls (Light and Gallery)
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(Icons.flashlight_on_outlined, "Light", () {
                        controller.toggleTorch();
                      }),
                      _buildBottomAction(Icons.image_outlined, "Gallery", () {
                        // Gallery logic can go here
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 38),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double l = 25;

    // Top Left
    canvas.drawLine(Offset.zero, const Offset(l, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, l), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), paint);
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - l, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - l), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
