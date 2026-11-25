import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage du jeton de connexion dans le coffre-fort chiffré du téléphone
/// (Keystore sur Android, Keychain sur iOS) au lieu de SharedPreferences.
///
/// Les versions précédentes de l'app rangeaient le jeton en clair dans
/// SharedPreferences sous la clé 'token'. À la première lecture, il est
/// déplacé dans le stockage sécurisé, pour ne pas déconnecter l'utilisateur.
class TokenStorage {
  static const String _key = 'token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> read() async {
    try {
      final value = await _storage.read(key: _key);
      if (value != null) return value;
    } catch (_) {
      // Coffre illisible (cas rare sur certains appareils) : on considère
      // l'utilisateur déconnecté, il devra se reconnecter.
      return null;
    }

    // Migration depuis l'ancien stockage en clair
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy == null) return null;
    try {
      await _storage.write(key: _key, value: legacy);
      await prefs.remove(_key);
    } catch (_) {
      // Échec d'écriture : on garde l'ancien jeton pour cette session
    }
    return legacy;
  }

  static Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> delete() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
