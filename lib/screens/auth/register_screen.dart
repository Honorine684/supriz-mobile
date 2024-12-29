import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supriz/screens/auth/login_screen.dart'; // Import de la page de connexion
import 'package:supriz/widgets/auth_widget.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/custom_textField.dart';
import '../../widgets/our_button.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = false; // État de chargement
  final AuthService _authService = AuthService();

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Début du chargement
      });

      await _authService.registerUser(
        usernameController.text,
        emailController.text,
        phoneController.text,
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
                  const Text('Créer un compte sur $appname', style: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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
                          const Text('Inscription', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
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
                                const SizedBox(height: 8),

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
                                const SizedBox(height: 8),

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
                                const SizedBox(height: 8),

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
                                    if (value.length < 8) {
                                      return 'Le mot de passe doit contenir au moins 8 caractères';
                                    }
                                    if (!RegExp(r'^(?=.*[A-Z]).+$').hasMatch(value)) {
                                      return 'Le mot de passe doit contenir au moins une lettre majuscule';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 8),
                                // Bouton pour créer un compte
                                ourButton(
                                  text: 'Creer un compte',
                                  onPressed: registerUser,
                                  isLoading: _isLoading, // Passer l'état de chargement
                                ),
                                const SizedBox(height: 5),
                                const Text('ou'),
                                const SizedBox(height: 5),
                                ourButton(
                                  text: 'Connexion',
                                  backgroundColor: roscColor,
                                  textColor: blackColor,
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
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

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final String _errorMessage = '';
  bool _isLoading = false; // État de chargement
  final AuthService _authService = AuthService();

  Future<void> verifyOtp() async {
    final otp = _otpController.text;
    final email = widget.email;

    setState(() {
      _isLoading = true; // Début du chargement
    });

    await _authService.verifyOtp(email, otp, context, (bool isLoading) {
      setState(() {
        _isLoading = isLoading; // Mettre à jour l'état de chargement
      });
    });
  }

  Future<void> resendOtp() async {
    final email = widget.email;

    setState(() {
      _isLoading = true; // Début du chargement
    });

    await _authService.resendOtp(email, context, (bool isLoading) {
      setState(() {
        _isLoading = isLoading; // Mettre à jour l'état de chargement
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
