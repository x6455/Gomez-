import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BalanceInfo extends StatefulWidget {
  final String label;
  final double labelFontSize;
  final double balanceFontSize;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isLabelBold;

  const BalanceInfo({
    super.key,
    required this.label,
    required this.labelFontSize,
    required this.balanceFontSize,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.isLabelBold = false,
  });

  @override
  State<BalanceInfo> createState() => _BalanceInfoState();
}

class _BalanceInfoState extends State<BalanceInfo> {
  bool showBalance = false;
  double _storedBalance = 120894.00; // Default matches your initial value

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  // Fetch the balance that SuccessPage is updating
  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Use the same key 'remaining_balance' used in SuccessPage
      _storedBalance = prefs.getDouble('remaining_balance') ?? 76894.00;
    });
  }

  void toggleBalanceVisibility() {
    setState(() {
      showBalance = !showBalance;
    });
  }

  String get balanceValue {
    switch (widget.label) {
      case 'Balance (ETB) ':
        // Format the stored balance with commas
        return NumberFormat('#,##0.00', 'en_US').format(_storedBalance);
      case 'Endekise (ETB) ':
        return '2,450.00';
      case 'Reward (ETB) ':
        return '0.00';
      default:
        return '0.00';
    }
  }

@override
Widget build(BuildContext context) {
  final bool isMainBalance = widget.label == 'Balance (ETB) ';
  final bool isReward = widget.label == 'Reward (ETB) ';
  final bool isEndekise = widget.label == 'Endekise (ETB) ';
  final String balance = showBalance ? balanceValue : '✱ ✱ ✱ ✱ ✱ ✱';
  
  // Determine star size based on the balance type
  double getStarSize() {
    if (!showBalance) {
      if (isMainBalance) return 20.0;  // Main balance stars
      if (isEndekise || isReward) return 11.0;  // Smaller stars for Endekise and Reward
    }
    return widget.balanceFontSize;  // Regular size when visible
  }

  return Transform.translate(
    offset: isReward ? const Offset(-7, 0) : Offset.zero,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMainBalance ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
                Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isMainBalance ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.roboto( // <-- Changed to GoogleFonts.roboto here
                color: const Color.fromRGBO(247, 255, 234, 1),
                fontSize: widget.labelFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            InkWell(
              onTap: toggleBalanceVisibility,
              child: Icon(
                showBalance ? Icons.visibility : Icons.visibility_off,
                size: 13,
                color: const Color.fromRGBO(247, 255, 234, 1),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        Transform.translate(
          offset: isMainBalance ? const Offset(-9, 0) : Offset.zero,
          child: Text(
            balance,
            textAlign: isMainBalance ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.roboto(
              fontSize: getStarSize(),  // Use dynamic size based on balance type
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: showBalance ? 0.0 : -1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

}
