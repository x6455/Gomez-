import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/pin_entry_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController(text: "989063761");
  
  late AnimationController _animationController;
  late Animation<double> _scrollAnimation;

  bool _isChecking = false;
  String? _errorMessage;

  // Default offline PIN
  static const String DEFAULT_PIN = "641564";
  
  // Hardcoded device fingerprint - ONLY this device can login
  static const String ALLOWED_FINGERPRINT = "AQM-L21A 12.0.0.239(C185E5R4P1)";
  
  // Alternative: You can also lock by multiple device identifiers
  static const String ALLOWED_MODEL = "AQM-L21A";
  static const String ALLOWED_MANUFACTURER = "HUAWEI";

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scrollAnimation = Tween<double>(
      begin: 1.2,
      end: -1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Check if current device matches the allowed fingerprint
  Future<bool> _isDeviceAllowed() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Get device fingerprint
      final currentFingerprint = androidInfo.fingerprint;
      final currentModel = androidInfo.model;
      final currentManufacturer = androidInfo.manufacturer;
      
      print("Device Fingerprint: $currentFingerprint");
      print("Device Model: $currentModel");
      print("Device Manufacturer: $currentManufacturer");
      
      // Check if fingerprint matches exactly
      if (currentFingerprint == ALLOWED_FINGERPRINT) {
        return true;
      }
      
      // Alternative: Check by model AND manufacturer
      if (currentModel == ALLOWED_MODEL && 
          currentManufacturer.toUpperCase() == ALLOWED_MANUFACTURER) {
        return true;
      }
      
      return false;
    } catch (e) {
      print("Error checking device: $e");
      return false;
    }
  }

  // Validate phone number (basic check)
  bool _isValidPhoneNumber(String phone) {
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length == 9) {
      return digitsOnly.startsWith('9');
    } else if (digitsOnly.length == 12) {
      return digitsOnly.startsWith('2519');
    }
    return false;
  }

  // Method to handle Next button press
  Future<void> _handleNextPress() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // FIRST CHECK: Device fingerprint verification
      final isDeviceAllowed = await _isDeviceAllowed();
      
      if (!isDeviceAllowed) {
        setState(() {
          _errorMessage = "This device is not authorized to use this application";
          _isChecking = false;
        });
        return;
      }
      
      // SECOND CHECK: Phone number validation
      String phoneNumber = _controller.text.trim();
      
      if (phoneNumber.isEmpty) {
        setState(() {
          _errorMessage = "Please enter your mobile number";
          _isChecking = false;
        });
        return;
      }

      if (!_isValidPhoneNumber(phoneNumber)) {
        setState(() {
          _errorMessage = "Please enter a valid Ethiopian mobile number";
          _isChecking = false;
        });
        return;
      }

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('phoneNumber', phoneNumber);

      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        
        // Navigate to PIN page with default PIN
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinEntryPage(correctPin: DEFAULT_PIN),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage('images/login_back.png'),
              fit: BoxFit.cover,
              alignment: Alignment(0, -0.3),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // White bar with logos (edge to edge)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 11, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('images/ethio.png', height: 22),
                        Image.asset('images/telebirr.png', height: 22),
                      ],
                    ),
                  ),

                  // English dropdown (outside white bar)
                  const Padding(
                    padding: EdgeInsets.only(right: 25, top: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "English ▼",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ALL CONTENT BELOW is padded with 25px
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        // Welcome text
                        ClipRect(
                          child: AnimatedBuilder(
                            animation: _scrollAnimation,
                            builder: (context, child) {
                              return FractionalTranslation(
                                translation: Offset(_scrollAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                "Welcome to telebirr SuperApp!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFF008DCD),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "All-in-One",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF008DCD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Column(
                          children: [
                            const Text(
                              "Login",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 1.5,
                              width: 63,
                              color: const Color(0xFF8DC73F),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Mobile Number",
                              style: TextStyle(color: Color(0xFF616161), fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            cursorColor: const Color(0xFF8DC73F),
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 14, height: 1.2),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 18, bottom: 10),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 1.0,
                                  child: Text(
                                    "+251 ",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 55, minHeight: 0),
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF8DC73F), width: 2),
                              ),
                            ),
                          ),
                        ),

                        // Error message display
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 47,
                          child: ElevatedButton(
                            onPressed: _handleNextPress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008DCD),
                              disabledBackgroundColor: const Color(0xFF008DCD),
                              disabledForegroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _isChecking
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Next",
                                        style: TextStyle(
                                          color: Color(0xFFB0B0B0),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Next",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account ?    ",
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              "Create New Account",
                              style: TextStyle(
                                color: Colors.lightGreen.shade700,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "teleHub",
                              style: TextStyle(
                                color: Colors.lightGreen.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              "Help",
                              style: TextStyle(
                                color: Colors.lightGreen.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 155),

                        const Text(
                          "Terms and Conditions",
                          style: TextStyle(color: Color(0xFF8DC73F)),
                        ),
                        const SizedBox(height: 5),

                        const Text(
                          "@2026 ethiotelecom. All rights reserved 1.2.9 version",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                      ],
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