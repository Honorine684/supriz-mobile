import 'dart:io';
import 'package:flutter/material.dart';

final ValueNotifier<File?> profileImageNotifier = ValueNotifier<File?>(null);
final ValueNotifier<String> nomNotifier = ValueNotifier<String>('');
final ValueNotifier<String> prenomNotifier = ValueNotifier<String>('');