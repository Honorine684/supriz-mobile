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

  void startConnectivityMonitor(
      BuildContext validContext, {
        Function(bool)? onConnectionChanged,
      }) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool hasInternet = await hasInternetAccess();
      if (!hasInternet && _isConnected) {
        // Afficher le dialogue uniquement si non déjà affiché
        if (!_isDialogShown) {
          _showNoConnectionDialog(validContext);
        }
      } else if (hasInternet && _isDialogShown) {
        // Fermer automatiquement le dialogue si la connexion revient
        Navigator.of(validContext, rootNavigator: true).pop();
        _isDialogShown = false; // Mettre à jour l'état du dialogue
      }
      _isConnected = hasInternet;
      onConnectionChanged?.call(hasInternet);
    });
  }


  void _showNoConnectionDialog(BuildContext validContext) {
    _isDialogShown = true; // Marquer que le dialogue est affiché
    showDialog(
      context: validContext,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Empêche de fermer le dialogue avec le bouton retour
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
                        Navigator.of(context).pop(); // Fermer le dialogue si la connexion est rétablie
                        _isDialogShown = false; // Mettre à jour l'état
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
    );
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}