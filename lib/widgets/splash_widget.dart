import 'package:supriz/consts/consts.dart';
import 'package:flutter/material.dart';

Widget splashWidget({Widget? child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(splashBg),
        fit: BoxFit.fill,
      ),
    ),
    child: child,
  );
}