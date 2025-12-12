import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../globals.dart';

// --- REAL SERVICE: EVIDENCE MANAGER ---
// This service is responsible for handling the Camera.
// It records video when SOS is active and saves it to the phone's storage.
class EvidenceManager {
  // Singleton instance (only one EvidenceManager exists in the app)
  static final EvidenceManager _instance = EvidenceManager._internal();
  factory EvidenceManager() => _instance;
  EvidenceManager._internal();

  CameraController? _controller;
  // A list to keep track of all recorded videos
  List<Map<String, String>> _evidenceFiles = [];
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isRecording = false;

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Initialize the camera
  Future<void> _initCamera() async {
    // Use the global cameras list
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: true);
    await _controller!.initialize();
  }

  // Load existing evidence files from storage
  Future<void> loadExistingFiles() async {
    try {
      final String publicPath = "/storage/emulated/0/Movies/Sahasi";
      final Directory publicDir = Directory(publicPath);

      List<FileSystemEntity> files = [];
      if (await publicDir.exists()) {
        files = publicDir.listSync();
      }

      _evidenceFiles = files
          .where((file) => file.path.endsWith('.mp4'))
          .map((file) {
            final stat = file.statSync();
            return {
              'id': file.path,
              'filename': p.basename(file.path),
              'path': file.path,
              'date': stat.modified.toString().substring(0, 10),
              'duration': 'Video'
            };
          }).toList()
          ..sort((a, b) => b['filename']!.compareTo(a['filename']!));

    } catch (e) {
      print("Error loading files: $e");
    }
  }

  // Start video recording
  Future<void> startRecording() async {
    if (_isRecording) return;

    // 1. Ask for permission to use Camera and Microphone
    var status = await Permission.camera.request();
    var micStatus = await Permission.microphone.request();
    var storageStatus = await Permission.storage.request();

    if (!status.isGranted || !micStatus.isGranted) return;

    try {
      // 2. Make sure camera is ready
      if (_controller == null || !_controller!.value.isInitialized) {
        await _initCamera();
      }

      // 3. Start recording
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordingDuration = 0;
      // Start a timer to count how long we've been recording
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
      });
      print("REAL: Camera recording started.");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  // Get current recording duration
  int getRecordingDuration() => _recordingDuration;

  // Stop video recording and save file
  Future<String> stopRecording() async {
    _recordingTimer?.cancel();
    final duration = _recordingDuration;
    _recordingDuration = 0;
    _isRecording = false;

    if (_controller != null && _controller!.value.isRecordingVideo) {
      try {
        XFile file = await _controller!.stopVideoRecording();

        final String publicPath = "/storage/emulated/0/Movies/Sahasi";
        final Directory publicDir = Directory(publicPath);
        if (!await publicDir.exists()) {
           await publicDir.create(recursive: true);
        }

        final filename = "SOS_Evidence_${DateTime.now().millisecondsSinceEpoch}.mp4";
        final newPath = p.join(publicDir.path, filename);

        try {
          await file.saveTo(newPath);
        } catch (e) {
          final appDir = await getApplicationDocumentsDirectory();
          final backupPath = p.join(appDir.path, filename);
          await file.saveTo(backupPath);
          return filename;
        }

        _evidenceFiles.insert(0, {
          'id': newPath,
          'filename': filename,
          'path': newPath,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'duration': '${duration}s'
        });

        return filename;
      } catch (e) {
        print("Error stopping recording: $e");
        return "Error saving.";
      }
    }
    return "No recording found.";
  }

  // Get list of evidence files
  List<Map<String, String>> getEvidenceFiles() => _evidenceFiles;

  // Delete an evidence file
  Future<void> deleteEvidence(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print("File deleted from disk: $path");
      }
      _evidenceFiles.removeWhere((file) => file['path'] == path);
    } catch (e) {
      print("Error deleting file: $e");
    }
  }
}
