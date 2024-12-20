import 'package:supriz/consts/consts.dart';
import 'package:flutter/material.dart';

/// Widget pour afficher le logo de l'application.
Widget applogoWidget() {
  return Container(
    width: 104,
    height: 95,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Image.asset(
      icAppLogo,
      fit: BoxFit.contain,
    ),
  );
}
