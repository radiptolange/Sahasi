# SAHASI (साहसी) - Personal Safety App

**Sahasi** (meaning "Brave" in Nepali) is a personal safety application designed to help users in emergency situations. It provides quick access to emergency services, automated evidence recording, location sharing, and tools to exit uncomfortable situations.

## 🌟 Key Features

*   **🚨 Emergency SOS**:
    *   **One-Tap Activation**: Quickly trigger an SOS alert.
    *   **Countdown Timer**: 3-second hold to prevent accidental triggers.
    *   **Automated Actions**: Automatically starts recording video and sending location SMS to emergency contacts when activated.
    *   **Double Tap Trigger**: (Optional) Activate SOS by tapping the power button twice (requires native setup).

*   **📹 Evidence Recording**:
    *   **Auto-Record**: Automatically records video when SOS is triggered.
    *   **Secure Storage**: Videos are saved locally and can be viewed in the "Evidence Access" section.
    *   **Manual Control**: Start/Stop recording anytime from the home screen.

*   **📍 Location Sharing**:
    *   **Live Location**: Sends your current GPS coordinates and a Google Maps link via SMS.
    *   **Smart Updates**: Checks for location permissions and connectivity to provide the most accurate info (e.g., "Near: Thamel, Kathmandu").

*   **📞 Fake Call**:
    *   **Escape Tool**: Schedule a fake incoming call to excuse yourself from awkward or unsafe situations.
    *   **Customizable**: Set the caller name, number, and delay time.
    *   **Realistic UI**: Simulates a real incoming call screen with accept/decline buttons.

*   **👥 Emergency Contacts**:
    *   **Manage Contacts**: Add trusted friends and family from your contact list.
    *   **Selection**: Choose which contacts receive SOS alerts.

*   **🌐 Localization**:
    *   **Bilingual**: Full support for **English** and **Nepali (नेपाली)** languages.

## 📂 Project Structure

The project has been refactored for better maintainability and understanding. Here is how the code is organized:

```
lib/
├── app.dart              # The root widget of the application (SahasiApp).
├── globals.dart          # Global variables (e.g., available cameras).
├── main.dart             # Entry point of the app.
│
├── config/               # Configuration files.
│   └── app_config.dart   # Constant keys for settings and preferences.
│
├── db/                   # Database handling.
│   └── database_helper.dart # SQLite helper for managing contacts.
│
├── localization/         # Language and translation support.
│   └── app_localizations.dart # English and Nepali translations.
│
├── screens/              # All the visible screens of the app.
│   ├── contacts_page.dart        # Manage emergency contacts.
│   ├── evidence_access_screen.dart # View and delete recorded videos.
│   ├── fake_call_page.dart       # Setup and trigger fake calls.
│   ├── home_page.dart            # Main dashboard with SOS button.
│   ├── main_navigation_screen.dart # Bottom navigation controller.
│   ├── settings_page.dart        # App settings (Language, Auto-record, etc.).
│   └── sos_timer_screen.dart     # Active SOS alert screen.
│
├── services/             # Background logic and services.
│   ├── evidence_manager.dart     # Camera and file management.
│   ├── location_service.dart     # GPS and geocoding logic.
│   └── settings_service.dart     # Persistent storage (Shared Preferences).
│
└── widgets/              # Reusable UI components.
    ├── add_contact_dialog.dart   # Dialog to add new contacts.
    ├── emergency_card.dart       # Cards for police/ambulance numbers.
    ├── feature_icon.dart         # Circular icons for home screen features.
    └── video_player_widget.dart  # Video player for viewing evidence.
```

## 🔄 Code Connection & Workflow

Understanding how the different parts of the application interact is key to navigating the codebase.

### 1. Initialization (`main.dart` -> `globals.dart`)
*   **Start**: The app begins in `main.dart`.
*   **Hardware Setup**: It first initializes the camera and stores the available cameras in the `cameras` list found in `globals.dart`.
*   **Database**: It ensures the database (`db/database_helper.dart`) is ready.
*   **Services**: It pre-loads evidence files using `EvidenceManager`.
*   **Run**: Finally, it launches `SahasiApp`.

### 2. Global State (`app.dart` -> `screens/*`)
*   **Root Widget**: `SahasiApp` (in `app.dart`) is the parent of all screens.
*   **State**: It holds global state variables like `_currentLanguageCode` (English/Nepali) and `_isSOSActive` (True/False).
*   **Access**: Any screen can access this state using `SahasiApp.of(context)`. For example, `SettingsPage` calls `SahasiApp.of(context).setLanguage('ne')` to change the language app-wide.

### 3. Navigation (`main_navigation_screen.dart`)
*   **Controller**: This screen acts as the shell. It displays the `NavigationBar` at the bottom and switches the body between `HomePage`, `ContactsPage`, etc.
*   **SOS Trigger**: It contains the central logic for the SOS trigger. Even if you are on the "Settings" tab, if you trigger SOS (via power button), this screen handles it.

### 4. Service Interaction
*   **Camera**: `EvidenceManager` (in `services/`) is a singleton. `HomePage` calls `EvidenceManager().startRecording()` to record, and `EvidenceAccessScreen` calls `EvidenceManager().getEvidenceFiles()` to display videos.
*   **Location**: `LocationService` provides a static method `getSmartSOSMessage()`. The `MainNavigationScreen` calls this to generate the text message sent during an emergency.
*   **Settings**: `SettingsService` saves user preferences to persistent storage. It is used by `SettingsPage` to save config and by `MainNavigationScreen` to read config (e.g., checking if `autoRecord` is true).

### 5. Data Flow (`db/` -> `screens/`)
*   **Contacts**: The `ContactsPage` interacts with `DatabaseHelper`. When you add a contact, it calls `DatabaseHelper.instance.createContact()`. When the SOS is triggered, `MainNavigationScreen` calls `DatabaseHelper.instance.readAllContacts()` to find out who to SMS.

## 🚀 Getting Started

1.  **Prerequisites**: Ensure you have Flutter installed on your machine.
2.  **Dependencies**: Run `flutter pub get` to install the required packages (camera, geolocator, sqflite, etc.).
3.  **Permissions**: The app requires permissions for:
    *   Camera & Microphone (for recording evidence)
    *   Location (for SOS alerts)
    *   SMS (for sending alerts)
    *   Storage (for saving videos)
4.  **Run**: Connect a device and run `flutter run`.

## 🛠 Tech Stack

*   **Framework**: Flutter (Dart)
*   **Database**: SQLite (sqflite)
*   **Storage**: Shared Preferences
*   **Hardware Access**: Camera, Geolocator, Sensors

---
*Stay Safe, Stay Sahasi.*
