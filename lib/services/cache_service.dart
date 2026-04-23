import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheService {
  // Clés de préférences à conserver lors du vidage du cache
  static const List<String> _keysToKeep = [
    'token',
    'isLoggedIn',
    'isFirstLaunch',
    'userId',
    'name',
    'email',
    'numero',
    'fcm_token',
    'device_id',
    'localProfileImagePath',
    'profileImagePath',
  ];

  /// Calculer la taille totale du cache
  static Future<String> getCacheSize() async {
    try {
      int totalSize = 0;

      // Cache temporaire
      final tempDir = await getTemporaryDirectory();
      totalSize += await _getDirectorySize(tempDir);

      // Cache des images (CachedNetworkImage)
      final cacheDir = await getApplicationCacheDirectory();
      totalSize += await _getDirectorySize(cacheDir);

      return _formatBytes(totalSize);
    } catch (e) {
      debugPrint('Erreur calcul taille cache: $e');
      return '0 B';
    }
  }

  /// Calculer la taille d'un répertoire
  static Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur calcul taille répertoire: $e');
    }
    return size;
  }

  /// Formater les bytes en unité lisible
  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Vider tout le cache
  static Future<bool> clearAllCache() async {
    try {
      // 1. Vider le cache des images (CachedNetworkImage)
      await DefaultCacheManager().emptyCache();

      // 2. Vider le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      await _clearDirectory(tempDir);

      // 3. Vider le répertoire de cache de l'application
      final cacheDir = await getApplicationCacheDirectory();
      await _clearDirectory(cacheDir);

      // 4. Vider les SharedPreferences non essentielles
      await _clearNonEssentialPreferences();

      debugPrint('Cache vidé avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur vidage cache: $e');
      return false;
    }
  }

  /// Vider uniquement le cache des images
  static Future<bool> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      debugPrint('Cache images vidé');
      return true;
    } catch (e) {
      debugPrint('Erreur vidage cache images: $e');
      return false;
    }
  }

  /// Vider les fichiers temporaires
  static Future<bool> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await _clearDirectory(tempDir);
      debugPrint('Fichiers temporaires vidés');
      return true;
    } catch (e) {
      debugPrint('Erreur vidage fichiers temporaires: $e');
      return false;
    }
  }

  /// Vider un répertoire sans le supprimer
  static Future<void> _clearDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(followLinks: false)) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // Ignorer les erreurs de suppression individuelles
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur vidage répertoire: $e');
    }
  }

  /// Vider les SharedPreferences non essentielles
  static Future<void> _clearNonEssentialPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();

      for (final key in allKeys) {
        // Ne pas supprimer les clés essentielles
        if (!_keysToKeep.contains(key) && !key.startsWith('flutter.')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Erreur vidage préférences: $e');
    }
  }

  /// Vider l'image de profil locale
  static Future<bool> clearProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('localProfileImagePath');

      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await prefs.remove('localProfileImagePath');
      }

      return true;
    } catch (e) {
      debugPrint('Erreur suppression image profil: $e');
      return false;
    }
  }

  /// Obtenir des détails sur le cache
  static Future<Map<String, String>> getCacheDetails() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();

      final tempSize = await _getDirectorySize(tempDir);
      final cacheSize = await _getDirectorySize(cacheDir);

      return {
        'temp': _formatBytes(tempSize),
        'cache': _formatBytes(cacheSize),
        'total': _formatBytes(tempSize + cacheSize),
      };
    } catch (e) {
      return {
        'temp': '0 B',
        'cache': '0 B',
        'total': '0 B',
      };
    }
  }
}
