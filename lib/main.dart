// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supriz/screens/panier/cart_controller.dart';
import 'package:supriz/screens/panier/cart_provider.dart';
import 'package:supriz/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'connection_checker.dart';
import 'consts/strings.dart';
import 'consts/styles.dart';
import 'services/notification_service.dart';
import 'services/firebase_notification_service.dart';

/*
void main() => runApp(
  DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => Supriz(),
  ),
);

 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.lazyPut<CartController>(() => CartController());

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
  await notificationService.initializeTimezone();
  await notificationService.requestPermission(); // Demander les permissions

  // Programmer tous les rappels d'anniversaire au démarrage
  // (au cas où l'app a été fermée ou le téléphone redémarré)
  notificationService.scheduleAllBirthdayReminders();

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
      if (!hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion Internet perdue')),
        );
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
      ],
      child: GetMaterialApp(
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
      ),
    );
  }
}
