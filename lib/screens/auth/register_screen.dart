// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supriz/screens/auth/login_screen.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController(text: '');
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  final AuthService _authService = AuthService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '852250813157-korlpa310j3d4bv4sd2rc5lt2laqdaoi.apps.googleusercontent.com',
  );

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _authService.registerUser(
        usernameController.text,
        emailController.text,
        phoneController.text,
        passwordController.text,
        context,
        (bool isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        await _authService.socialLogin(
          provider: 'google',
          token: googleAuth.idToken ?? '',
          email: googleUser.email,
          name: googleUser.displayName ?? '',
          context: context,
          setLoading: (bool isLoading) {
            setState(() {
              _isGoogleLoading = isLoading;
            });
          },
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Google: $error')),
      );
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      await _authService.socialLogin(
        provider: 'apple',
        token: credential.identityToken ?? '',
        email: credential.email ?? '',
        name: '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
        context: context,
        setLoading: (bool isLoading) {
          setState(() {
            _isAppleLoading = isLoading;
          });
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Apple: $error')),
      );
    } finally {
      setState(() {
        _isAppleLoading = false;
      });
    }
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
                SizedBox(height: 30),
                // Logo
                Image.asset(icAppLogo, height: 80),
                SizedBox(height: 12),
                // Titre
                Text(
                  'Inscription sur $appname',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                // Card d'inscription
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre Inscription
                          Center(
                            child: Text(
                              'Inscription',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: blackColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Nom d'utilisateur
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              hintText: "Nom d'utilisateur",
                              hintStyle: TextStyle(color: greyColor, fontSize: 14),
                              filled: true,
                              fillColor: greyColor.withValues(alpha: 0.1),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.person_outline, color: greyColor),
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red, width: 1),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ce champ est requis';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          // Email
                          TextFormField(
                            controller: emailController,
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red, width: 1),
                              ),
                            ),
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
                          SizedBox(height: 16),
                          // Numéro
                          IntlPhoneField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              hintText: 'Numéro de téléphone',
                              hintStyle: TextStyle(color: greyColor, fontSize: 14),
                              filled: true,
                              fillColor: greyColor.withValues(alpha: 0.1),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red, width: 1),
                              ),
                            ),
                            initialCountryCode: 'BJ',
                            languageCode: 'fr',
                            invalidNumberMessage: 'Numéro invalide',
                            disableLengthCheck: true,
                            dropdownIconPosition: IconPosition.trailing,
                            flagsButtonPadding: EdgeInsets.only(left: 10),
                            showDropdownIcon: true,
                            dropdownIcon: Icon(Icons.keyboard_arrow_down, color: greyColor),
                            pickerDialogStyle: PickerDialogStyle(
                              searchFieldInputDecoration: InputDecoration(
                                hintText: 'Rechercher un pays',
                                hintStyle: TextStyle(color: greyColor, fontSize: 14),
                                filled: true,
                                fillColor: greyColor.withValues(alpha: 0.1),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                prefixIcon: Icon(Icons.search, color: greyColor),
                              ),
                            ),
                            onChanged: (phone) {
                              // Stocker le numéro complet avec code pays
                              phoneController.text = phone.completeNumber;
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return 'Ce champ est requis';
                              }
                              // Pour le Bénin: 8 chiffres exactement
                              if (phone.number.length != 8 && phone.number.length != 10) {
                                return 'Le numéro doit contenir 8 ou 10 chiffres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          // Mot de passe
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Mot de passe',
                              hintStyle: TextStyle(color: greyColor, fontSize: 14),
                              filled: true,
                              fillColor: greyColor.withValues(alpha: 0.1),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.lock_outline, color: greyColor),
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
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.red, width: 1),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: greyColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ce champ est requis';
                              }
                              if (value.length < 8) {
                                return 'Le mot de passe doit contenir au moins 8 caractères';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          // Bouton Créer un compte
                          ourButton(
                            text: 'Créer un compte',
                            onPressed: registerUser,
                            isLoading: _isLoading,
                          ),
                          SizedBox(height: 16),
                          // Ou s'inscrire
                          Center(
                            child: Text(
                              "ou s'inscrire",
                              style: TextStyle(
                                color: greyColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Boutons sociaux
                          Row(
                            children: [
                              // Google
                              Expanded(
                                child: _SocialButton(
                                  onPressed: _handleGoogleSignIn,
                                  isLoading: _isGoogleLoading,
                                  label: 'avec google',
                                  isGoogle: true,
                                ),
                              ),
                              SizedBox(width: 12),
                              // Apple (iOS uniquement)
                              if (Platform.isIOS)
                                Expanded(
                                  child: _SocialButton(
                                    onPressed: _handleAppleSignIn,
                                    isLoading: _isAppleLoading,
                                    label: 'avec icloud',
                                    isGoogle: false,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Lien connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Vous avez déjà un compte ? ",
                                style: TextStyle(
                                  color: blackColor,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Se connecter",
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
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final bool isGoogle;

  const _SocialButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.isGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        side: BorderSide(color: greyColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: blueColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isGoogle)
                  Image.network(
                    'https://www.google.com/favicon.ico',
                    height: 20,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'G',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  )
                else
                  Icon(Icons.apple, color: blackColor, size: 24),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith('01')) {
      if (newValue.text.length > 10) {
        return oldValue;
      }
    } else {
      if (newValue.text.length > 8) {
        return oldValue;
      }
    }
    return newValue;
  }
}

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final String _errorMessage = '';
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> verifyOtp() async {
    final otp = _otpController.text;
    final email = widget.email;

    setState(() {
      _isLoading = true;
    });

    await _authService.verifyOtp(email, otp, context, (bool isLoading) {
      setState(() {
        _isLoading = isLoading;
      });
    });
  }

  Future<void> resendOtp() async {
    final email = widget.email;

    setState(() {
      _isLoading = true;
    });

    await _authService.resendOtp(email, context, (bool isLoading) {
      setState(() {
        _isLoading = isLoading;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: const CustomAppBar(title: 'Vérification OTP'),
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
                fieldOuterPadding: const EdgeInsets.all(10),
              ),
              keyboardType: TextInputType.number,
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
              onPressed: verifyOtp,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            ourButton(
              text: 'Renvoyer le code',
              backgroundColor: roscColor,
              textColor: blackColor,
              onPressed: resendOtp,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
