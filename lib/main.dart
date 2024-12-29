// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supriz/screens/panier/cart_provider.dart';
import 'package:supriz/screens/splash/splash_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'connection_checker.dart';
import 'consts/strings.dart';
import 'consts/styles.dart';

/*
void main() => runApp(
  DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => Supriz(),
  ),
);

 */

void main() => runApp(Supriz());

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
    connectionChecker.startConnectivityMonitor(onConnectionChanged: (hasInternet) {
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
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appname,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
          fontFamily: regular,
          useMaterial3: true,
        ),
        //home: BottomNavigation(),
        home: SplashScreen(),
        navigatorKey: connectionChecker.navigatorKey,
      ),
    );
  }
}