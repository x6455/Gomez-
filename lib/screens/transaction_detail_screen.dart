import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> txData;

  const TransactionDetailScreen({super.key, required this.txData});

  Future<void> _handleGetReceipt() async {
final String baseUrl = "http://transactioninfo-ethiotelecom-et.duckdns.org:3008/transaction-ethiotelecom-et";
    final Uri url = Uri.parse(baseUrl).replace(queryParameters: {
      'txID': txData['txID'] ?? "N/A",
      'time': txData['time'] ?? "",
      'amount_sent': txData['amount_sent']?.toString() ?? "0.00",
      'service_charge': txData['service_charge']?.toString() ?? "0.00",
      'vat_0_3_percent': txData['vat_0_3_percent']?.toString() ?? "0.00",
      'total_deducted': txData['total_deducted']?.toString() ?? "0",
      'bankName': txData['bankName'] ?? "N/A",
      'accountName': txData['accountName'] ?? "N/A",
      'accountNumber': txData['accountNumber'] ?? "N/A",
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Transaction Detail",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.more_horiz, color: Colors.black, size: 20),
                SizedBox(width: 8),
                VerticalDivider(width: 1, indent: 5, endIndent: 5),
                SizedBox(width: 8),
                Icon(Icons.cancel_outlined, color: Colors.black, size: 20),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 15.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _handleGetReceipt,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/receipt.jpg',
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Get Receipt",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
