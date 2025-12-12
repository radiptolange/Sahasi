import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../localization/app_localizations.dart';
import '../services/evidence_manager.dart';
import '../services/location_service.dart';
import '../db/database_helper.dart';
import '../widgets/emergency_card.dart';
import '../widgets/feature_icon.dart';

// --- 1. HOME SCREEN ---
// The main dashboard. This is what you see when you first open the app.
// It contains the big "SOS" button and quick access to emergency numbers.
class HomePage extends StatefulWidget {
  final bool isSOSActive;
  // This function is passed from the parent (MainNavigationScreen) to tell it "SOS was pressed!"
  final VoidCallback onTriggerSOS;
  const HomePage({super.key, required this.isSOSActive, required this.onTriggerSOS});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('sahasi_sos_channel');
  bool _isSendingLocation = false;
  late AnimationController _sosController;

  @override
  void initState() {
    super.initState();
    // Initialize SOS button animation.
    // The user must hold the button for 2 seconds to activate SOS.
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
      // If the animation finishes (user held it long enough), trigger SOS!
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onTriggerSOS();
        _sosController.reset();
      }
    });
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  // Helper to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.request();
    if (status.isDenied) return;
    try {
      await platform.invokeMethod('makeDirectCall', {'number': phoneNumber});
    } on PlatformException {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  // Toggle manual video recording
  void _toggleManualRecording() async {
    setState(() {});
    if (EvidenceManager().isRecording) {
      await EvidenceManager().stopRecording();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('stop_recording'))));
    } else {
      await EvidenceManager().startRecording();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('start_recording'))));
    }
    setState(() {});
  }

  // Manually share location via SMS
  Future<void> _manualShareLocation() async {
    setState(() => _isSendingLocation = true);
    final contacts = await DatabaseHelper.instance.readAllContacts();

    final selectedContacts = contacts.where((c) => c['is_selected'] == 1).toList();
    if (selectedContacts.isEmpty) {
      setState(() => _isSendingLocation = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('no_contacts'))));
      return;
    }

    if (await Permission.sms.request().isDenied || await Permission.location.request().isDenied) {
      setState(() => _isSendingLocation = false);
      return;
    }

    final message = await LocationService.getSmartSOSMessage(context.loc.translate('sos_message'));

    int successCount = 0;
    for (var contact in selectedContacts) {
      try {
        await platform.invokeMethod('sendBackgroundSMS', {'number': contact['number'], 'message': message});
        successCount++;
      } catch (e) { print("SMS Fail: $e"); }
    }

    setState(() => _isSendingLocation = false);

    if (mounted && successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('location_sent_success')), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isRecording = EvidenceManager().isRecording;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Icon(Icons.shield, size: 50, color: Colors.purple),
            Text(loc.translate('app_name'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),

            const SizedBox(height: 24),

            Align(alignment: Alignment.centerLeft, child: Text(loc.translate('emergency_numbers'), style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),

            EmergencyCard(
              title: loc.translate('police'),
              subtitle: "Nepal Police",
              number: "100",
              bgColor: Colors.red.shade50,
              textColor: Colors.red,
              onTap: () => _makePhoneCall("100"),
            ),
            EmergencyCard(
              title: loc.translate('women_helpline'),
              subtitle: "Women Commission",
              number: "1145",
              bgColor: Colors.purple.shade50,
              textColor: Colors.purple,
              onTap: () => _makePhoneCall("1145"),
            ),
            EmergencyCard(
              title: loc.translate('ambulance'),
              subtitle: "Emergency",
              number: "102",
              bgColor: Colors.blue.shade50,
              textColor: Colors.blue,
              onTap: () => _makePhoneCall("102"),
            ),

            const SizedBox(height: 24),

            Center(
              child: AnimatedBuilder(
                animation: _sosController,
                builder: (context, child) {
                  final scale = 1.0 - (_sosController.value * 0.05);
                  final secondsRemaining = 2 - (_sosController.value * 2).ceil();
                  final isPressing = _sosController.isAnimating;

                  return GestureDetector(
                    onTapDown: (_) {
                      if (!widget.isSOSActive) {
                        HapticFeedback.lightImpact();
                        _sosController.forward();
                      }
                    },
                    onTapUp: (_) {
                      if (_sosController.status != AnimationStatus.completed) _sosController.reset();
                    },
                    onTapCancel: () => _sosController.reset(),
                    onTap: widget.isSOSActive ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SOS active."))) : null,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: widget.isSOSActive
                            ? const LinearGradient(colors: [Colors.teal, Colors.green])
                            : const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Stack(
                          children: [
                            if (isPressing)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: MediaQuery.of(context).size.width * _sosController.value,
                                  height: 160,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(widget.isSOSActive ? Icons.sensors_rounded : Icons.fingerprint, size: 48, color: Colors.white),
                                const SizedBox(height: 8),
                                Center(child: Text(widget.isSOSActive ? "SOS ACTIVE" : loc.translate('sos_button'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                                if (!widget.isSOSActive)
                                  Text(
                                    isPressing ? "Activating in $secondsRemaining..." : loc.translate('hold_to_activate'),
                                    style: TextStyle(color: Colors.white70, fontSize: isPressing ? 16 : 12, fontWeight: isPressing ? FontWeight.bold : FontWeight.normal)
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FeatureIcon(
                  icon: isRecording ? Icons.stop_circle : Icons.video_camera_back,
                  label: isRecording ? loc.translate('stop_evidence') : loc.translate('record_evidence'),
                  onTap: _toggleManualRecording,
                  isLoading: false,
                  isActive: isRecording
                ),
                FeatureIcon(
                  icon: Icons.share_location,
                  label: _isSendingLocation ? loc.translate('sending_location') : loc.translate('share_location'),
                  onTap: _manualShareLocation,
                  isLoading: _isSendingLocation
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
