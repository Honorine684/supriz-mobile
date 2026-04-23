// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../widgets/our_button.dart';
import '../../widgets/toast_notification.dart';
import '../../services/auth_service.dart';

class MdpOublieScreen extends StatefulWidget {
  const MdpOublieScreen({super.key});

  @override
  State<MdpOublieScreen> createState() => _MdpOublieScreenState();
}

class _MdpOublieScreenState extends State<MdpOublieScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> sendOtp() async {
    if (emailController.text.isEmpty) {
      ToastNotification.error(context, 'Veuillez entrer votre email');
      return;
    }
    await AuthService().sendOtpMdp(emailController.text, context, setLoading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(authBg),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Bouton retour
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: whiteColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Logo
                Image.asset(icAppLogo, height: 100),
                SizedBox(height: 16),
                // Titre
                Text(
                  'Mot de passe oublié',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                // Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Récupération',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: blackColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Entrez votre email pour recevoir un code',
                            style: TextStyle(
                              fontSize: 14,
                              color: greyColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Champ email
                        TextField(
                          controller: emailController,
                          cursorColor: blueColor,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Adresse email',
                            hintStyle: TextStyle(color: greyColor, fontSize: 14),
                            filled: true,
                            fillColor: greyColor.withValues(alpha: 0.1),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: Icon(Icons.email_outlined, color: greyColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: blueColor, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Bouton Valider
                        ourButton(
                          text: 'Envoyer le code',
                          onPressed: sendOtp,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 16),
                        // Lien retour connexion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous vous souvenez ? ',
                              style: TextStyle(color: blackColor, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Se connecter',
                                style: TextStyle(
                                  color: blueColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
