import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 Added url_launcher import

class TxDetail2 extends StatelessWidget {
  final Map<String, dynamic> txData;

  const TxDetail2({super.key, required this.txData});

  // 🔥 URL Launcher Receipt Mapping Logic
  Future<void> _handleGetReceipt() async {
    final String baseUrl = "http://127.0.0.1:3000/transaction-ethiotelecom-et";
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
    const Color telebirrGreen = Color(0xFF8DC73F);
    const Color canvasGray = Color(0xFFF5F5F5);
    const Color darkText = Color(0xFF222222);
    const Color labelGray = Color(0xFF9E9E9E);

    final String amount = txData['amount_sent'] ?? "0.00";
    final String txID = txData['txID'] ?? "DFO58N3TPH";
    final String accountName = txData['accountName'] ?? "Nebiyu";
    final String serviceCharge = txData['service_charge'] ?? "1.00";
    final String timeString = txData['time'] ?? "";
    
    String formattedTime = timeString;
    try {
      if (timeString.isNotEmpty) {
        DateTime parsedTime = DateTime.parse(timeString);
        formattedTime = DateFormat('yyyy/dd/MM HH:mm:ss').format(parsedTime);
      }
    } catch (e) {
      formattedTime = timeString;
    }

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
          'Transaction Detail', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: telebirrGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Transfer Money",
                    style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "-$amount",
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: darkText
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "ETB",
                        style: TextStyle(fontSize: 13, color: darkText, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, color: Color(0xFFF2F2F2)),
                  ),
                  _buildDetailRow("Transaction Time:", formattedTime, labelGray, darkText),
                  _buildDetailRow("Transaction No.", txID, labelGray, darkText),
                  _buildDetailRow("Transaction Type", "Transfer Money", labelGray, darkText),
                  _buildDetailRow("Transaction To", accountName, labelGray, darkText),
                  _buildDetailRow("Transaction Amount", "-$amount ETB", labelGray, darkText),
                  _buildDetailRow("Transaction Status", "Completed", labelGray, darkText),
                  _buildDetailRow("Service Charge", "-$serviceCharge ETB", labelGray, darkText),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 🔥 Tying the URL pipeline to the invoice row
            InkWell(
              onTap: _handleGetReceipt, // Maps directly to the receipt launcher
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: telebirrGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Click here to get the invoice",
                      style: TextStyle(
                        color: Color(0xFF444444), 
                        fontSize: 14, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
