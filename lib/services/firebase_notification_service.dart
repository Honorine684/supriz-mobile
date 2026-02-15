import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'message_service.dart';
import '../screens/historique/historique_screen.dart';
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
    debugPrint('Token FCM: $token');

    // Sauvegarder localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // Envoyer au backend si l'utilisateur est connecté
    final authToken = prefs.getString('token');
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

  void _handleNotification(RemoteMessage message) async {
    // Afficher une notification locale quand l'app est en foreground
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Supriz',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'supriz_notifications',
            'Notifications Supriz',
            channelDescription: 'Notifications pour les vues et réactions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data['message_slug'],
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
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final messageSlug = data['message_slug'];

    if (messageSlug != null && messageSlug.isNotEmpty) {
      _navigateToMessage(messageSlug);
    }
  }

  /// Callback quand l'utilisateur clique sur une notification locale
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification cliquée avec payload: $payload');

    if (payload != null && payload.isNotEmpty) {
      _navigateToMessage(payload);
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
