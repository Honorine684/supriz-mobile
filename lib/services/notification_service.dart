// notification_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supriz/services/token_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supriz/consts/consts.dart';

import '../screens/notifications/notifications_screen.dart';

class NotificationService {
  // Singleton pattern pour garder la même instance partout
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initializeNotifications() async {
    if (_isInitialized) return; // Éviter la double initialisation

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
    print('NotificationService: Initialisé avec succès');
  }

  Future<void> showNotification(NotificationItem notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications importantes',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notification.id,
      'Nouvelle notification',
      notification.text,
      platformChannelSpecifics,
    );

    // Mettre à jour l'état de la notification après l'avoir envoyée
    notification.send = true;
  }

  Future<String?> getAuthToken() async {
    return await TokenStorage.read();
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    String? token = await getAuthToken();
    if (token == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$domaineapi/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      List<NotificationItem> notifications = data.map((item) {
        // Le format de created_at est maintenant "dd/mm/YYYY HH:mm"
        String createdAt = item['created_at'] ?? '';
        String date = '';
        String time = '';

        if (createdAt.contains(' ')) {
          // Nouveau format: "20/02/2026 14:30"
          final parts = createdAt.split(' ');
          date = parts[0]; // "20/02/2026"
          time = parts.length > 1 ? parts[1] : ''; // "14:30"
        } else if (createdAt.contains('T')) {
          // Ancien format ISO: "2026-02-20T14:30:00.000Z"
          date = createdAt.split('T')[0];
          time = createdAt.split('T')[1].split('.')[0];
        }

        return NotificationItem(
          id: item['id'],
          titre: item['titre'],
          text: item['contenus'] ?? 'No content',
          date: date,
          time: time,
          isRead: item['isRead'] ?? false,
        );
      }).toList();

      return notifications;
    } else {
      throw Exception('Échec du chargement des notifications');
    }
  }

  Future<void> markAllAsRead() async {
    String? token = await getAuthToken();
    if (token == null) {
      print('Token is null, cannot mark notifications as read.');
      return;
    }

    final response = await http.post(
      Uri.parse('$domaineapi/notifications/makereadall'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec du marquage des notifications comme lues');
    }
  }

  Future<void> deleteNotification(NotificationItem notification) async {
    String? token = await getAuthToken();
    if (token == null) {
      print('Token is null, cannot delete notification.');
      return;
    }

    final response = await http.delete(
      Uri.parse('$domaineapi/notifications/delete/${notification.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression de la notification');
    }
  }

  Future<void> deleteAllNotifications() async {
    String? token = await getAuthToken();
    if (token == null) {
      print('Token is null, cannot delete notifications.');
      return;
    }

    final response = await http.delete(
      Uri.parse('$domaineapi/notifications/deleteall'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la suppression de toutes les notifications');
    }
  }

  Future<void> markAsRead(NotificationItem notification) async {
    try {
      final url =
      Uri.parse('$domaineapi/notifications/makeread/${notification.id}');

      String? token = await getAuthToken();

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        notification.isRead = true;
      } else {
        print('Erreur : Impossible de marquer la notification comme lue.');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }
}
