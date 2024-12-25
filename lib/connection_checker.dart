// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'consts/colors.dart';
import 'consts/images.dart';

class ConnectionChecker {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late bool _isConnected;
  bool _isDialogShown = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // Rendre public

  ConnectionChecker() {
    _isConnected = true;
  }

  Future<bool> hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void startConnectivityMonitor({
    Function(bool)? onConnectionChanged,
  }) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool hasInternet = await hasInternetAccess();
      if (!hasInternet && _isConnected) {
        if (!_isDialogShown) {
          _showNoConnectionDialog();
        }
      } else if (hasInternet && _isDialogShown) {
        _dismissNoConnectionDialog();
      }
      _isConnected = hasInternet;
      onConnectionChanged?.call(hasInternet);
    });
  }

  void _showNoConnectionDialog() {
    _isDialogShown = true;
    navigatorKey.currentState?.push(
      DialogRoute(
        context: navigatorKey.currentContext!,
        builder: (context) => PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    wifi,
                    height: 60,
                    width: 60,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Oups! veuillez activer votre connexion.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vertpan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        bool hasInternet = await hasInternetAccess();
                        if (hasInternet) {
                          _dismissNoConnectionDialog();
                        }
                      },
                      child: Text(
                        'Réessayer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissNoConnectionDialog() {
    _isDialogShown = false;
    navigatorKey.currentState?.pop();
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}