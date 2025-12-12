import 'dart:async';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

// --- SOS TIMER SCREEN ---
// This screen displays when SOS is active, showing a timer and status.
class SOSTimerScreen extends StatefulWidget {
  final Future<void> Function() stopSOS;
  final String Function(int) formatTime;
  final String statusMessage;

  const SOSTimerScreen({super.key, required this.stopSOS, required this.formatTime, required this.statusMessage});
  @override
  State<SOSTimerScreen> createState() => _SOSTimerScreenState();
}

class _SOSTimerScreenState extends State<SOSTimerScreen> {
  Timer? _sosTimer;
  int _sosDuration = 0;

  @override
  void initState() {
    super.initState();
    _sosDuration = 0;
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _sosDuration++);
    });
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
            Text(widget.formatTime(_sosDuration), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(widget.statusMessage, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () async {
                await widget.stopSOS();
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
              child: Text(loc.translate('stop_sos')),
            )
          ],
        ),
      ),
    );
  }
}
