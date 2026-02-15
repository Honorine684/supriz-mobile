// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../widgets/our_button.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer votre email')),
      );
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
        color: whiteColor,
        child: Column(
          children: [
            // Header bleu avec pattern
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(authBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  // AppBar personnalisée
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: whiteColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Mot de passe oublié',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 48), // Pour équilibrer l'icône de retour
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Mail de récupération',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Entrer votre mail de récupération.',
                      style: TextStyle(
                        fontSize: 14,
                        color: greyColor,
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
                      text: 'Valider',
                      backgroundColor: blueColor,
                      textColor: whiteColor,
                      onPressed: sendOtp,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
