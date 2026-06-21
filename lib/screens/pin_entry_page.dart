import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/main_screen.dart';

class PinEntryPage extends StatefulWidget {
  final String correctPin;
  
  const PinEntryPage({
    super.key, 
    required this.correctPin,
  });

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  String _pin = "";
  final int _pinLength = 6;

  void _onNumberPress(String number) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += number);
    }
    
    // Auto-verify when PIN reaches correct length
    if (_pin.length == widget.correctPin.length) {
      if (_pin == widget.correctPin) {
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
            const SnackBar(
              content: Text("Incorrect PIN. Please try again."),
              duration: Duration(seconds: 2),
            ),
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
          // Smaller, lighter X button
          icon: const Icon(
            Icons.close, 
            color: Color(0xFF757575), 
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Lighter "Enter PIN" text
          const Text(
            "Enter PIN",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w400,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 30),
          
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.correctPin.length, (index) {
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
          // Bolder "Forgot PIN" - removed question mark
          const Text(
            "Forgot PIN",
            style: TextStyle(
              color: Color(0xFF000000), 
              fontSize: 16, 
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const Spacer(),

          // Custom Number Pad - numbers bolder
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                _buildRow(['4', '5', '6']),
                _buildRow(['7', '8', '9']),
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
            // Bolder numbers
            style: const TextStyle(
              fontSize: 30, 
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}