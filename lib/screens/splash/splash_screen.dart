// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../connection_checker.dart';
import '../../consts/colors.dart';
import '../../consts/images.dart';
import '../../consts/strings.dart';
import '../../widgets/splash_widget.dart';
import '../auth/login_screen.dart';
import '../home/bottom_navigation.dart';
import '../onboarding/onboarding.dart';

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

    // Cas 1 : Première installation de l'application
    if (isFirstLaunch) {
      prefs.setBool('isFirstLaunch', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
    // Cas 2 : Utilisateur non connecté
    else if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
    // Cas 3 : Utilisateur connecté
    else {
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
                const SizedBox(height: 2),
                // Version de l'application
                const Text(
                  appversion,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            // Copyright en bas
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    name_version,
                    style: TextStyle(
                      fontFamily: 'bold',
                      fontSize: 15,
                      color: greyColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
