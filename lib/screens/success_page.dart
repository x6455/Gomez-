import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_sender.dart'; // Native MethodChannel SMS sender
import 'package:telebirrbybr7/services/recent_transfers_service.dart';

class SuccessPage extends StatefulWidget {
  final String amount;
  final String accountName;
  final String accountNumber;
  final String bankName;

  const SuccessPage({
    super.key,
    required this.amount,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
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
  final double _initialBalance = 76864.00; // Starting Value
  final double _resetThreshold = 1000.00;   // Reset trigger point
  // -----------------------------

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
    
    // Calculate raw VAT (0.3%) and Service Charge (15% of VAT)
    double rawVat = sent * 0.003;
    double rawServiceCharge = rawVat * 0.15;
    double combinedFees = rawVat + rawServiceCharge;

    double finalVat;
    double finalService;

    // Apply the 74.00 ETB CAP on the combined fees
    if (combinedFees > 74.0) {
      // If sum of VAT + Service exceeds 74, discard raw values and use cap
      // Split 74 ETB proportionally (VAT + 15% VAT = 74)
      finalVat = 74.0 / 1.15; 
      finalService = 74.0 - finalVat;
    } else {
      finalVat = rawVat;
      finalService = rawServiceCharge;
    }

    // Final total calculation with rounding adjustment
    double total = sent + finalVat + finalService;
    final double adjustedTotal = _roundToZeroCents(total);
    final double adjustment = adjustedTotal - total;
    
    // Apply rounding difference to the service charge for a clean total
    final double adjustedServiceCharge = finalService + adjustment;

    return {
      'sent': sent,
      'vat': finalVat,
      'service': adjustedServiceCharge,
      'total': adjustedTotal,
    };
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

    // Add to recent transfers
    await RecentTransfersService.add(
      accountName: widget.accountName,
      bankName: widget.bankName,
      accountNumber: widget.accountNumber,
    );
  }

  Future<void> _trySendSMS() async {
    final String phoneNumber = "0910105852";
    final charges = _calculateCharges(widget.amount);
    
    final String formattedBalance = NumberFormat('#,##0.00', 'en_US').format(_currentBalance);

    final String message = 
    "Dear DANIEL\n" +
    "You have transferred ETB ${widget.amount} successfully from your telebirr account 251910105852 to ${widget.bankName} account number ${widget.accountNumber} on $_txTime. Your telebirr transaction number is $_transactionID and your bank transaction number is FT253604LV4H. The service fee is ETB ${charges['vat']!.toStringAsFixed(2)} and 15% VAT on the service fee is ETB ${charges['service']!.toStringAsFixed(2)}. Your current balance is ETB $formattedBalance. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/$_transactionID\n" +
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
            _detailRow("Transaction Number", _transactionID),
            _detailRow("Transaction Time:", _txTime),
            _detailRow("Transaction Type:", "Transfer To Bank"),
            _detailRow("Transaction To:", widget.accountName.toUpperCase()),
            _detailRow("Bank Account Number:", widget.accountNumber),
            _detailRow("Bank Name:", widget.bankName),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.qr_code_2, color: primaryGreen, size: 20),
                Text(" QR Code ",
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_forward_ios, color: primaryGreen, size: 14),
                const SizedBox(width: 15),
              ],
            ),
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
            const SizedBox(height: 13),
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
            const SizedBox(height: 10),
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
