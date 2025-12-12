import 'package:flutter/material.dart';

// --- LOCALIZATION ---
// This class handles app localization (English and Nepali).
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'SAHASI',
      'emergency_numbers': 'Default Emergency Numbers',
      'police': 'Police',
      'women_helpline': 'Women Helpline',
      'ambulance': 'Ambulance',
      'sos_button': 'EMERGENCY SOS',
      'hold_to_activate': 'Hold 3s to Activate',
      'record_evidence': 'Record Evidence',
      'stop_evidence': 'Stop Recording',
      'share_location': 'Share Location',
      'sending_location': 'Sending...',
      'safety_tips': 'Safety Tips',
      'safety_message': 'Always trust your instincts. If something feels wrong, activate the SOS immediately.',
      'contacts': 'Emergency Contacts',
      'no_contacts': 'No contacts added yet.',
      'add_contact': 'Add Contact',
      'fake_call': 'Fake Call',
      'schedule_call': 'Start Call',
      'customize_caller': 'Customize Caller',
      'caller_name': 'Caller Name',
      'caller_number': 'Caller Number',
      'incoming_call': 'Incoming call from...',
      'decline': 'Decline',
      'accept': 'Accept',
      'settings': 'Settings',
      'auto_record': 'Record Video Evidence on SOS Trigger',
      'auto_share_loc': 'Location Share via SMS on SOS Trigger',
      'double_tap_sos': 'Double Tap Power SOS',
      'sms_interval': 'SMS Frequency',
      'every_time': 'Every %s',
      'language': 'Language / भाषा',
      'english': 'English',
      'nepali': 'नेपाली',
      'evidence_access': 'Evidence Access',
      'evidence_empty': 'No evidence files found.',
      'view_evidence': 'View Evidence',
      'sos_timer_title': 'EMERGENCY ACTIVE',
      'stop_sos': 'STOP SOS',
      'sos_message': 'HELP! I am in danger.',
      'start_recording': 'Recording started.',
      'stop_recording': 'Recording stopped.',
      'location_sent_success': 'Location SMS sent to selected contacts.',
      'call_delay': 'Call Delay',
      'select_contacts': 'Select Contacts for SOS',
      'pick_contact': 'Select from Contacts',
      'cannot_disable_both': 'At least one safety feature must be ON.',
      'delete_confirm': 'Delete?',
    },
    'ne': {
      'app_name': 'साहसी',
      'emergency_numbers': 'पूर्वनिर्धारित आपतकालीन नम्बरहरू',
      'police': 'प्रहरी',
      'women_helpline': 'महिला हेल्पलाइन',
      'ambulance': 'एम्बुलेन्स',
      'sos_button': 'आपतकालीन एसओएस',
      'hold_to_activate': 'सक्रिय गर्न ३ सेकेन्डसम्म थिच्नुहोस्',
      'record_evidence': 'प्रमाण रेकर्ड गर्नुहोस्',
      'stop_evidence': 'रेकर्डिङ रोक्नुहोस्',
      'share_location': 'स्थान साझा गर्नुहोस्',
      'sending_location': 'पठाउँदै...',
      'safety_tips': 'सुरक्षा सुझावहरू',
      'safety_message': 'सधैं आफ्नो अन्तर्ज्ञानमा विश्वास गर्नुहोस्।',
      'contacts': 'आपतकालीन सम्पर्कहरू',
      'no_contacts': 'कुनै सम्पर्कहरू थपिएको छैन।',
      'add_contact': 'सम्पर्क थप्नुहोस्',
      'fake_call': 'नक्कली कल',
      'schedule_call': 'कल सुरु गर्नुहोस्',
      'customize_caller': 'कलर अनुकूलित गर्नुहोस्',
      'caller_name': 'कलरको नाम',
      'caller_number': 'कलरको नम्बर',
      'incoming_call': 'बाट आगमन कल...',
      'decline': 'अस्वीकार गर्नुहोस्',
      'accept': 'स्वीकार गर्नुहोस्',
      'settings': 'सेटिङहरू',
      'auto_record': 'SOS ट्रिगरमा भिडियो प्रमाण रेकर्ड गर्नुहोस्',
      'auto_share_loc': 'SOS ट्रिगरमा SMS मार्फत स्थान साझा गर्नुहोस्',
      'double_tap_sos': 'डबल ट्याप पावर SOS',
      'sms_interval': 'एसएमएस आवृत्ति',
      'every_time': 'हरेक %s',
      'language': 'भाषा / Language',
      'english': 'English',
      'nepali': 'नेपाली',
      'evidence_access': 'प्रमाण पहुँच',
      'evidence_empty': 'कुनै प्रमाण छैन।',
      'view_evidence': 'प्रमाण हेर्नुहोस्',
      'sos_timer_title': 'आपतकालीन सक्रिय',
      'stop_sos': 'एसओएस रोक्नुहोस्',
      'sos_message': 'मलाई मद्दत गर्नुहोस्!',
      'start_recording': 'रेकर्डिङ सुरु भयो।',
      'stop_recording': 'रेकर्डिङ रोकियो।',
      'location_sent_success': 'स्थान SMS पठाइयो।',
      'call_delay': 'कल समय',
      'select_contacts': 'SOS को लागी सम्पर्क छान्नुहोस्',
      'pick_contact': 'सम्पर्कबाट छान्नुहोस्',
      'cannot_disable_both': 'कम से कम एक सुरक्षा सुविधा सक्रिय हुनुपर्छ।',
      'delete_confirm': 'मेटाउने?',
    },
  };

  final String languageCode;
  AppLocalizations(this.languageCode);

  static AppLocalizations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLocalizationsWidget>()?.localizations;
  }

  // Translate a key to the current language
  String translate(String key, {String? arg1}) {
    String? text = _localizedValues[languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
    if (arg1 != null) text = text.replaceFirst('%s', arg1);
    return text;
  }
}

// InheritedWidget to propagate localizations down the tree
class AppLocalizationsWidget extends InheritedWidget {
  final AppLocalizations localizations;
  const AppLocalizationsWidget({Key? key, required this.localizations, required Widget child}) : super(key: key, child: child);
  @override
  bool updateShouldNotify(covariant AppLocalizationsWidget oldWidget) => localizations.languageCode != oldWidget.localizations.languageCode;
}

// Extension for easier access to translations
extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this) ?? AppLocalizations('en');
}
