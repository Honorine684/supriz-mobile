import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supriz/services/token_storage.dart';
import '../consts/consts.dart';

class MessageService {
  static const String baseUrl = '$domaineapi/messages';

  /// Récupérer tous les messages de l'utilisateur
  Future<List<MessageItem>> fetchMessages() async {
    try {
      final token = await TokenStorage.read();

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List<dynamic> messages = data['messages'];
          return messages.map((item) => MessageItem.fromJson(item)).toList();
        }
        throw Exception('Erreur lors du chargement');
      } else {
        throw Exception('Échec du chargement des messages');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération des messages');
    }
  }

  /// Créer un nouveau message
  Future<Map<String, dynamic>> createMessage({
    required String titre,
    String? contenu,
    required int sousCategorieId,
    File? media,
    List<File>? images,
    String? backgroundPath,
    int? musiqueId,
    String expiration = '24h',
    bool uniqueView = false,
  }) async {
    try {
      final token = await TokenStorage.read();

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['titre'] = titre;
      if (contenu != null) request.fields['contenu'] = contenu;
      request.fields['sous_categorie_id'] = sousCategorieId.toString();
      if (backgroundPath != null) request.fields['background_path'] = backgroundPath;
      if (musiqueId != null) request.fields['musique_id'] = musiqueId.toString();
      request.fields['expiration'] = expiration;
      request.fields['unique_view'] = uniqueView ? '1' : '0';

      // Ajouter le média principal
      if (media != null) {
        request.files.add(await http.MultipartFile.fromPath('media', media.path));
      }

      // Ajouter les images multiples
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          request.files.add(await http.MultipartFile.fromPath('images[$i]', images[i].path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'id': data['data']['id'],
          'slug': data['data']['slug'],
          'shareUrl': data['data']['share_url'],
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la création du message');
    }
  }

  /// Récupérer un message spécifique
  Future<MessageItem> getMessage(int id) async {
    try {
      final token = await TokenStorage.read();

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return MessageItem.fromJson(data['data']);
        }
        throw Exception('Message non trouvé');
      } else {
        throw Exception('Échec du chargement du message');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération du message');
    }
  }

  /// Supprimer un message
  Future<bool> deleteMessage(int id) async {
    try {
      final token = await TokenStorage.read();

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la suppression du message');
    }
  }

  /// Activer/Désactiver un message
  Future<bool> toggleMessageStatus(int id) async {
    try {
      final token = await TokenStorage.read();

      final response = await http.post(
        Uri.parse('$baseUrl/$id/toggle-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_active'] ?? false;
      } else {
        throw Exception('Échec du changement de statut');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors du changement de statut');
    }
  }

  /// Récupérer les catégories Supriz
  Future<List<SuprizCategory>> getCategories() async {
    try {
      final token = await TokenStorage.read();

      final response = await http.get(
        Uri.parse('$domaineapi/messages-categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List<dynamic> categories = data['categories'];
          return categories.map((item) => SuprizCategory.fromJson(item)).toList();
        }
        throw Exception('Erreur lors du chargement');
      } else {
        throw Exception('Échec du chargement des catégories');
      }
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération des catégories');
    }
  }

  /// Récupérer les musiques
  Future<List<MusiqueItem>> getMusiques({int? categorieId}) async {
    try {
      final token = await TokenStorage.read();

      String url = '$domaineapi/messages-musiques';
      if (categorieId != null) {
        url = '$url/$categorieId';
      }

      print('Loading musiques from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Musiques response status: ${response.statusCode}');
      print('Musiques response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List<dynamic> musiques = data['musiques'];
          print('Musiques count: ${musiques.length}');
          return musiques.map((item) => MusiqueItem.fromJson(item)).toList();
        }
        throw Exception('Erreur lors du chargement');
      } else {
        throw Exception('Échec du chargement des musiques');
      }
    } catch (e) {
      print('Erreur musiques: $e');
      throw Exception('Erreur lors de la récupération des musiques');
    }
  }

  /// Récupérer les arrière-plans
  Future<List<ArrierePlanItem>> getArrierePlans({int? categorieId}) async {
    try {
      final token = await TokenStorage.read();

      String url = '$domaineapi/messages-arriere-plans';
      if (categorieId != null) {
        url = '$url/$categorieId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final List<dynamic> arrierePlans = data['arriere_plans'];
          return arrierePlans.map((item) => ArrierePlanItem.fromJson(item)).toList();
        }
        throw Exception('Erreur lors du chargement');
      } else {
        throw Exception('Échec du chargement des arrière-plans');
      }
    } catch (e) {
      print('Erreur arrière-plans: $e');
      throw Exception('Erreur lors de la récupération des arrière-plans');
    }
  }

  /// Voir un message public via son slug
  Future<PublicMessageItem> getPublicMessage(String slug, {String? deviceId}) async {
    try {
      final response = await http.get(
        Uri.parse('$domaineapi/public/messages/$slug'),
        headers: {
          'Content-Type': 'application/json',
          if (deviceId != null) 'X-Device-Id': deviceId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return PublicMessageItem.fromJson(data['data']);
        }
        throw Exception('Message non trouvé');
      } else if (response.statusCode == 410) {
        final data = jsonDecode(response.body);
        if (data['is_expired'] == true) {
          throw Exception('MESSAGE_EXPIRED');
        }
        if (data['unique_view_expired'] == true) {
          throw Exception('UNIQUE_VIEW_EXPIRED');
        }
        if (data['already_viewed'] == true) {
          throw Exception('ALREADY_VIEWED');
        }
        if (data['max_views_reached'] == true) {
          throw Exception('MAX_VIEWS_REACHED');
        }
        throw Exception('MESSAGE_INACTIVE');
      } else {
        throw Exception('Échec du chargement du message');
      }
    } catch (e) {
      print('Erreur: $e');
      rethrow;
    }
  }

  /// Ajouter une réaction à un message
  Future<Map<String, int>> addReaction(String slug, String emoji, {String? deviceId}) async {
    try {
      final response = await http.post(
        Uri.parse('$domaineapi/public/messages/$slug/react'),
        headers: {
          'Content-Type': 'application/json',
          if (deviceId != null) 'X-Device-Id': deviceId,
        },
        body: jsonEncode({'emoji': emoji}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          if (data['reactions'] != null && data['reactions'] is Map) {
            final reactions = data['reactions'] as Map<String, dynamic>;
            return reactions.map((key, value) => MapEntry(key, value as int));
          }
          return {};
        }
        throw Exception('Erreur lors de la réaction');
      } else {
        throw Exception('Échec de la réaction');
      }
    } catch (e) {
      print('Erreur réaction: $e');
      rethrow;
    }
  }

  /// Mettre à jour le token FCM
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final token = await TokenStorage.read();

      await http.post(
        Uri.parse('$domaineapi/update-fcm-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );
    } catch (e) {
      print('Erreur update FCM token: $e');
    }
  }
}

