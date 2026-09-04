import 'package:flutter/material.dart';
import 'dart:async';
import 'success_page.dart';
import 'package:telebirrbybr7/services/notification_service.dart';

class ProcessingPage extends StatefulWidget {
  final String amount;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final bool isFromQr;
  final bool isTelebirrTransfer; // New flag

  const ProcessingPage({
    super.key,
    required this.amount,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.isFromQr = false,
    this.isTelebirrTransfer = false, // Default false
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
              isFromQr: widget.isFromQr,
              isTelebirrTransfer: widget.isTelebirrTransfer, // Pass along
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF8DC73F);
    final Color processingCustomColor = const Color(0xFF00B578);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Processing Icon and Text Layout Block
            Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: processingCustomColor,
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white, 
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Processing",
                  style: TextStyle(
                      color: processingCustomColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 60),
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
