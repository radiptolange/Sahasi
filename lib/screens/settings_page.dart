import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';
import '../services/settings_service.dart';
import '../config/app_config.dart';
import '../app.dart';

// --- 4. SETTINGS SCREEN ---
// Configure app settings like auto-record, location sharing, language, etc.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoRecord = true;
  bool _autoShareLoc = true;
  bool _doubleTapSos = false;
  String _currentLang = 'en';
  int _sosSeconds = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from storage
  void _loadSettings() async {
    _autoRecord = await SettingsService().getSetting(AppConfig.keyAutoRecord);
    _autoShareLoc = await SettingsService().getSetting(AppConfig.keyShareLocation);
    _doubleTapSos = await SettingsService().getSetting(AppConfig.keyDoubleTapSos);
    _currentLang = await SettingsService().getSetting(AppConfig.keyLanguage);
    _sosSeconds = await SettingsService().getSetting(AppConfig.keySosIntervalSeconds);
    if (![15, 30, 60, 120, 300, 600, 1800, 3600].contains(_sosSeconds)) {
      _sosSeconds = 15;
    }
    setState(() {});
  }

  // Helper to format seconds to time string
  String _getLabel(int sec) {
    if (sec < 60) return "$sec sec";
    if (sec == 60) return "1 min";
    if (sec < 3600) return "${sec ~/ 60} min";
    return "1 hour";
  }

  void _onAutoRecordChanged(bool val) {
    if (!val && !_autoShareLoc) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('cannot_disable_both'))));
      return;
    }
    setState(() => _autoRecord = val);
    SettingsService().setSetting(AppConfig.keyAutoRecord, val);
  }

  void _onAutoShareLocChanged(bool val) {
    if (!val && !_autoRecord) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.translate('cannot_disable_both'))));
      return;
    }
    setState(() => _autoShareLoc = val);
    SettingsService().setSetting(AppConfig.keyShareLocation, val);
  }

  void _onDoubleTapChanged(bool val) {
    setState(() => _doubleTapSos = val);
    SettingsService().setSetting(AppConfig.keyDoubleTapSos, val);
    const platform = MethodChannel('sahasi_sos_channel');
    try {
      platform.invokeMethod('setSOSThreshold', {'count': val ? 2 : 3});
    } catch(e) {
      print("Error setting native threshold: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    final bool isFrequencyEnabled = _autoShareLoc;

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(loc.translate('auto_record')),
            value: _autoRecord,
            onChanged: _onAutoRecordChanged,
          ),
          SwitchListTile(
            title: Text(loc.translate('auto_share_loc')),
            value: _autoShareLoc,
            onChanged: _onAutoShareLocChanged,
          ),
          SwitchListTile(
            title: Text(loc.translate('double_tap_sos')),
            subtitle: const Text("Default is 3 taps. Enable for 2 taps."),
            value: _doubleTapSos,
            onChanged: _onDoubleTapChanged,
          ),
          const SizedBox(height: 10),

          Opacity(
            opacity: isFrequencyEnabled ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('sms_interval'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: IgnorePointer(
                    ignoring: !isFrequencyEnabled,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _sosSeconds,
                        items: [15, 30, 60, 120, 300, 600, 1800, 3600].map((e) => DropdownMenuItem(value: e, child: Text(_getLabel(e)))).toList(),
                        onChanged: (v) {
                          setState(() => _sosSeconds = v!);
                          SettingsService().setSetting(AppConfig.keySosIntervalSeconds, v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 30),
          Text(loc.translate('language'), style: const TextStyle(fontWeight: FontWeight.bold)),
          RadioListTile(value: 'en', groupValue: _currentLang, onChanged: (v) { SahasiApp.of(context).setLanguage(v!); setState(() => _currentLang = v);}, title: Text(loc.translate('english'))),
          RadioListTile(value: 'ne', groupValue: _currentLang, onChanged: (v) { SahasiApp.of(context).setLanguage(v!); setState(() => _currentLang = v);}, title: Text(loc.translate('nepali'))),
        ],
      ),
    );
  }
}
