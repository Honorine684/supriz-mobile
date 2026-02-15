// notification_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:supriz/consts/consts.dart';

import '../screens/notifications/notifications_screen.dart';
import 'birthday_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
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
        return NotificationItem(
          id: item['id'],
          text: item['contenus'] ?? 'No content',
          date: item['created_at'].split('T')[0],
          time: item['created_at'].split('T')[1].split('.')[0],
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

  /// Initialiser le timezone pour les notifications programmées
  Future<void> initializeTimezone() async {
    tz_data.initializeTimeZones();
  }

  /// Demander la permission de notifications (iOS)
  Future<bool> requestPermission() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Programmer un rappel d'anniversaire
  Future<void> scheduleBirthdayReminder({
    required int birthdayId,
    required String friendName,
    required DateTime scheduledDate,
  }) async {
    await initializeTimezone();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'birthday_reminders',
      'Rappels d\'anniversaire',
      channelDescription: 'Notifications pour les anniversaires de vos amis',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1000 + birthdayId, // Offset pour éviter les conflits avec d'autres notifications
      'Anniversaire de $friendName bientôt !',
      'Prépare ton message Supriz pour $friendName 🎁',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'birthday_$birthdayId',
    );
  }

  /// Annuler un rappel d'anniversaire
  Future<void> cancelBirthdayReminder(int birthdayId) async {
    await flutterLocalNotificationsPlugin.cancel(1000 + birthdayId);
  }

  /// Programmer tous les rappels d'anniversaire depuis l'API
  Future<void> scheduleAllBirthdayReminders() async {
    await initializeTimezone();

    // Récupérer tous les anniversaires actifs
    final birthdays = await BirthdayService.fetchBirthdays();

    for (final birthday in birthdays) {
      if (!birthday.isActive) continue;

      // Annuler l'ancien rappel si existe
      await cancelBirthdayReminder(birthday.id);

      // Calculer la date de notification
      DateTime nextBirthdayDate;
      try {
        nextBirthdayDate = DateTime.parse(birthday.nextBirthday);
      } catch (e) {
        continue;
      }

      // Parser l'heure de rappel (format HH:mm)
      final timeParts = birthday.reminderTime.split(':');
      final reminderHour = int.tryParse(timeParts[0]) ?? 9;
      final reminderMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

      // Créer la date/heure de notification
      var notificationDateTime = DateTime(
        nextBirthdayDate.year,
        nextBirthdayDate.month,
        nextBirthdayDate.day,
        reminderHour,
        reminderMinute,
      );

      // Soustraire les minutes de rappel avant
      notificationDateTime = notificationDateTime.subtract(
        Duration(minutes: birthday.reminderMinutesBefore),
      );

      // Ne programmer que si la date est dans le futur
      if (notificationDateTime.isAfter(DateTime.now())) {
        await scheduleBirthdayReminder(
          birthdayId: birthday.id,
          friendName: birthday.friendName,
          scheduledDate: notificationDateTime,
        );
      }
    }
  }
}
