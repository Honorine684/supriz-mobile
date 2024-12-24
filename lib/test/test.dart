// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../consts/colors.dart';
import '../widgets/appbar_custom.dart';
import '../widgets/our_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Placeholder(),
    );
  }
}

