import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/screens/auth/register_screen.dart';

/// Widget personnalisé pour un champ de texte avec un titre et des options configurables.
Widget customTextField({
  required String title,
  required String hint,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  String? Function(String?)? validator,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(vertical: 5.0),
  Widget? suffixIcon,
  Widget? prefixIcon, // Ajout du paramètre prefixIcon
  InputDecoration? decoration, // Décoration personnalisée
  int? maxLength,
  List<TextInputFormatter>? inputFormatters, // Ajout du paramètre inputFormatters
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Titre du champ de texte
      Text(
        title,
        style: const TextStyle(
          color: blueColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8), // Espacement entre le titre et le champ
      // Champ de texte personnalisé
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: blueColor,
        obscureText: obscureText,
        style: const TextStyle(
          fontWeight: FontWeight.w400,
        ),
        inputFormatters: inputFormatters, // Application des inputFormatters
        decoration: decoration ?? InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontFamily: bold,
            color: greyColor,
          ),
          isDense: true,
          contentPadding: contentPadding,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: blueColor,
              width: 2.0,
            ),
          ),
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon, // Utilisation du prefixIcon
          filled: false, // Désactive le remplissage par défaut
          fillColor: Colors.transparent, // Couleur de remplissage transparente
        ),
        validator: validator,
        maxLength: maxLength, // Limite de caractères
        buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) {
          return null; // Masquer le compteur de caractères
        },
      ),
      const SizedBox(height: 17),
    ],
  );
}
