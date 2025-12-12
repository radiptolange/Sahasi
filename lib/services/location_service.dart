import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// --- REAL SERVICE: LOCATION ---
// This service handles finding where you are (GPS) and creating the SMS message.
class LocationService {
  // Generate a smart SOS message with location details.
  // This message is what gets sent to your emergency contacts.
  static Future<String> getSmartSOSMessage(String baseMessage) async {
    // 1. Check if GPS is on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "$baseMessage\nLocation Disabled on device.";

    // 2. Check if we have permission to see location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "$baseMessage\nLocation Permission Denied.";
    }

    try {
      // 3. Get the actual GPS coordinates (Latitude/Longitude)
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Create a clickable Google Maps link
      String googleMapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String rawCoords = "${position.latitude}, ${position.longitude}";

      var connectivityResult = await (Connectivity().checkConnectivity());
      bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

      String addressInfo = "";
      if (isOnline) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String street = place.street ?? "";
            String locality = place.locality ?? "";
            if (street.isNotEmpty || locality.isNotEmpty) {
              addressInfo = "Near: $street, $locality";
            }
          }
        } catch (e) { print("Geocoding failed: $e"); }
      }

      StringBuffer sb = StringBuffer();
      sb.write(baseMessage);
      sb.write("\n");
      if (isOnline && addressInfo.isNotEmpty) sb.write("📍 $addressInfo\n");
      sb.write("🔗 Live Map: $googleMapsLink\n");
      sb.write("📡 Offline Coords: $rawCoords");

      return sb.toString();

    } catch (e) {
      return "$baseMessage\nError fetching location: $e";
    }
  }

  // Helper method to just get current location message
  static Future<String> getCurrentLocation() async {
    return await getSmartSOSMessage("");
  }
}
