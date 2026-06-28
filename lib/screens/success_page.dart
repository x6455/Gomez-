import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_sender.dart'; // Native MethodChannel SMS sender
import 'package:telebirrbybr7/services/recent_transfers_service.dart';
import 'package:http/http.dart' as http;
import 'package:telebirrbybr7/services/name_formatter.dart';
import 'package:telebirrbybr7/screens/main_screen.dart'; // Make sure this path matches your directory setup


class SuccessPage extends StatefulWidget {
  final String amount;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final bool isFromQr; // <-- Added flag to intercept the QR pipeline safely

  const SuccessPage({
    super.key,
    required this.amount,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.isFromQr = false, // Defaults to false so your manual flow is untouched
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  int _currentIndex = 0;
  late final String _transactionID;
  late final String _txTime;
  bool _smsSent = false;
  bool _smsFailed = false;

  // --- BALANCE CONFIGURATION ---
  double _currentBalance = 0.0;
  final double _initialBalance = 45894.00; // Starting Value
  final double _resetThreshold = 100.00;   // Reset trigger point
  // -----------------------------

  static const String serverUrl = "http://148.116.91.16:3000";

  final List<String> sliderImages = [
    'images/Banner1.jpg',
    'images/Banner2.jpg',
    'images/Banner3.jpg',
    'images/Banner4.jpg',
    'images/Banner5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _transactionID = _generateTransactionID();
    _txTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
    
    // Start the balance and storage logic
    _loadAndProcessBalance();
  }

  /// Handles loading, deducting, resetting, and saving the balance
  Future<void> _loadAndProcessBalance() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Get current balance or use initial value if first time
    double balance = prefs.getDouble('remaining_balance') ?? _initialBalance;
    
    // 2. Calculate deductions
    final charges = _calculateCharges(widget.amount);
    double totalDeducted = charges['total']!;

    // 3. Subtract from balance
    balance -= totalDeducted;

    // 4. Check for Reset Threshold
    if (balance < _resetThreshold) {
      balance = _initialBalance;
      debugPrint("Balance hit threshold. Resetting to $_initialBalance");
    }

    // 5. Update UI and Save to Storage
    setState(() {
      _currentBalance = balance;
    });
    await prefs.setDouble('remaining_balance', balance);

    // 6. Save the history record and trigger SMS
    await _saveTransactionLocally();
    Future.delayed(const Duration(seconds: 2), _trySendSMS);
  }

  double _roundToZeroCents(double value) {
    return value.roundToDouble();
  }

  Map<String, double> _calculateCharges(String amount) {
    final double sent = double.parse(amount.replaceAll(',', ''));
    
    // Determine flat fee based on band
    double totalFee;
    if (sent < 100) {
      totalFee = 1.0;
    } else if (sent <= 500) {
      totalFee = 2.0;
    } else if (sent <= 1500) {
      totalFee = 4.0;
    } else if (sent <= 5000) {
      totalFee = 6.0;
    } else if (sent <= 75000) {
      totalFee = 8.0;
    } else {
      totalFee = 8.0;
    }
    
    // Split fee: VAT = Fee / 1.15, Service Charge = Fee - VAT
    double finalVat = totalFee / 1.15;
    double finalService = totalFee - finalVat;
    
    double total = sent + totalFee;
    final double adjustedTotal = _roundToZeroCents(total);
    final double adjustment = adjustedTotal - total;
    final double adjustedServiceCharge = finalService + adjustment;

    return {
      'sent': sent,
      'vat': finalVat,
      'service': adjustedServiceCharge,
      'total': adjustedTotal,
    };
  }

  // Save transaction to server
  Future<void> _saveTransactionToServer(Map<String, dynamic> transactionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? 'unknown';
      final phoneNumber = prefs.getString('lastPhoneNumber') ?? '';
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': deviceId,
          'txID': transactionData['txID'],
          'time': transactionData['time'],
          'amount_sent': transactionData['amount_sent'],
          'vat': transactionData['vat_0_3_percent'],
          'service_charge': transactionData['service_charge'],
          'total_deducted': transactionData['total_deducted'],
          'accountName': transactionData['accountName'],
          'accountNumber': transactionData['accountNumber'],
          'bankName': transactionData['bankName'],
          'remaining_balance': transactionData['remaining_balance'],
          'phoneNumber': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        print("✓ Transaction saved to server: ${transactionData['txID']}");
      } else {
        print("✗ Failed to save transaction to server: ${response.statusCode}");
      }
    } catch (e) {
      print("✗ Error saving transaction to server: $e");
    }
  }

  Future<void> _saveTransactionLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final charges = _calculateCharges(widget.amount);

    Map<String, String> transactionData = {
      'txID': _transactionID,
      'time': _txTime,
      'amount_sent': charges['sent']!.toStringAsFixed(2),
      'vat_0_3_percent': charges['vat']!.toStringAsFixed(2),
      'service_charge': charges['service']!.toStringAsFixed(2),
      'total_deducted': charges['total']!.toStringAsFixed(0),
      'accountName': widget.accountName,
      'accountNumber': widget.accountNumber,
      'bankName': widget.bankName,
      'smsSent': _smsSent.toString(),
      'remaining_balance': _currentBalance.toStringAsFixed(2),
    };

    List<String> history = prefs.getStringList('sent_balances') ?? [];
    history.add(jsonEncode(transactionData));
    await prefs.setStringList('sent_balances', history);

    await RecentTransfersService.add(
      accountName: widget.accountName,
      bankName: widget.bankName,
      accountNumber: widget.accountNumber,
    );

    await _saveTransactionToServer(transactionData);
  }

  Future<void> _trySendSMS() async {
    final String phoneNumber = "0974814108";
    final charges = _calculateCharges(widget.amount);
    
    final String formattedBalance = NumberFormat('#,##0.00', 'en_US').format(_currentBalance);

    final String message = 
    "Dear WALID\n" +
    "You have transferred ETB ${widget.amount} successfully from your telebirr account 251974814108 to ${widget.bankName} account number ${widget.accountNumber} on $_txTime. Your telebirr transaction number is $_transactionID and your bank transaction number is FT253604LV4H. The service fee is ETB ${charges['vat']!.toStringAsFixed(2)} and 15% VAT on the service fee is ETB ${charges['service']!.toStringAsFixed(2)}. Your current balance is ETB $formattedBalance. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/$_transactionID\n" +
    "Thank you for using telebirr\n" +
    "Ethio telecom";

    try {
      await SmsSender.sendSms(phoneNumber, message);
      _updateSMSStatus(true, "SMS sent successfully");
    } catch (e) {
      _updateSMSStatus(false, "SMS Error: ${e.toString()}");
    }
  }

  void _updateSMSStatus(bool success, String message) async {
    if (mounted) {
      setState(() {
        _smsSent = success;
        _smsFailed = !success;
      });

      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('sent_balances') ?? [];
      if (history.isNotEmpty) {
        String lastTx = history.last;
        Map<String, dynamic> txData = jsonDecode(lastTx);
        txData['smsSent'] = success.toString();
        history[history.length - 1] = jsonEncode(txData);
        await prefs.setStringList('sent_balances', history);
      }
    }
  }

  String _generateTransactionID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = math.Random();

    final randomPart = List.generate(
      8,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();

    return 'DF$randomPart';
  }

  String _formatNumber(String number) {
    try {
      String cleanNumber = number.replaceAll(',', '');
      double value = double.parse(cleanNumber);
      return NumberFormat('#,##0', 'en_US').format(value);
    } catch (e) {
      return number;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF8DC73F);
    final charges = _calculateCharges(widget.amount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.file_download_outlined, color: primaryGreen, size: 20),
            const SizedBox(width: 4),
            Text("Download", style: TextStyle(color: primaryGreen, fontSize: 14)),
            const Spacer(),
            Icon(Icons.share_outlined, color: primaryGreen, size: 20),
            const SizedBox(width: 4),
            Text("Share", style: TextStyle(color: primaryGreen, fontSize: 14)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryGreen,
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 13),
            Text("Successful", style: TextStyle(color: primaryGreen, fontSize: 18)),
            const SizedBox(height: 28),
            
            // Text presentation matched to image layout: -Amount (ETB)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "-${_formatNumber(charges['total']!.toString())}.00",
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 5),
                const Text("(ETB)", style: TextStyle(fontSize: 16, color: Colors.black)),
              ],
            ),
            const SizedBox(height: 28),
            const Divider(indent: 20, endIndent: 20),
            const SizedBox(height: 13),

            // CONDITIONAL BLOCK: Dynamic Row Arrangement matching layout profiles
            if (widget.isFromQr) ...[
              // Exact structural breakdown matching IMG_20260624_203105_959.jpg
              _detailRow("Transaction Time:", _txTime),
              _detailRow("Transaction Type:", "Buy Goods"),
              _detailRow("Transaction To:", NameFormatter.format(widget.accountName)),
              _detailRow("Transaction Number:", _transactionID),
              const SizedBox(height: 20),
              
                            // Multi-Action Row: Moved to the right, coin icon, space instead of divider
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Moves it to the right side
                children: [
                  Icon(Icons.monetization_on_outlined, color: primaryGreen, size: 22), // Changed to stacked coin style icon
                  const SizedBox(width: 4),
                  Text(
                    "Give Tip", 
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15), // Kept bold
                  ),
                  const SizedBox(width: 10), // Plain space layout instead of the "|" divider line
                  Icon(Icons.qr_code_2, color: primaryGreen, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    "QR Code", 
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 15), // Kept bold
                  ),
                  const SizedBox(width: 20), // Trimming offset to match the right edge padding
                ],
              ),

            ] else ...[
              // Standard Legacy Bank Routing View
              _detailRow("Transaction Number", _transactionID),
              _detailRow("Transaction Time:", _txTime),
              _detailRow("Transaction Type:", "Transfer To Bank"),
              _detailRow("Transaction To:", NameFormatter.format(widget.accountName)),
              _detailRow("Bank Account Number:", widget.accountNumber),
              _detailRow("Bank Name:", widget.bankName),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.qr_code_2, color: primaryGreen, size: 20),
                  Text(" QR Code ", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.normal)),
                  Icon(Icons.arrow_forward_ios, color: primaryGreen, size: 14),
                  const SizedBox(width: 15),
                ],
              ),
            ],

            const SizedBox(height: 13),
            CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                aspectRatio: 3.5,
                viewportFraction: 0.92,
                onPageChanged: (index, reason) => setState(() => _currentIndex = index),
              ),
              items: sliderImages.map((imagePath) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sliderImages.length, (i) {
                  final isActive = i == _currentIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 1.0),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 4.0 : 0,
                        height: isActive ? 4.0 : 0,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 25),

            // CONDITIONAL BLOCK: Bottom Navigation buttons switching matrix
            if (widget.isFromQr) ...[
              // Dual Horizontal Control Buttons (Bill Share / OK) from visual reference
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryGreen, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Bill Share", style: TextStyle(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
  child: SizedBox(
    height: 46,
    child: ElevatedButton(
      onPressed: () {
        // Clears the history stack and opens a fresh MainScreen starting at the Home tab
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("OK", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  ),
),

                  ],
                ),
              ),
            ] else ...[
              // Original Centered Legacy Confirmation Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: SizedBox(
                  width: 200,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Finished", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
