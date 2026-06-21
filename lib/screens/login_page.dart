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
  static const String allowedFingerprint = "SP1A.210812.016.G975USQU9IXE3";

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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login_back.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // Top Logos and English selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('images/ethio.png', height: 25), 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Image.asset('images/telebirr.png', height: 25), 
                        const SizedBox(height: 4),
                        const Text(
                          "English ▼",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),

                // Welcome text moving like a train
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
                      child: Column(
                        children: [
                          Text(
                            "Welcome to telebirr SuperApp",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22, 
                              color: Color(0xFF008DCD), 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          Text(
                            "All-in-One",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Color(0xFF008DCD)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Column(
                  children: [
                    const Text(
                      "Login",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 50,
                      color: const Color(0xFF8DC73F),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mobile Number", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                const SizedBox(height: 10),

                // Mobile Number Input Box
                SizedBox(
                  width: double.infinity, 
                  height: 55,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("+251 ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
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
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Error message display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _handleNextPress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008DCD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text("Next", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account ? "),
                    Text(
                      "Create New Account", 
                      style: TextStyle(color: Colors.lightGreen.shade700, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("teleHub", style: TextStyle(color: Colors.lightGreen.shade700, fontSize: 16)),
                    Text("Help", style: TextStyle(color: Colors.lightGreen.shade700, fontSize: 16)),
                  ],
                ),

                const SizedBox(height: 60),

                const Text(
                  "Terms and Conditions", 
                  style: TextStyle(color: Color(0xFF8DC73F)) 
                ),
                const SizedBox(height: 5),
                const Text(
                  "@2023 ethiotelecom. All rights reserved 1.0.0 version",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}