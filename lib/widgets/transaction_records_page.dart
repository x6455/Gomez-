import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionRecordsPage extends StatefulWidget {
  const TransactionRecordsPage({super.key});

  @override
  State<TransactionRecordsPage> createState() => _TransactionRecordsPageState();
}

class _TransactionRecordsPageState extends State<TransactionRecordsPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = prefs.getStringList('sent_balances') ?? [];
    
    setState(() {
      _history = historyStrings
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList()
          .reversed // Newest items show up at the top
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color telebirrGreen = Color(0xFF8DC73F);
    const Color canvasGray = Color(0xFFF5F5F5);

    // Dynamically look up current month name (e.g., "June")
    final String currentMonthName = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: canvasGray,
      appBar: AppBar(
        backgroundColor: canvasGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Transaction History', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          // Authentic Mini-Program top right control capsule stack
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.more_horiz, color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Container(width: 1, height: 14, color: Colors.grey.shade300),
                const SizedBox(width: 10),
                const Icon(Icons.radio_button_checked, color: Colors.black, size: 18),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Option Pill Stack Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildCapsuleTab("Main", true, telebirrGreen),
                const SizedBox(width: 10),
                _buildCapsuleTab("Reward", false, telebirrGreen),
                const Spacer(),
                Icon(Icons.file_download_outlined, color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 14),
                Icon(Icons.tune, color: Colors.grey.shade600, size: 22),
              ],
            ),
          ),
          
          // 2. Metrics Summary Panel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: telebirrGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryColumn("Pay (ETB)", "-12052.00"),
                _buildSummaryColumn("Income (ETB)", "12052.00"),
                _buildSummaryColumn("Total (ETB)", "0.00"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Main Transaction List Container Card Layout
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: telebirrGreen))
                : _history.isEmpty 
                  ? const Center(child: Text("No records found", style: TextStyle(color: Colors.grey)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left-aligned dynamic Month Header Row
                        Padding(
                          padding: const EdgeInsets.only(left: 18, top: 16, bottom: 4),
                          child: Text(
                            currentMonthName,
                            style: const TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.w700, 
                              color: Colors.black
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _history.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1, 
                              color: Color(0xFFF2F2F2), 
                              indent: 72, 
                              endIndent: 16
                            ),
                            itemBuilder: (context, index) {
                              return _buildTransactionItem(_history[index]);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleTab(String label, bool isSelected, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final String amount = tx['amount_sent'] ?? "0.00";
    final String timeString = tx['time'] ?? "";
    String formattedDateTime = timeString;

    try {
      if (timeString.isNotEmpty) {
        DateTime parsedTime = DateTime.parse(timeString);
        // Formats to match mockup precision: dd-MM-yyyy HH:mm
        formattedDateTime = DateFormat('dd-MM-yyyy HH:mm').format(parsedTime);
      }
    } catch (e) {
      formattedDateTime = timeString;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(txData: tx),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF8DC73F), // Matching store green background token circular mask
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          title: const Text(
            "Transfer Money", 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF222222)), 
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              formattedDateTime, 
              style: const TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "-$amount",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "ETB",
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
