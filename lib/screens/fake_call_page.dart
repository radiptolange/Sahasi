import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import 'contacts_page.dart';

// --- 3. FAKE CALL SCREEN ---
// This screen allows you to schedule a fake incoming call.
// Useful for getting out of awkward or unsafe situations.
class FakeCallPage extends StatefulWidget {
  const FakeCallPage({super.key});
  @override
  State<FakeCallPage> createState() => _FakeCallPageState();
}

class _FakeCallPageState extends State<FakeCallPage> {
  final _nameCtrl = TextEditingController(text: "Mom");
  final _numCtrl = TextEditingController(text: "9800000000");
  int _delaySeconds = 5;

  @override
  void initState() {
    super.initState();
    _loadDelay();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  void _loadDelay() async {
    int d = await SettingsService().getSetting(AppConfig.keyFakeCallDelay);
    setState(() => _delaySeconds = d);
  }

  // Set a timer to trigger the "Fake" incoming call screen after X seconds
  void _scheduleCall() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${context.loc.translate('schedule_call')} in $_delaySeconds s")));
    Timer(Duration(seconds: _delaySeconds), () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => IncomingCallScreen(
        name: _nameCtrl.text,
        number: _numCtrl.text,
      )));
    });
  }

  void _pickContact() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const ContactsPage(isSelectionMode: true)));
    if (result != null && result is Map) {
      setState(() {
        _nameCtrl.text = result['name'];
        _numCtrl.text = result['number'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('fake_call'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  CircleAvatar(radius: 40, child: Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : "M")),
                  const SizedBox(height: 16),
                  Text(_nameCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 22)),
                  Text(_numCtrl.text, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _pickContact,
              icon: const Icon(Icons.contacts),
              label: Text(loc.translate('pick_contact'))
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${loc.translate('call_delay')}: $_delaySeconds s"),
                Expanded(
                  child: Slider(
                    value: _delaySeconds.toDouble(),
                    min: 5, max: 60, divisions: 11,
                    onChanged: (v) {
                      setState(() => _delaySeconds = v.toInt());
                      SettingsService().setSetting(AppConfig.keyFakeCallDelay, v.toInt());
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _scheduleCall,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
              child: Text(loc.translate('schedule_call'), style: const TextStyle(color: Colors.white))
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: loc.translate('caller_name'))),
            TextField(controller: _numCtrl, decoration: InputDecoration(labelText: loc.translate('caller_number'))),
          ],
        ),
      ),
    );
  }
}

// SIMULATED INCOMING CALL
// This screen looks like a real incoming phone call.
class IncomingCallScreen extends StatefulWidget {
  final String name;
  final String number;

  const IncomingCallScreen({super.key, required this.name, required this.number});
  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  static const platform = MethodChannel('sahasi_sos_channel');
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    // Play ringtone and vibrate when screen opens
    _playRingtone();
    _startVibration();
  }

  // Vibrate the phone every second to mimic a ringing phone
  void _startVibration() {
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _stopRingtone();
    _vibrationTimer?.cancel();
    super.dispose();
  }
  void _playRingtone() async { try { await platform.invokeMethod('playRingtone'); } catch (_) {} }
  void _stopRingtone() async { try { await platform.invokeMethod('stopRingtone'); } catch (_) {} }

  void _answerCall() {
    _stopRingtone();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => OngoingCallScreen(name: widget.name, number: widget.number)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(children: [
              const SizedBox(height: 60),
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
              const SizedBox(height: 20),
              Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 36)),
              Text("Mobile ${widget.number}", style: const TextStyle(color: Colors.white70, fontSize: 18)),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(heroTag: 'dec', onPressed: () => Navigator.pop(context), backgroundColor: Colors.redAccent, child: const Icon(Icons.call_end, size: 30)),
                  FloatingActionButton(heroTag: 'acc', onPressed: _answerCall, backgroundColor: Colors.greenAccent, child: const Icon(Icons.call, size: 30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SIMULATED ONGOING CALL
class OngoingCallScreen extends StatefulWidget {
  final String name;
  final String number;
  const OngoingCallScreen({super.key, required this.name, required this.number});

  @override
  State<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _seconds++));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 60, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 80, color: Colors.white)),
            const SizedBox(height: 24),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_formatDuration(_seconds), style: const TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  FloatingActionButton(onPressed: () {}, backgroundColor: Colors.white24, elevation: 0, child: const Icon(Icons.mic_off)),
                  const SizedBox(height: 8),
                  const Text("Mute", style: TextStyle(color: Colors.white54))
                ]),
                Column(children: [
                  FloatingActionButton(onPressed: () {}, backgroundColor: Colors.white24, elevation: 0, child: const Icon(Icons.dialpad)),
                  const SizedBox(height: 8),
                  const Text("Keypad", style: TextStyle(color: Colors.white54))
                ]),
                Column(children: [
                  FloatingActionButton(onPressed: () {}, backgroundColor: Colors.white24, elevation: 0, child: const Icon(Icons.volume_up)),
                  const SizedBox(height: 8),
                  const Text("Speaker", style: TextStyle(color: Colors.white54))
                ]),
              ],
            ),
            const SizedBox(height: 40),
            FloatingActionButton.large(
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
