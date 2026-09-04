import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_dialog.dart';
import 'package:telebirrbybr7/services/name_formatter.dart';

class BankAmountPage extends StatefulWidget {
  final String accountName;
  final String accountNumber;
  final String bankName;
  final bool isFromQr;
  final bool isTelebirrTransfer; // New flag

  const BankAmountPage({
    super.key,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    this.isFromQr = false,
    this.isTelebirrTransfer = false, // Default false
  });

  @override
  State<BankAmountPage> createState() => _BankAmountPageState();
}

class _BankAmountPageState extends State<BankAmountPage> {
  String _amount = "";
  bool _showCursor = true;
  Timer? _cursorTimer;

  final Color _primaryGreen = const Color(0xFF8DC73F);
  final Color _purpleColor = const Color(0xFFA349E5);
  
  // Balance variables
  double _currentBalance = 0.0;
  final double _initialBalance = 176864.00;
  bool _balanceLoaded = false;

  final Map<String, Color> _bankColors = {
    'CBE': const Color(0xFFA349E5),
    'Awash Bank': const Color(0xFF2A2A9D),
    'Dashen Bank': const Color(0xFF012169),
    'Bank of Abyssinia': const Color(0xFFE6A115),
  };

  final Map<String, String> _bankLogos = {
    'CBE': 'images/cbe.png',
    'Awash Bank': 'images/Awash.png',
    'Dashen Bank': 'images/dashen.png',
    'Bank of Abyssinia': 'images/abyssinia.jpg',
  };

  Color _getBankColor(String bankName) {
    if (bankName.isEmpty) return Colors.white;
    return _bankColors[bankName] ?? _purpleColor;
  }

  String _getBankLogo(String bankName) {
    if (bankName.isEmpty) return '';
    return _bankLogos[bankName] ?? 'images/cbe.png';
  }

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    super.dispose();
  }

  // Load balance from SharedPreferences
  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    double balance = prefs.getDouble('remaining_balance') ?? _initialBalance;
    
    if (mounted) {
      setState(() {
        _currentBalance = balance;
        _balanceLoaded = true;
      });
    }
  }

  // Refresh balance when returning to this page
  Future<void> _refreshBalance() async {
    await _loadBalance();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == "back") {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (value == ".") {
        if (!_amount.contains(".")) {
          _amount += value;
        }
      } else {
        _amount += value;
      }
    });
  }

  void _showConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Text(
                widget.isTelebirrTransfer ? "Transfer Money" : "Transfer To Bank",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatAmount(_amount),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "ETB",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: _primaryGreen, size: 28),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Payment Method",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Balance",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "(Available Balance:ETB)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle, color: _primaryGreen, size: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      PinDialog.show(
                        context, 
                        amount: _amount.isEmpty ? "0.00" : _amount, 
                        primaryGreen: _primaryGreen,
                        accountName: widget.accountName,
                        accountNumber: widget.accountNumber,
                        bankName: widget.bankName,
                        isFromQr: widget.isFromQr,
                        isTelebirrTransfer: widget.isTelebirrTransfer, // Pass along
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Transfer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _refreshBalance();
    });
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return "0.00";

    final number = double.tryParse(value);
    if (number == null) return "0.00";

    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(number);
  }
  
  String _formatBalance(double balance) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(balance);
  }

  @override
  Widget build(BuildContext context) {
    const Color themeBgColor = Color(0xFFF5F5F5);
    final bankColor = _getBankColor(widget.bankName);
    final bankLogo = _getBankLogo(widget.bankName);
    final hasBank = widget.bankName.isNotEmpty && !widget.isTelebirrTransfer;

    return Scaffold(
      backgroundColor: themeBgColor,
      appBar: AppBar(
        backgroundColor: themeBgColor,
        elevation: 0,
        title: Text(
          widget.isTelebirrTransfer ? 'Transfer Money' : 'Transfer to Bank',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.isTelebirrTransfer ? Colors.white : (hasBank ? bankColor : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: widget.isTelebirrTransfer
                              ? Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: _primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.person, color: _primaryGreen, size: 20),
                                )
                              : hasBank
                                  ? Container(
                                      width: 35,
                                      height: 35,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Image.asset(
                                          bankLogo,
                                          errorBuilder: (c, e, s) =>
                                              Icon(Icons.account_balance, color: bankColor),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.grey, size: 20),
                                    ),
                          title: Text(
                            NameFormatter.format(widget.accountName),
                            style: TextStyle(
                              color: widget.isTelebirrTransfer ? Colors.black : (hasBank ? Colors.white : Colors.black), 
                              fontWeight: FontWeight.bold, 
                              fontSize: 18
                            ),
                          ),
                          subtitle: widget.isTelebirrTransfer
                              ? Text(
                                  widget.accountNumber,
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                )
                              : hasBank
                                  ? Text(
                                      "${widget.bankName} (${widget.accountNumber})",
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                    )
                                  : Text(
                                      widget.accountNumber,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Amount", style: TextStyle(color: Colors.black, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _amount,
                                    style: const TextStyle(
                                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  const SizedBox(width: 2),
                                  Opacity(
                                    opacity: _showCursor ? 1.0 : 0.0,
                                    child: Container(
                                      width: 1.5,
                                      height: 32,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text("(ETB)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Divider(thickness: 0.5, height: 30, color: Colors.grey.withOpacity(0.2)),
                              Text(
                                "Balance: ${_formatBalance(_currentBalance)}(ETB)",
                                style: const TextStyle(
                                  color: Color(0xFF4A6572),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Add notes(optional)",
                      style: TextStyle(color: _primaryGreen, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CUSTOM KEYBOARD
          Container(
            padding: const EdgeInsets.all(3),
            color: themeBgColor,
            height: 235,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _row(["1", "2", "3"]),
                      _row(["4", "5", "6"]),
                      _row(["7", "8", "9"]),
                      Expanded(
                        child: Row(
                          children: [
                            _buildKey("0", flex: 2),
                            _buildKey(".", flex: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildKey("back", isAction: true),
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          child: Material(
                            color: (_amount.isNotEmpty &&
                                    double.tryParse(_amount) != null &&
                                    double.parse(_amount) > 0)
                                ? _primaryGreen
                                : _primaryGreen.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                            child: InkWell(
                              onTap: (_amount.isNotEmpty &&
                                      double.tryParse(_amount) != null &&
                                      double.parse(_amount) > 0)
                                  ? _showConfirmationBottomSheet
                                  : null,
                              child: const Center(
                                child: Text("Transfer",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((k) => _buildKey(k)).toList(),
      ),
    );
  }

  Widget _buildKey(String label, {int flex = 1, bool isAction = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(3),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _onKeyTap(label),
            child: Center(
              child: label == "back"
                  ? const Icon(Icons.backspace_outlined, color: Colors.black54)
                  : Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
