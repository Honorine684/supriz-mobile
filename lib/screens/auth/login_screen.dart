// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supriz/screens/auth/mdp_oublie_screen.dart';
import 'package:supriz/screens/auth/register_screen.dart';
import '../../consts/consts.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  final AuthService _authService = AuthService();

  // État pour le social login
  bool _showSocialLoginForm = false;
  String? _socialUserName;
  String? _socialUserEmail;
  String? _socialUserPhoto;
  String? _socialProvider;
  String? _socialToken;
  String _phoneNumber = '';
  bool _isPhoneValid = false;
  String? _phoneErrorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '852250813157-korlpa310j3d4bv4sd2rc5lt2laqdaoi.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _authService.loginUser(
        emailController.text,
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
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Essayer de se connecter d'abord (utilisateur existant)
        final success = await _tryDirectSocialLogin(
          provider: 'google',
          token: googleAuth.idToken ?? '',
          email: googleUser.email,
          name: googleUser.displayName ?? '',
        );

        if (!success) {
          // Nouvel utilisateur - afficher le formulaire de téléphone
          setState(() {
            _socialUserName = googleUser.displayName;
            _socialUserEmail = googleUser.email;
            _socialUserPhoto = googleUser.photoUrl;
            _socialProvider = 'google';
            _socialToken = googleAuth.idToken;
            _showSocialLoginForm = true;
            _isGoogleLoading = false;
          });
          _animationController.forward();
        }
      } else {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isGoogleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Google: $error')),
      );
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

      final name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      final email = credential.email ?? '';

      // Essayer de se connecter d'abord (utilisateur existant)
      final success = await _tryDirectSocialLogin(
        provider: 'apple',
        token: credential.identityToken ?? '',
        email: email,
        name: name,
      );

      if (!success) {
        // Nouvel utilisateur - afficher le formulaire de téléphone
        setState(() {
          _socialUserName = name.isNotEmpty ? name : 'Utilisateur Apple';
          _socialUserEmail = email;
          _socialUserPhoto = null;
          _socialProvider = 'apple';
          _socialToken = credential.identityToken;
          _showSocialLoginForm = true;
          _isAppleLoading = false;
        });
        _animationController.forward();
      }
    } catch (error) {
      setState(() {
        _isAppleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion Apple: $error')),
      );
    }
  }

  // Essayer une connexion directe (pour utilisateur existant)
  Future<bool> _tryDirectSocialLogin({
    required String provider,
    required String token,
    required String email,
    required String name,
  }) async {
    try {
      final result = await _authService.trySocialLogin(
        provider: provider,
        token: token,
        email: email,
        name: name,
        context: context,
        setLoading: (bool isLoading) {
          setState(() {
            if (provider == 'google') {
              _isGoogleLoading = isLoading;
            } else {
              _isAppleLoading = isLoading;
            }
          });
        },
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  // Finaliser l'inscription avec le numéro de téléphone
  Future<void> _completeSocialSignUp() async {
    if (_phoneNumber.isEmpty) {
      setState(() {
        _phoneErrorMessage = 'Veuillez entrer votre numéro de téléphone';
      });
      return;
    }

    if (!_isPhoneValid) {
      setState(() {
        _phoneErrorMessage = 'Veuillez entrer un numéro valide';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneErrorMessage = null;
    });

    await _authService.socialLogin(
      provider: _socialProvider!,
      token: _socialToken!,
      email: _socialUserEmail!,
      name: _socialUserName!,
      numero: _phoneNumber,
      context: context,
      setLoading: (bool isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
  }

  void _cancelSocialLogin() {
    _animationController.reverse().then((_) {
      setState(() {
        _showSocialLoginForm = false;
        _socialUserName = null;
        _socialUserEmail = null;
        _socialUserPhoto = null;
        _socialProvider = null;
        _socialToken = null;
        _phoneNumber = '';
        _isPhoneValid = false;
        _phoneErrorMessage = null;
      });
    });
    // Déconnecter Google si nécessaire
    _googleSignIn.signOut();
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
                SizedBox(height: 40),
                // Logo
                Image.asset(icAppLogo, height: 100),
                SizedBox(height: 16),
                // Titre
                Text(
                  'Se connecter à $appname',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                // Card de connexion
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
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _showSocialLoginForm
                          ? _buildSocialLoginForm()
                          : _buildNormalLoginForm(),
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

  Widget _buildNormalLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey('normal_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre Connexion
          Center(
            child: Text(
              'Connexion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
          ),
          SizedBox(height: 24),
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
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
              return null;
            },
          ),
          SizedBox(height: 24),
          // Bouton Se connecter
          ourButton(
            text: 'Se connecter',
            onPressed: loginUser,
            isLoading: _isLoading,
          ),
          SizedBox(height: 12),
          // Mot de passe oublié
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MdpOublieScreen()),
                );
              },
              child: Text(
                'Mot de passe oublié?',
                style: TextStyle(color: blueColor, fontSize: 14),
              ),
            ),
          ),
          SizedBox(height: 8),
          // Ou se connecter
          Center(
            child: Text(
              'ou se connecter',
              style: TextStyle(color: greyColor, fontSize: 14),
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
                  label: 'Google',
                  isGoogle: true,
                ),
              ),
              SizedBox(width: 12),
              // Apple
              if (Platform.isIOS)
                Expanded(
                  child: _SocialButton(
                    onPressed: _handleAppleSignIn,
                    isLoading: _isAppleLoading,
                    label: 'Apple',
                    isGoogle: false,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          // Lien inscription
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Vous n'avez pas de compte ? ",
                style: TextStyle(color: blackColor, fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text(
                  "S'inscrire",
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
    );
  }

  Widget _buildSocialLoginForm() {
    return Column(
      key: ValueKey('social_form'),
      children: [
        // Bouton retour
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _cancelSocialLogin,
            icon: Icon(Icons.arrow_back_ios, color: greyColor),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ),
        SizedBox(height: 8),
        // Titre
        Text(
          'Finaliser l\'inscription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        SizedBox(height: 24),
        // Photo de profil
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: greyColor.withOpacity(0.1),
            border: Border.all(color: blueColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: blueColor.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: _socialUserPhoto != null
                ? Image.network(
                    _socialUserPhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      _socialProvider == 'apple' ? Icons.apple : Icons.person,
                      size: 40,
                      color: greyColor,
                    ),
                  )
                : Icon(
                    _socialProvider == 'apple' ? Icons.apple : Icons.person,
                    size: 40,
                    color: greyColor,
                  ),
          ),
        ),
        SizedBox(height: 16),
        // Nom
        Text(
          _socialUserName ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        SizedBox(height: 4),
        // Email
        Text(
          _socialUserEmail ?? '',
          style: TextStyle(
            fontSize: 14,
            color: greyColor,
          ),
        ),
        SizedBox(height: 8),
        // Badge provider
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _socialProvider == 'google'
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_socialProvider == 'google')
                Image.network(
                  'https://www.google.com/favicon.ico',
                  height: 16,
                  width: 16,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.g_mobiledata,
                    size: 16,
                    color: Colors.red,
                  ),
                )
              else
                Icon(Icons.apple, size: 16, color: blackColor),
              SizedBox(width: 6),
              Text(
                _socialProvider == 'google' ? 'Google' : 'Apple',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _socialProvider == 'google' ? Colors.red : blackColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: greyColor.withOpacity(0.3))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ajoutez votre numéro',
                style: TextStyle(color: greyColor, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: greyColor.withOpacity(0.3))),
          ],
        ),
        SizedBox(height: 20),
        // Champ téléphone
        IntlPhoneField(
          decoration: InputDecoration(
            hintText: 'Numéro de téléphone',
            hintStyle: TextStyle(color: greyColor, fontSize: 14),
            filled: true,
            fillColor: greyColor.withOpacity(0.1),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorText: _phoneErrorMessage,
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red, width: 2),
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
              fillColor: greyColor.withOpacity(0.1),
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
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return 'Ce champ est requis';
            }
            // Pour le Bénin: 8 chiffres
            if (phone.number.length != 8 && phone.number.length != 10) {
              return 'Le numéro doit contenir 8 ou 10 chiffres';
            }
            return null;
          },
          onChanged: (phone) {
            setState(() {
              _phoneNumber = phone.completeNumber;
              _isPhoneValid = phone.isValidNumber();
              if (_isPhoneValid) {
                _phoneErrorMessage = null;
              }
            });
          },
        ),
        SizedBox(height: 24),
        // Bouton Confirmer
        ourButton(
          text: 'Créer mon compte',
          onPressed: _completeSocialSignUp,
          isLoading: _isLoading,
        ),
        SizedBox(height: 16),
        // Texte légal avec liens cliquables
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 11, color: greyColor),
            children: [
              TextSpan(text: 'En continuant, vous acceptez nos '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://suprizs.com/conditions-utilisation')),
                  child: Text(
                    'conditions d\'utilisation',
                    style: TextStyle(fontSize: 11, color: blueColor, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              TextSpan(text: ' et notre '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://suprizs.com/politique-confidentialite')),
                  child: Text(
                    'politique de confidentialité',
                    style: TextStyle(fontSize: 11, color: blueColor, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
      ],
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
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: BorderSide(color: greyColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