/// Modèle pour un message
class MessageItem {
  final int id;
  final String titre;
  final String? contenu;
  final String slug;
  final String shareUrl;
  final String? categorie;
  final String? mediaUrl;
  final String? backgroundPath;
  final List<String>? images;
  final MusiqueItem? musique;
  final String expirationType;
  final String dateExpiration;
  final bool isExpired;
  final bool isActive;
  final int viewsCount;
  final Map<String, int> reactions;
  final String createdAt;

  MessageItem({
    required this.id,
    required this.titre,
    this.contenu,
    required this.slug,
    required this.shareUrl,
    this.categorie,
    this.mediaUrl,
    this.backgroundPath,
    this.images,
    this.musique,
    required this.expirationType,
    required this.dateExpiration,
    required this.isExpired,
    required this.isActive,
    required this.viewsCount,
    this.reactions = const {},
    required this.createdAt,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    Map<String, int> reactionsMap = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      (json['reactions'] as Map<String, dynamic>).forEach((key, value) {
        reactionsMap[key] = value as int;
      });
    }

    return MessageItem(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      slug: json['slug'],
      shareUrl: json['share_url'],
      categorie: json['categorie'],
      mediaUrl: json['media_url'],
      backgroundPath: json['background_path'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      musique: json['musique'] != null ? MusiqueItem.fromJson(json['musique']) : null,
      expirationType: json['expiration_type'] ?? '24h',
      dateExpiration: json['date_expiration'],
      isExpired: json['is_expired'] ?? false,
      isActive: json['is_active'] ?? true,
      viewsCount: json['views_count'] ?? 0,
      reactions: reactionsMap,
      createdAt: json['created_at'],
    );
  }
}

/// Modèle pour un message public
class PublicMessageItem {
  final int? id;
  final String titre;
  final String? contenu;
  final String? categorie;
  final String? mediaUrl;
  final String? backgroundPath;
  final List<String>? images;
  final MusiqueItem? musique;
  final int viewsCount;
  final Map<String, int> reactions;
  final bool canReact;

