// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

class MdpOublieScreen extends StatefulWidget {
  MdpOublieScreen({super.key});

  @override
  _MdpOublieScreenState createState() => _MdpOublieScreenState();
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
    await AuthService().sendOtpMdp(emailController.text, context, setLoading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Mot de passe oublié"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Entrer votre mail de récupération',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              cursorColor: blueColor,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: blueColor),
                ),
                fillColor: blueColor,
                border: OutlineInputBorder(),
                hintText: 'Entrer votre mail de récupération',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ourButton(
              text: 'Valider',
              backgroundColor: blueColor,
              textColor: whiteColor,
              onPressed: sendOtp,
              isLoading: _isLoading, // Passer l'état de chargement
            ),
          ],
        ),
      ),
    );
  }
}
