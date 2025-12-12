import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for MethodChannel
import 'config/app_config.dart';
import 'services/settings_service.dart';
import 'localization/app_localizations.dart';
import 'screens/main_navigation_screen.dart';

// --- ROOT APP WIDGET ---
// This widget is the root of your application.
// It holds data that needs to be shared across the entire app, like the Language and SOS status.
class SahasiApp extends StatefulWidget {
  const SahasiApp({super.key});
  @override
  State<SahasiApp> createState() => SahasiAppState();

  // Access the state of the app from anywhere in the widget tree.
  // This allows child screens (like HomePage) to talk to this parent widget.
  static SahasiAppState of(BuildContext context) => context.findAncestorStateOfType<SahasiAppState>()!;
}

// State for SahasiApp, managing global app state like language and SOS status
class SahasiAppState extends State<SahasiApp> {
  // Default language is English ('en')
  String _currentLanguageCode = 'en';
  // Tracks if the SOS mode is currently running (True = Danger, False = Safe)
  bool _isSOSActive = false;

  // Getter for SOS active status
  bool get isSOSActive => _isSOSActive;

  @override
  void initState() {
    super.initState();
    // When the app starts, we load the saved settings (like preferred language).
    _loadSettings();
  }

  // Load initial settings
  void _loadSettings() async {
    final language = await SettingsService().getSetting(AppConfig.keyLanguage);
    setState(() => _currentLanguageCode = language);
    final doubleTap = await SettingsService().getSetting(AppConfig.keyDoubleTapSos);
    _updateNativeThreshold(doubleTap);
  }

  // Set application language
  void setLanguage(String code) async {
    await SettingsService().setSetting(AppConfig.keyLanguage, code);
    setState(() => _currentLanguageCode = code);
  }

  // Set SOS active status
  void setIsSOSActive(bool active) => setState(() => _isSOSActive = active);

  // Update native code about double tap setting
  void _updateNativeThreshold(bool doubleTap) {
    const platform = MethodChannel('sahasi_sos_channel');
    try {
      platform.invokeMethod('setSOSThreshold', {'count': doubleTap ? 2 : 3});
    } catch(e) {
      print("Error setting threshold: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAHASI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF5F0FA),
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C27B0)),
      ),
      // Inject localization
      builder: (context, child) => AppLocalizationsWidget(
        localizations: AppLocalizations(_currentLanguageCode),
        child: child!,
      ),
      home: MainNavigationScreen(key: ValueKey(_currentLanguageCode), isSOSActive: _isSOSActive),
    );
  }
}