  PublicMessageItem({
    this.id,
    required this.titre,
    this.contenu,
    this.categorie,
    this.mediaUrl,
    this.backgroundPath,
    this.images,
    this.musique,
    required this.viewsCount,
    this.reactions = const {},
    this.canReact = true,
  });

  factory PublicMessageItem.fromJson(Map<String, dynamic> json) {
    Map<String, int> reactionsMap = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      (json['reactions'] as Map<String, dynamic>).forEach((key, value) {
        reactionsMap[key] = value as int;
      });
    }

    return PublicMessageItem(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      categorie: json['categorie'],
      mediaUrl: json['media_url'],
      backgroundPath: json['background_path'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      musique: json['musique'] != null ? MusiqueItem.fromJson(json['musique']) : null,
      viewsCount: json['views_count'] ?? 0,
      reactions: reactionsMap,
      canReact: json['can_react'] ?? true,
    );
  }
}

/// Modèle pour une catégorie Supriz
class SuprizCategory {
  final int id;
  final String name;
  final String? icone;
  final String? image;
  final String? placeholderTexte;
  final String? giftImage;

  SuprizCategory({
    required this.id,
    required this.name,
    this.icone,
    this.image,
    this.placeholderTexte,
    this.giftImage,
  });

  factory SuprizCategory.fromJson(Map<String, dynamic> json) {
    return SuprizCategory(
      id: json['id'],
      name: json['name_sous_categories'],
      icone: json['icone'],
      image: json['image'],
      placeholderTexte: json['placeholder_texte'],
      giftImage: json['gift_image'],
    );
  }
}

/// Modèle pour une musique
class MusiqueItem {
  final int id;
  final String titre;
  final String? artiste;
  final String fichierUrl;
  final int? duree;

  MusiqueItem({
    required this.id,
    required this.titre,
    this.artiste,
    required this.fichierUrl,
    this.duree,
  });

  factory MusiqueItem.fromJson(Map<String, dynamic> json) {
    return MusiqueItem(
      id: json['id'],
      titre: json['titre'],
      artiste: json['artiste'],
      fichierUrl: json['fichier_url'],
      duree: json['duree'] is int ? json['duree'] : int.tryParse(json['duree']?.toString() ?? ''),
    );
  }

  /// Formater la durée en mm:ss
  String get formattedDuree {
    if (duree == null) return '';
    final minutes = duree! ~/ 60;
    final seconds = duree! % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

/// Modèle pour un arrière-plan
class ArrierePlanItem {
  final int id;
  final String nom;
  final String imageUrl;
  final int ordre;

  ArrierePlanItem({
    required this.id,
    required this.nom,
    required this.imageUrl,
    required this.ordre,
  });

  factory ArrierePlanItem.fromJson(Map<String, dynamic> json) {
    return ArrierePlanItem(
      id: json['id'],
      nom: json['nom'] ?? '',
      imageUrl: json['image_url'] ?? '',
      ordre: json['ordre'] ?? 0,
    );
  }
}
