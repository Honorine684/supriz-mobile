// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/services/token_storage.dart';
import '../../consts/colors.dart';
import '../../consts/images.dart';
import '../../consts/strings.dart';
import '../../widgets/splash_widget.dart';
import '../../services/firebase_notification_service.dart';
import '../auth/login_screen.dart';
import '../home/bottom_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnUserStatus(); // Gestion de la redirection
  }

  Future<void> _navigateBasedOnUserStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    // Obtenir les préférences partagées
    final prefs = await SharedPreferences.getInstance();

    // Lire les valeurs des préférences
    final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? token = await TokenStorage.read();

    // Mettre à jour l'état de connexion en fonction de la présence du token
    if (token != null) {
      prefs.setBool('isLoggedIn', true);
    }

    // Cas 1 : Utilisateur non connecté (ou première installation)
    if (isFirstLaunch || !isLoggedIn) {
      prefs.setBool('isFirstLaunch', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
    // Cas 3 : Utilisateur connecté
    else {
      // Rafraîchir le token FCM à chaque ouverture de l'app
      try {
        await FirebaseNotificationService().sendTokenToBackend();
      } catch (e) {
        // Ignorer les erreurs FCM
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return splashWidget(
      child: Scaffold(
        body: Stack(
          children: [
            // Contenu principal
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de l'application
                Center(
                  child: Image.asset(
                    icAppLogo,
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 10),
                // Nom de l'application
                const Text(
                  appname,
                  style: TextStyle(
                    fontFamily: 'bold',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
