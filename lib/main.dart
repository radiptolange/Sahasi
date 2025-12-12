import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'globals.dart';
import 'services/evidence_manager.dart';
import 'db/database_helper.dart';
import 'app.dart';

// --- MAIN APP ---
// Entry point of the application.
// This is the first function that runs when you open the app.
void main() async {
  // Ensure that Flutter's engine is ready before we do any setup.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // 1. Hardware Setup: Check for available cameras on the phone.
    // We store this list in a global variable so we can use it later to record video.
    cameras = await availableCameras();
  } catch (e) {
    print("Camera init failed: $e");
  }

  // 2. Database Setup: Make sure the local database is ready.
  // This is used to save your emergency contacts.
  await DatabaseHelper.instance.database;
  
  // 3. Service Setup: Check for any previously recorded videos.
  await EvidenceManager().loadExistingFiles();
  
  // 4. Start the App: Launch the main interface (SahasiApp).
  runApp(const SahasiApp());
}
