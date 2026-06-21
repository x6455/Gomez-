import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/main_screen.dart';

class PinEntryPage extends StatefulWidget {
  const PinEntryPage({super.key});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  String _pin = "";
  final int _pinLength = 6; // Set to 6 to match "124589"
  final String _correctPin = "124589"; // Your default PIN

  void _onNumberPress(String number) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += number);
    }
    
    // Auto-verify when PIN reaches 6 digits
    if (_pin.length == _pinLength) {
      if (_pin == _correctPin) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        });
      } else {
        // Reset if incorrect
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => _pin = "");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Incorrect PIN. Please try again.")),
          );
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
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
          // Top left X button
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "Enter PIN",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 30),
          
          // PIN Dots: Hollow black border or Solid Green
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              bool isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? const Color(0xFF8DC73F) : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? const Color(0xFF8DC73F) : Colors.black,
                    width: 0.5,
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 25),
          const Text(
            "Forgot PIN?",
            style: TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.w400),
          ),
          
          const Spacer(),

          // Custom Number Pad
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                _buildRow(['4', '5', '6']),
                _buildRow(['7', '8', '9']),
                // Custom bottom row: [Empty] [0] [Arrow]
                Row(
                  children: [
                    const Expanded(child: SizedBox(height: 80)), 
                    _buildNumberButton('0'),
                    Expanded(
                      child: InkWell(
                        onTap: _onBackspace,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: const SizedBox(
                          height: 80,
                          // 1. Backspace changed to arrow style
                          child: Icon(Icons.arrow_back, size: 30, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      children: numbers.map((n) => _buildNumberButton(n)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: InkWell(
        onTap: () => _onNumberPress(number),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 80,
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }
}