// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supriz/screens/auth/mdp_oublie_screen.dart';
import 'package:supriz/screens/auth/register_screen.dart';
import 'package:supriz/widgets/auth_widget.dart';
import '../../consts/consts.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

// Page de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // État de chargement
  final AuthService _authService = AuthService();

  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Début du chargement
      });

      await _authService.loginUser(
        emailController.text,
        passwordController.text,
        context,
            (bool isLoading) {
          setState(() {
            _isLoading = isLoading; // Mettre à jour l'état de chargement
          });
        },
      );
    }
  }

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
                  Text('Se connecter à $appname', style: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
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
                          Text('Connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
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
                                SizedBox(height: 10),
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
                                SizedBox(height: 10),
                                ourButton(
                                  text: 'Connexion',
                                  onPressed: loginUser,
                                  isLoading: _isLoading, // Passer l'état de chargement
                                ),
                                TextButton(
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 10, vertical: 3)),
                                    foregroundColor: MaterialStateProperty.all(blueColor),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => MdpOublieScreen()),
                                    );
                                  },
                                  child: Text('Mot de passe oublié?'),
                                ),
                                Text('ou'),
                                SizedBox(height: 5),
                                ourButton(
                                  text: 'Creer un compte',
                                  backgroundColor: roscColor,
                                  textColor: blackColor,
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegisterScreen()),
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
