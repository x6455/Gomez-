import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telebirrbybr7/screens/transaction_detail_screen.dart';

class TransactionMessagesScreen extends StatefulWidget {
  const TransactionMessagesScreen({super.key});

  @override
  State<TransactionMessagesScreen> createState() => _TransactionMessagesScreenState();
}

class _TransactionMessagesScreenState extends State<TransactionMessagesScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('sent_balances') ?? [];

    // Load seen status
    final List<String> seenTxIDs = prefs.getStringList('seen_transactions') ?? [];

    setState(() {
      _transactions = history
          .map((item) {
            final tx = jsonDecode(item) as Map<String, dynamic>;
            // Mark as seen if in seen list
            tx['seen'] = seenTxIDs.contains(tx['txID']);
            return tx;
          })
          .toList()
          .reversed
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _markAsSeen(String txID) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> seenTxIDs = prefs.getStringList('seen_transactions') ?? [];
    if (!seenTxIDs.contains(txID)) {
      seenTxIDs.add(txID);
      await prefs.setStringList('seen_transactions', seenTxIDs);
    }
  }

  void _handleTransactionTap(Map<String, dynamic> tx) async {
    // Mark as seen immediately
    final txID = tx['txID'] as String;
    await _markAsSeen(txID);
    
    setState(() {
      tx['seen'] = true;
    });

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
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

    // Wait 2 seconds then navigate
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loader
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(txData: tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Transaction Message",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.black, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text("No transactions found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return _buildTransactionCard(tx);
                  },
                ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    return GestureDetector(
      onTap: () => _handleTransactionTap(tx),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.19),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF0056B3),
                      child: Icon(Icons.check, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Transfer to Bank",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "-${tx['amount_sent']}",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Red indicator - hidden when seen
                    if (tx['seen'] != true)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Perforated line
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _cutout(isLeft: true),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              (constraints.constrainWidth() / 8).floor(),
                              (index) => const SizedBox(
                                width: 4,
                                height: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEEEEEE),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _cutout(isLeft: false),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _infoRow("Transaction Time:", tx['time'] ?? ""),
                    const SizedBox(height: 6),
                    _infoRow("Transaction To:", tx['accountName']?.toUpperCase() ?? ""),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cutout({required bool isLeft}) {
    return Container(
      height: 20,
      width: 13,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.only(
          topRight: isLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: isLeft ? const Radius.circular(12) : Radius.zero,
          topLeft: !isLeft ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}