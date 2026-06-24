import 'package:flutter/material.dart';
import 'dart:async';
import 'success_page.dart';
import 'package:telebirrbybr7/services/notification_service.dart';

class ProcessingPage extends StatefulWidget {
  final String amount;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final bool isFromQr; // <-- Added flag to complete the pipeline context cleanly

  const ProcessingPage({
    super.key,
    required this.amount,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.isFromQr = false, // Defaults to false to keep your original flow intact
  });

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  @override
  void initState() {
    super.initState();

    // Trigger notification immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.showTransferSuccess(
        amount: widget.amount,
      );

      // 1. Shorter delay configuration: Reduced from 3 seconds to 1 second
      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessPage(
              amount: widget.amount,
              accountName: widget.accountName,
              accountNumber: widget.accountNumber,
              bankName: widget.bankName,
              isFromQr: widget.isFromQr, // <-- Seamlessly forwards pipeline state to success screen
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF8DC73F);
    final Color processingCustomColor = const Color(0xFF00B578); // 3. Custom color match: #00B578

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 2. Shift layout down globally by exactly 30px from the top safe area
            const SizedBox(height: 30),

            // Processing Icon and Text Layout Block
            Column(
              children: [
                CircleAvatar(
                  radius: 22, // 2. Made processing logo smaller (shrunk from 30)
                  backgroundColor: processingCustomColor, // 3. Set background to #00B578
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white, 
                    size: 26, // 2. Scaled down icon asset dynamically (shrunk from 35)
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Processing",
                  style: TextStyle(
                      color: processingCustomColor, // 3. Set text style to #00B578
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 60), // 2. Space between line and logo group kept perfectly intact
            const Divider(
                indent: 30, endIndent: 30, color: Color(0xFFEEEEEE)),

            const Spacer(),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: SizedBox(
                width: 200,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Finished",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
