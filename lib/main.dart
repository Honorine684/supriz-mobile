// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supriz/screens/splash/splash_screen.dart';
import 'package:get/get.dart';
import 'connection_checker.dart';
import 'consts/strings.dart';
import 'consts/styles.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'widgets/toast_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Enregistrer le handler pour les notifications en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialiser le service de notifications Firebase
  final firebaseNotificationService = FirebaseNotificationService();
  await firebaseNotificationService.initialize();

  // Initialiser les notifications locales
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();

  runApp(const Supriz());
}

class Supriz extends StatefulWidget {
  const Supriz({super.key});

  @override
  State<Supriz> createState() => _SuprizState();
}

class _SuprizState extends State<Supriz> {
  late ConnectionChecker connectionChecker;

  @override
  void initState() {
    super.initState();
    connectionChecker = ConnectionChecker();
    connectionChecker.startConnectivityMonitor(
        onConnectionChanged: (hasInternet) {
      if (!hasInternet && mounted) {
        ToastNotification.error(context, 'Connexion Internet perdue. Vérifiez votre réseau.');
      }
    });
  }

  @override
  void dispose() {
    connectionChecker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: appname,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
          fontFamily: regular,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('fr', 'FR'),
        home: SplashScreen(),
        navigatorKey: connectionChecker.navigatorKey,
      );
  }
}
