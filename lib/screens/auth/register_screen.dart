// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supriz/screens/auth/login_screen.dart'; // Import de la page de connexion
import 'package:supriz/widgets/auth_widget.dart';
import '../../consts/consts.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/our_button.dart';

// Page d'inscription
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: authWidget(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Image.asset(icAppLogo, height: 100),
                  Text('Créer un compte sur $appname', style: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Card(
                    color: whiteColor,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text('Inscription', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Champ pour le nom d'utilisateur
                                customTextField(
                                  controller: usernameController,
                                  hint: "Entrez votre nom d'utilisateur",
                                  title: "Nom d'utilisateur",
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ce champ est requis';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8),

                                // Champ pour l'email
                                customTextField(
                                  controller: emailController,
                                  hint: "Entrez votre email",
                                  title: "Email",
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ce champ est requis';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                      return 'Entrez un email valide';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8),

                                // Champ pour le numéro de téléphone
                                customTextField(
                                  controller: phoneController,
                                  hint: "Entrez votre numéro de téléphone",
                                  title: "Numéro de téléphone",
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ce champ est requis';
                                    }
                                    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                                      return 'Entrez un numéro valide';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,

                                ),
                                SizedBox(height: 8),

                                // Champ pour le mot de passe
                                customTextField(
                                  controller: passwordController,
                                  hint: "Entrez votre mot de passe",
                                  title: "Mot de passe",
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: greyColor),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ce champ est requis';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 8),
                                // Bouton pour créer un compte
                                ourButton(
                                  text: 'Creer un compte',

                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {

                                    }
                                  },
                                ),
                                SizedBox(height: 5),
                                Text('ou'),
                                SizedBox(height: 5),
                                ourButton(
                                  text: 'Connexion',
                                  backgroundColor: roscColor,
                                  textColor: blackColor,
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => LoginScreen()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
