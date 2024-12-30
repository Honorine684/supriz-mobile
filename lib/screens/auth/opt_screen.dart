// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supriz/consts/colors.dart';
import 'package:supriz/screens/auth/reset_pwd.dart';
import '../../consts/images.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 4) {
      // Code OTP à 4 chiffres
      setState(() {
        _errorMessage = 'Veuillez entrer un code OTP valide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await AuthService()
          .verifyOtpMdp(widget.email, _otpController.text, context, setLoading);
    } catch (e) {
      setState(() {
        _errorMessage = 'Code OTP incorrect. Réessayez.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendOTP() {
    AuthService().sendOtpMdp(widget.email, context, setLoading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: 'Vérification OTP'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vous avez reçu un mail",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Entrer le code de vérification qui vous a été envoyé par mail pour pouvoir réinitialiser votre mot de passe",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            Image.asset(opt),
            const SizedBox(height: 10),
            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _otpController,
              onChanged: (value) {
                setState(() {});
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 50,
                fieldWidth: 40,
                inactiveColor: Colors.grey,
                activeColor: blueColor,
                selectedColor: Colors.green,
                fieldOuterPadding: EdgeInsets.all(10),
              ),
              keyboardType: TextInputType.number,
              // Restriction aux chiffres uniquement
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ourButton(
              text: 'Verifier',
              backgroundColor: blueColor,
              textColor: whiteColor,
              onPressed: _verifyOTP,
              isLoading: _isLoading, // Passer l'état de chargement
            ),
            const SizedBox(height: 20),
            ourButton(
              text: 'Renvoyer le code',
              backgroundColor: roscColor,
              textColor: blackColor,
              onPressed: _resendOTP,
            ),
          ],
        ),
      ),
    );
  }
}
