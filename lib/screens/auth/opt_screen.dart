// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supriz/consts/colors.dart';
import 'package:supriz/screens/auth/reset_pwd.dart';
import '../../consts/images.dart';
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
  bool _isResending = false;
  String _errorMessage = '';

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _verifyOTP() async {
    // 4 chiffres (ancien format serveur) ou 6 chiffres (nouveau format)
    final codeLength = _otpController.text.length;
    if (codeLength != 4 && codeLength != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer le code reçu par email';
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
        _errorMessage = 'Code incorrect. Veuillez réessayer.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendOTP() {
    setState(() {
      _isResending = true;
    });
    AuthService().sendOtpMdp(widget.email, context, (bool loading) {
      setState(() {
        _isResending = loading;
      });
    });
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
                  'Vérification du code',
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
                      children: [
                        Text(
                          'Vérification',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Entrez le code envoyé à votre email',
                          style: TextStyle(
                            fontSize: 14,
                            color: greyColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = '';
                            });
                          },
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            inactiveColor: greyColor.withValues(alpha: 0.3),
                            activeColor: blueColor,
                            selectedColor: blueColor,
                            activeFillColor: whiteColor,
                            inactiveFillColor: greyColor.withValues(alpha: 0.1),
                            selectedFillColor: whiteColor,
                          ),
                          enableActiveFill: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        SizedBox(height: 8),
                        ourButton(
                          text: 'Vérifier',
                          onPressed: _verifyOTP,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: _isResending ? null : _resendOTP,
                          child: _isResending
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: blueColor,
                                  ),
                                )
                              : Text(
                                  'Renvoyer le code',
                                  style: TextStyle(
                                    color: blueColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
