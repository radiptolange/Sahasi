import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../localization/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/evidence_manager.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';
import '../db/database_helper.dart';
import '../app.dart';
import 'home_page.dart';
import 'contacts_page.dart';
import 'fake_call_page.dart';
import 'evidence_access_screen.dart';
import 'settings_page.dart';
import 'sos_timer_screen.dart';

// --- MAIN NAVIGATION ---
// This screen handles the bottom navigation bar and switching between main screens.
// It acts as the "Shell" of the application.
// Crucially, it also contains the central logic for what happens when you press SOS.
class MainNavigationScreen extends StatefulWidget {
  final bool isSOSActive;
  const MainNavigationScreen({super.key, required this.isSOSActive});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Tracks which tab is currently open (0 = Home, 1 = Contacts, etc.)
  Timer? _locationTimer; // Timer to send location updates every few seconds
  static const platform = MethodChannel('sahasi_sos_channel');

  @override
  void initState() {
    super.initState();
    // Start listening for hardware button presses (like power button double-click)
    _initNativeListeners();
    // Request critical permissions on startup
    _checkPermissions();
  }

  // Request all necessary permissions on app start.
  // If denied, show a dialog explaining why they are needed.
  Future<void> _checkPermissions() async {
    // List of critical permissions needed for the app to function.
    // Note: We exclude Permission.storage here because on Android 13+, it is often denied
    // (replaced by photos/videos), and we have a fallback to internal storage.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.sms,
      Permission.phone,
    ].request();

    // Check if any critical permission is permanently denied or denied
    bool isAnyDenied = statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied);

    if (isAnyDenied && mounted) {
      // Show a dialog forcing the user to allow permissions
      showDialog(
        context: context,
        barrierDismissible: false, // User cannot click outside to close
        builder: (context) => AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
            "This app requires Camera, Microphone, Location, SMS, and Phone permissions to function correctly (SOS, Recording, Calling). Please grant them in settings."
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Open app settings so user can manually enable permissions
                openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () {
                 // Retry checking permissions (this will just close the dialog and re-run check)
                 Navigator.pop(context);
                 _checkPermissions();
              },
               child: const Text("Retry"),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Listen for native SOS triggers (e.g., power button presses)
  void _initNativeListeners() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onNativeSOS') {
        if (!SahasiApp.of(context).isSOSActive) _triggerSOS();
      }
    });
  }

  // CENTRAL SOS TRIGGER LOGIC
  // This is the most important function. It runs when SOS is activated.
  // 1. Vibrates the phone.
  // 2. Sets global state to 'Danger'.
  // 3. Starts Video Recording.
  // 4. Starts Location Sharing (SMS).
  Future<void> _triggerSOS() async {
    // 1. Feedback: Vibrate to confirm activation
    HapticFeedback.heavyImpact();
    final loc = context.loc;

    // 2. Update State: Tell the whole app that SOS is now ACTIVE
    final appState = SahasiApp.of(context);
    if (appState.isSOSActive) return; // Prevent double trigger

    appState.setIsSOSActive(true);

    // Load settings and contacts to know what to do
    final contacts = await DatabaseHelper.instance.readAllContacts();
    final autoRecord = await SettingsService().getSetting(AppConfig.keyAutoRecord);
    final autoShareLoc = await SettingsService().getSetting(AppConfig.keyShareLocation);
    final smsIntervalSec = await SettingsService().getSetting(AppConfig.keySosIntervalSeconds);

    List<String> statuses = ["Alert Sent"];

    // 3. Evidence: Start recording video if enabled
    if (autoRecord) {
      await EvidenceManager().startRecording();
      statuses.add("Recording ON");
    }

    // 4. Location: Send SMS with location if enabled
    if (autoShareLoc) {
      await _shareLocationViaSms(contacts);
      statuses.add("Location Sharing ON");

      // Keep sending location updates periodically
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(Duration(seconds: smsIntervalSec), (timer) async {
        await _shareLocationViaSms(contacts);
      });
    }

    final statusMessage = statuses.join(". ") + ".";

    // Show the SOS active screen (Timer)
    if (mounted) {
       Navigator.of(context).push(MaterialPageRoute(builder: (context) => SOSTimerScreen(
         stopSOS: _stopSOS,
         formatTime: _formatTime,
         statusMessage: statusMessage
       )));
    }
  }

  // Helper to share location via SMS
  Future<void> _shareLocationViaSms(List<Map<String, dynamic>> contacts) async {
    final selectedContacts = contacts.where((c) => c['is_selected'] == 1).toList();
    if (selectedContacts.isEmpty) return;

    if (await Permission.sms.request().isDenied || await Permission.location.request().isDenied) return;

    final message = await LocationService.getSmartSOSMessage(context.loc.translate('sos_message'));

    for (var contact in selectedContacts) {
      try {
        await platform.invokeMethod('sendBackgroundSMS', {'number': contact['number'], 'message': message});
      } catch (e) { print("SMS Fail: $e"); }
    }
  }

  // Stop SOS mode
  Future<void> _stopSOS() async {
    final appState = SahasiApp.of(context);
    appState.setIsSOSActive(false);
    _locationTimer?.cancel();
    await EvidenceManager().stopRecording();
  }

  // Format time for SOS timer
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(isSOSActive: widget.isSOSActive, onTriggerSOS: _triggerSOS),
      const ContactsPage(),
      const FakeCallPage(),
      const EvidenceAccessScreen(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield, color: Colors.purple), label: ''),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: Colors.purple), label: ''),
          NavigationDestination(icon: Icon(Icons.call_end_outlined), selectedIcon: Icon(Icons.call_end, color: Colors.purple), label: ''),
          NavigationDestination(icon: Icon(Icons.video_file_outlined), selectedIcon: Icon(Icons.video_file, color: Colors.purple), label: ''),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Colors.purple), label: ''),
        ],
      ),
    );
  }
}
