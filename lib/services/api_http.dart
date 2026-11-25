import 'dart:convert';

import 'package:http/http.dart' as http;

// Le reste du package http (Response, MultipartRequest, MultipartFile…) est
// réexporté tel quel : il suffit d'importer ce fichier `as http` à la place
// de 'package:http/http.dart'.
export 'package:http/http.dart' hide get, post, put, patch, delete;

/// Délai maximal d'un appel au serveur. Au-delà, une TimeoutException est
/// levée et traitée par les blocs catch existants (message « Connexion
/// impossible »), au lieu d'un chargement sans fin sur réseau instable.
const Duration apiTimeout = Duration(seconds: 30);

/// Délai plus long pour les envois de fichiers (photos d'un message).
const Duration apiUploadTimeout = Duration(seconds: 120);

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    http.get(url, headers: headers).timeout(apiTimeout);

Future<http.Response> post(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    http
        .post(url, headers: headers, body: body, encoding: encoding)
        .timeout(apiTimeout);

Future<http.Response> put(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    http
        .put(url, headers: headers, body: body, encoding: encoding)
        .timeout(apiTimeout);

Future<http.Response> patch(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    http
        .patch(url, headers: headers, body: body, encoding: encoding)
        .timeout(apiTimeout);

Future<http.Response> delete(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    http
        .delete(url, headers: headers, body: body, encoding: encoding)
        .timeout(apiTimeout);
