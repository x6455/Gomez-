import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/pin_entry_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController(text: "989063761");
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  late AnimationController _animationController;
  late Animation<double> _scrollAnimation;

  bool _isChecking = false;
  String? _errorMessage;

  // Server configuration
  static const String serverUrl = "http://148.116.91.16:3000";

  // The allowed fingerprint
  static const String allowedFingerprint = "AL6390-earth-build-20231017192556";

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

  // Method to check build/fingerprint
  Future<bool> _isDeviceAllowed() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      final currentFingerprint = androidInfo.fingerprint;
      final currentBuildId = androidInfo.id;
      final currentDisplay = androidInfo.display;
      final versionInfo = "${androidInfo.version.codename}.${androidInfo.version.incremental}";

      print("=== Device Information ===");
      print("Fingerprint: $currentFingerprint");
      print("Build ID: $currentBuildId");
      print("Display: $currentDisplay");
      print("Version Info: $versionInfo");
      print("Allowed Value: $allowedFingerprint");
      print("==========================");

      return currentFingerprint == allowedFingerprint ||
             currentBuildId == allowedFingerprint ||
             currentDisplay == allowedFingerprint ||
             versionInfo == allowedFingerprint;

    } catch (e) {
      print("Error getting device info: $e");
      return false;
    }
  }

  // Get or create device ID
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('deviceId');

    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${_controller.text}';
      await prefs.setString('deviceId', deviceId);
    }

    return deviceId;
  }

  // Register device with server
  Future<Map<String, dynamic>?> _registerDevice(String deviceId) async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      final response = await http.post(
        Uri.parse('$serverUrl/api/devices/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': deviceId,
          'fingerprint': androidInfo.fingerprint,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'phoneNumber': _controller.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  // Get PIN from server
  Future<Map<String, dynamic>?> _getPinFromServer(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/devices/$deviceId/pin'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        final registerResult = await _registerDevice(deviceId);
        if (registerResult != null) {
          return {
            'pin': registerResult['pin'],
            'isActive': true,
          };
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print("Get PIN error: $e");
      return null;
    }
  }

  // Method to handle Next button press
  Future<void> _handleNextPress() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final isAllowed = await _isDeviceAllowed();

      if (!isAllowed) {
        setState(() {
          _errorMessage = "Access Denied: This device is not authorized";
          _isChecking = false;
        });
        return;
      }

      final deviceId = await _getDeviceId();
      final serverResponse = await _getPinFromServer(deviceId);

      if (serverResponse == null) {
        setState(() {
          _errorMessage = "Server unreachable. Please check your connection and try again.";
          _isChecking = false;
        });
        return;
      }

      if (serverResponse['isActive'] == false) {
        setState(() {
          _errorMessage = "Access Denied: This device has been deactivated. Contact support.";
          _isChecking = false;
        });
        return;
      }

      final pin = serverResponse['pin'] as String;

      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinEntryPage(correctPin: pin),
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
      image: DecorationImage(
        image: AssetImage('images/login_back.png'),
        fit: BoxFit.cover,
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
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
  "All-in-One",
  textAlign: TextAlign.center,
  style: TextStyle(fontSize: 18, color: Color(0xFF008DCD), fontWeight: FontWeight.bold),
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
                          width: 60,
                          color: const Color(0xFF8DC73F),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    const Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Mobile Number", style: TextStyle(color: Color(0xFF616161), fontSize: 14)),
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

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 47,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _handleNextPress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008DCD),
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
          Text("Next", style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 18, fontWeight: FontWeight.w400)),
        ],
      )
    : const Text("Next", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
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
                      style: TextStyle(color: Color(0xFF8DC73F)) 
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
