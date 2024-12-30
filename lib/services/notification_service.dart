// notification_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supriz/consts/consts.dart';

import '../screens/notifications/notifications_screen.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    String? token = await getAuthToken();
    if (token == null) {
      print('Token is null, cannot fetch notifications.');
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
      print('Raw data: $data'); // Ajout de débogage
      List<NotificationItem> newNotifications = [];

      List<NotificationItem> notifications = data.map((item) {
        NotificationItem notification = NotificationItem(
          id: item['id'],
          text: item['contenus'] ?? 'No content',
          date: item['created_at'].split('T')[0],
          time: item['created_at'].split('T')[1].split('.')[0],
          isRead: item['isRead'] ?? false,
        );

        if (!notification.isRead && !notification.send) {
          newNotifications.add(notification);
          showNotification(notification);
        }

        return notification;
      }).toList();

      notifications.addAll(newNotifications);
      print('Notifications fetched: ${notifications.length}'); // Ajout de débogage
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
