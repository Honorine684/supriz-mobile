import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/services/token_storage.dart';
import 'package:get/get.dart';
import 'message_service.dart';
import '../screens/historique/historique_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../consts/global.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final MessageService _messageService = MessageService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialiser Firebase et les notifications
  Future<void> initialize() async {
    try {
      // Initialiser les notifications locales pour afficher en foreground
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Ajouter le callback pour gérer le clic sur notification locale
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Créer le canal de notification Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'supriz_notifications',
        'Notifications Supriz',
        description: 'Notifications pour les vues et réactions',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Demander les permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notifications autorisées');

        // Récupérer et sauvegarder le token FCM
        await _getAndSaveToken();

        // Écouter les changements de token
        _messaging.onTokenRefresh.listen(_saveToken);

        // Configurer les handlers de notifications
        _configureNotificationHandlers();

        // Gérer le cas où l'app est ouverte depuis une notification (app fermée)
        await _handleInitialMessage();
      } else {
        debugPrint('Notifications refusées');
      }
    } catch (e) {
      debugPrint('Erreur initialisation Firebase: $e');
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('Erreur récupération token FCM: $e');
    }
  }

  Future<void> _saveToken(String token) async {

    // Sauvegarder localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // Envoyer au backend si l'utilisateur est connecté
    final authToken = await TokenStorage.read();
    if (authToken != null) {
      await _messageService.updateFcmToken(token);
    }
  }

  void _configureNotificationHandlers() {
    // Notification reçue en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notification reçue en foreground: ${message.notification?.title}');
      _handleNotification(message);
    });

    // Notification cliquée (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification ouverte: ${message.notification?.title}');
      _handleNotificationClick(message);
    });
  }

  /// Gérer le cas où l'app est lancée depuis une notification (app était fermée)
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App ouverte depuis notification (terminée): ${initialMessage.notification?.title}');
      // _handleNotificationClick incrémente déjà le compteur
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleNotification(RemoteMessage message) async {
    // Afficher une notification locale quand l'app est en foreground
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Créer un payload JSON avec le type et le slug
      final payloadData = {
        'type': data['type'] ?? '',
        'message_slug': data['message_slug'] ?? '',
        'notification_id': data['notification_id'] ?? '',
      };

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Supriz',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'supriz_notifications',
            'Notifications Supriz',
            channelDescription: 'Notifications pour les vues et réactions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title ?? 'Supriz',
              summaryText: 'Supriz',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(payloadData),
      );

      // Incrémenter le compteur de notifications non lues
      notificationCountNotifier.value++;
    }

    final type = data['type'];
    if (type == 'message_view') {
      debugPrint('Quelqu\'un a vu votre message');
      // Déclencher un rafraîchissement silencieux des messages
      messagesRefreshNotifier.value++;
    } else if (type == 'message_reaction') {
      debugPrint('Quelqu\'un a réagi à votre message avec ${data['emoji']}');
      // Déclencher un rafraîchissement silencieux des messages
      messagesRefreshNotifier.value++;
    } else if (type == 'admin_notification') {
      debugPrint('Notification admin reçue');
    }
  }

  void _handleNotificationClick(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final messageSlug = data['message_slug'];

    // Incrémenter le compteur car la notification vient du background
    notificationCountNotifier.value++;

    // Naviguer selon le type de notification
    if (type == 'admin_notification') {
      _navigateToNotifications();
    } else if (messageSlug != null && messageSlug.isNotEmpty) {
      _navigateToMessage(messageSlug);
    }
  }

  /// Callback quand l'utilisateur clique sur une notification locale
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification cliquée avec payload: $payload');

    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = data['type'] as String?;
        final messageSlug = data['message_slug'] as String?;

        if (type == 'admin_notification') {
          _navigateToNotifications();
        } else if (messageSlug != null && messageSlug.isNotEmpty) {
          _navigateToMessage(messageSlug);
        }
      } catch (e) {
        // Fallback pour l'ancien format (juste le slug)
        debugPrint('Erreur parsing payload, fallback: $e');
        _navigateToMessage(payload);
      }
    }
  }

  /// Naviguer vers l'écran de l'historique des messages
  /// Note: Le propriétaire du message voit son historique (pas la vue publique)
  void _navigateToMessage(String messageSlug) {
    debugPrint('Navigation vers les messages (slug: $messageSlug)');

    // Naviguer vers l'historique des messages du propriétaire
    // Le ViewMessageScreen est pour les visiteurs, pas pour le propriétaire
    Get.to(
      () => const HistoriquesScreen(),
      transition: Transition.rightToLeft,
    );
  }

  /// Naviguer vers l'écran des notifications (pour les notifications admin)
  void _navigateToNotifications() {
    debugPrint('Navigation vers les notifications');

    // Invalider le cache pour forcer le rechargement des nouvelles notifications
    notificationsLoaded = false;
    notificationsCache.value = [];

    Get.to(
      () => const NotificationScreen(),
      transition: Transition.rightToLeft,
    );
  }

  /// Envoyer le token FCM au backend après connexion
  Future<void> sendTokenToBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');

      if (fcmToken != null) {
        await _messageService.updateFcmToken(fcmToken);
      }
    } catch (e) {
      debugPrint('Erreur envoi token FCM: $e');
    }
  }
}

/// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notification reçue en background: ${message.notification?.title}');
}
