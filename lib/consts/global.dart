import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/notifications/notifications_screen.dart';

final ValueNotifier<File?> profileImageNotifier = ValueNotifier<File?>(null);

// Notifier pour le compteur de notifications non lues
final ValueNotifier<int> notificationCountNotifier = ValueNotifier<int>(0);

// Cache pour les notifications (évite de recharger à chaque ouverture)
final ValueNotifier<List<NotificationItem>> notificationsCache = ValueNotifier<List<NotificationItem>>([]);

// Indique si les notifications ont déjà été chargées
bool notificationsLoaded = false;

// Notifier pour déclencher un rafraîchissement des messages (vues/réactions)
// Incrémente la valeur pour signaler un refresh nécessaire
final ValueNotifier<int> messagesRefreshNotifier = ValueNotifier<int>(0);