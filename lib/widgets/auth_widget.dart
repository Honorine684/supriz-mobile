import 'package:supriz/consts/consts.dart';
import 'package:flutter/material.dart';

Widget authWidget({Widget? child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(authBg),
      fit: BoxFit.fill,
      ),
    ),
    child: child,
  );
}