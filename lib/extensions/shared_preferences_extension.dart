import 'package:shared_preferences/shared_preferences.dart';

extension SharedPreferencesExtension on SharedPreferences {
  Future<String?> getUserEmail() async {
    return getString('userEmail'); // Saklanan e-posta adresini al
  }

  Future<void> setUserEmail(String email) async {
    await setString('userEmail', email); // E-posta adresini sakla
  }
}
