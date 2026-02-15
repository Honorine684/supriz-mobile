import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service pour précharger et mettre en cache les fichiers audio
class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  // Cache en mémoire des fichiers déjà téléchargés
  final Map<String, String> _cachedPaths = {};

  // URLs en cours de téléchargement
  final Set<String> _downloadingUrls = {};

  /// Obtenir le chemin du cache audio
  Future<Directory> get _cacheDir async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Générer un nom de fichier unique basé sur l'URL
  String _getFileName(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    // Garder l'extension si présente
    final extension = url.contains('.mp3') ? '.mp3' : '.m4a';
    return '$hash$extension';
  }

  /// Vérifier si un fichier audio est déjà en cache
  Future<String?> getCachedPath(String url) async {
    // Vérifier le cache mémoire d'abord
    if (_cachedPaths.containsKey(url)) {
      final path = _cachedPaths[url]!;
      if (await File(path).exists()) {
        return path;
      } else {
        _cachedPaths.remove(url);
      }
    }

    // Vérifier le cache disque
    final cacheDir = await _cacheDir;
    final fileName = _getFileName(url);
    final file = File('${cacheDir.path}/$fileName');

    if (await file.exists()) {
      _cachedPaths[url] = file.path;
      return file.path;
    }

    return null;
  }

  /// Précharger un fichier audio (télécharger en arrière-plan)
  Future<void> preload(String url) async {
    // Ne pas re-télécharger si déjà en cache ou en cours
    if (_downloadingUrls.contains(url)) return;

    final cachedPath = await getCachedPath(url);
    if (cachedPath != null) return;

    _downloadingUrls.add(url);

    try {
      final cacheDir = await _cacheDir;
      final fileName = _getFileName(url);
      final file = File('${cacheDir.path}/$fileName');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _cachedPaths[url] = file.path;
        debugPrint('Audio préchargé: $fileName');
      }
    } catch (e) {
      debugPrint('Erreur préchargement audio: $e');
    } finally {
      _downloadingUrls.remove(url);
    }
  }

  /// Précharger plusieurs fichiers audio en parallèle
  Future<void> preloadAll(List<String> urls) async {
    // Limiter à 3 téléchargements simultanés
    final chunks = <List<String>>[];
    for (var i = 0; i < urls.length; i += 3) {
      chunks.add(urls.sublist(i, i + 3 > urls.length ? urls.length : i + 3));
    }

    for (final chunk in chunks) {
      await Future.wait(chunk.map((url) => preload(url)));
    }
  }

  /// Obtenir le chemin local ou l'URL originale
  /// Retourne le chemin local si en cache, sinon l'URL
  Future<String> getPlayablePath(String url) async {
    final cachedPath = await getCachedPath(url);
    return cachedPath ?? url;
  }

  /// Télécharger et retourner le chemin local
  /// Bloquant - attend le téléchargement complet
  Future<String> downloadAndCache(String url) async {
    final cachedPath = await getCachedPath(url);
    if (cachedPath != null) return cachedPath;

    final cacheDir = await _cacheDir;
    final fileName = _getFileName(url);
    final file = File('${cacheDir.path}/$fileName');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _cachedPaths[url] = file.path;
        return file.path;
      }
    } catch (e) {
      debugPrint('Erreur téléchargement audio: $e');
    }

    // En cas d'erreur, retourner l'URL originale
    return url;
  }

  /// Vider le cache audio
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDir;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _cachedPaths.clear();
      debugPrint('Cache audio vidé');
    } catch (e) {
      debugPrint('Erreur vidage cache audio: $e');
    }
  }

  /// Obtenir la taille du cache audio
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDir;
      if (!await cacheDir.exists()) return 0;

      int size = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          size += await entity.length();
        }
      }
      return size;
    } catch (e) {
      return 0;
    }
  }
}
