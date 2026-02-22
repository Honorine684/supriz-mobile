import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../consts/consts.dart';

class BirthdayItem {
  final int id;
  final String friendName;
  final String? friendPhone;
  final String birthdayDate;
  final String birthdayDisplay;
  final String reminderTime;
  final int reminderMinutesBefore;
  final bool isActive;
  final String? notes;
  final int daysUntil;
  final bool isToday;
  final String nextBirthday;

  BirthdayItem({
    required this.id,
    required this.friendName,
    this.friendPhone,
    required this.birthdayDate,
    required this.birthdayDisplay,
    required this.reminderTime,
    required this.reminderMinutesBefore,
    required this.isActive,
    this.notes,
    required this.daysUntil,
    required this.isToday,
    required this.nextBirthday,
  });

  factory BirthdayItem.fromJson(Map<String, dynamic> json) {
    return BirthdayItem(
      id: json['id'],
      friendName: json['friend_name'] ?? '',
      friendPhone: json['friend_phone'],
      birthdayDate: json['birthday_date'] ?? '',
      birthdayDisplay: json['birthday_display'] ?? '',
      reminderTime: json['reminder_time'] ?? '00:00',
      reminderMinutesBefore: json['reminder_minutes_before'] ?? 30,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      daysUntil: json['days_until'] ?? 0,
      isToday: json['is_today'] ?? false,
      nextBirthday: json['next_birthday'] ?? '',
    );
  }

  /// Créer une copie avec des modifications
  BirthdayItem copyWith({
    int? id,
    String? friendName,
    String? friendPhone,
    String? birthdayDate,
    String? birthdayDisplay,
    String? reminderTime,
    int? reminderMinutesBefore,
    bool? isActive,
    String? notes,
    int? daysUntil,
    bool? isToday,
    String? nextBirthday,
  }) {
    return BirthdayItem(
      id: id ?? this.id,
      friendName: friendName ?? this.friendName,
      friendPhone: friendPhone ?? this.friendPhone,
      birthdayDate: birthdayDate ?? this.birthdayDate,
      birthdayDisplay: birthdayDisplay ?? this.birthdayDisplay,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      daysUntil: daysUntil ?? this.daysUntil,
      isToday: isToday ?? this.isToday,
      nextBirthday: nextBirthday ?? this.nextBirthday,
    );
  }
}

class UpcomingBirthdayItem {
  final int id;
  final String friendName;
  final String? friendPhone;
  final String birthdayDisplay;
  final int daysUntil;
  final bool isToday;

  UpcomingBirthdayItem({
    required this.id,
    required this.friendName,
    this.friendPhone,
    required this.birthdayDisplay,
    required this.daysUntil,
    required this.isToday,
  });

  factory UpcomingBirthdayItem.fromJson(Map<String, dynamic> json) {
    return UpcomingBirthdayItem(
      id: json['id'],
      friendName: json['friend_name'] ?? '',
      friendPhone: json['friend_phone'],
      birthdayDisplay: json['birthday_display'] ?? '',
      daysUntil: json['days_until'] ?? 0,
      isToday: json['is_today'] ?? false,
    );
  }
}

class TodayBirthdayItem {
  final int id;
  final String friendName;
  final String? friendPhone;

  TodayBirthdayItem({
    required this.id,
    required this.friendName,
    this.friendPhone,
  });

  factory TodayBirthdayItem.fromJson(Map<String, dynamic> json) {
    return TodayBirthdayItem(
      id: json['id'],
      friendName: json['friend_name'] ?? '',
      friendPhone: json['friend_phone'],
    );
  }
}

class BirthdayService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Récupérer tous les anniversaires
  static Future<List<BirthdayItem>> fetchBirthdays() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$domaineapi/birthdays'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['birthdays'] != null) {
          return (data['birthdays'] as List)
              .map((item) => BirthdayItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur fetchBirthdays: $e');
      return [];
    }
  }

  /// Récupérer les anniversaires à venir (7 jours par défaut)
  static Future<List<UpcomingBirthdayItem>> fetchUpcomingBirthdays({int days = 7}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$domaineapi/birthdays/upcoming?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['upcoming'] != null) {
          return (data['upcoming'] as List)
              .map((item) => UpcomingBirthdayItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur fetchUpcomingBirthdays: $e');
      return [];
    }
  }

  /// Récupérer les anniversaires du jour
  static Future<List<TodayBirthdayItem>> fetchTodayBirthdays() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$domaineapi/birthdays/today'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['today'] != null) {
          return (data['today'] as List)
              .map((item) => TodayBirthdayItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur fetchTodayBirthdays: $e');
      return [];
    }
  }

  /// Ajouter un anniversaire
  static Future<Map<String, dynamic>> addBirthday({
    required String friendName,
    String? friendPhone,
    required String birthdayDate,
    String? reminderTime,
    int? reminderMinutesBefore,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'friend_name': friendName,
        if (friendPhone != null) 'friend_phone': friendPhone,
        'birthday_date': birthdayDate,
        if (reminderTime != null) 'reminder_time': reminderTime,
        if (reminderMinutesBefore != null) 'reminder_minutes_before': reminderMinutesBefore,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$domaineapi/birthdays'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'ajout',
        'errors': data['errors'],
      };
    } catch (e) {
      print('Erreur addBirthday: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Modifier un anniversaire
  static Future<Map<String, dynamic>> updateBirthday({
    required int id,
    String? friendName,
    String? friendPhone,
    String? birthdayDate,
    String? reminderTime,
    int? reminderMinutesBefore,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (friendName != null) body['friend_name'] = friendName;
      if (friendPhone != null) body['friend_phone'] = friendPhone;
      if (birthdayDate != null) body['birthday_date'] = birthdayDate;
      if (reminderTime != null) body['reminder_time'] = reminderTime;
      if (reminderMinutesBefore != null) body['reminder_minutes_before'] = reminderMinutesBefore;
      if (isActive != null) body['is_active'] = isActive;
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse('$domaineapi/birthdays/$id'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la modification',
      };
    } catch (e) {
      print('Erreur updateBirthday: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Supprimer un anniversaire
  static Future<Map<String, dynamic>> deleteBirthday(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$domaineapi/birthdays/$id'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la suppression',
      };
    } catch (e) {
      print('Erreur deleteBirthday: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Tester la notification serveur (FCM)
  static Future<Map<String, dynamic>> testServerNotification({int? birthdayId}) async {
    try {
      final headers = await _getHeaders();
      final url = birthdayId != null
          ? '$domaineapi/birthdays/$birthdayId/test-notification'
          : '$domaineapi/birthdays/test-notification';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'envoi',
      };
    } catch (e) {
      print('Erreur testServerNotification: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
