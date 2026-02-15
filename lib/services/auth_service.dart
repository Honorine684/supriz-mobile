import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/screens/auth/login_screen.dart';
import 'package:supriz/screens/auth/register_screen.dart';
import '../consts/colors.dart';
import '../consts/strings.dart';
import '../screens/auth/opt_screen.dart';
import '../screens/auth/reset_pwd.dart';
import '../screens/home/bottom_navigation.dart';
import '../screens/panier/cart_controller.dart';
import 'firebase_notification_service.dart';

class AuthService {

  Future<void> registerUser(
      String nom, String email, String numero, String password, BuildContext context, Function setLoading) async {
    final url = Uri.parse('$domaineapi/register');

    setLoading(true); // Début du chargement

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nom': nom,
          'prenom': '', // Le prénom n'est pas demandé dans le formulaire
          'email': email,
          'numero': numero,
          'password': password,
          'password_confirmation': password,
        }),
      );

      setLoading(false); // Fin du chargement

      if (response.statusCode == 200) {
        // Inscription réussie
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie !'),
            backgroundColor: blueColor,
          ),
        );
        // Envoyer l'OTP
        await sendOtpIns(email, context, setLoading);
      } else {
        // Gestion des erreurs
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${responseData['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setLoading(false); // Fin du chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendOtpIns(String email, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final response = await http.post(
      Uri.parse('$domaineapi/send-otp-mdp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'user': email, // Assuming 'id_user' is the email in your case
      }),
    );

    setLoading(false); // Fin du chargement

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> verifyOtp(String email, String otp, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final response = await http.post(
      Uri.parse('$domaineapi/verify-otp-compte'),
      body: {
        'user': email,
        'otp': otp,
      },
    );

    setLoading(false); // Fin du chargement

    if (response.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> resendOtp(String email, BuildContext context, Function setLoading) async {
    await sendOtpIns(email, context, setLoading);
  }

  Future<void> loginUser(String email, String password, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final url = Uri.parse('$domaineapi/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      setLoading(false); // Fin du chargement

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          // Connexion réussie
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: blueColor, // Utiliser Colors.blue au lieu de blueColor pour éviter les erreurs
            ),
          );

          // Stocker le token dans shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token'] ?? '');
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? ''); // Stocker le nom de l'utilisateur
          await prefs.setString('numero', responseData['numero'] ?? ''); // Stocker le numéro de l'utilisateur
          await prefs.setString('email', responseData['email'] ?? ''); // Stocker l'email de l'utilisateur
          await prefs.setString('profileImagePath', responseData['image'] ?? ''); // Stocker l'URL de l'image de profil de l'utilisateur

          // Récupérer immédiatement les achats après la connexion (si disponible)
          try {
            final cartController = Get.find<CartController>();
            await cartController.fetchAchats();
          } catch (e) {
            // CartController non initialisé, ignorer
          }

          // Envoyer le token FCM au backend
          try {
            await FirebaseNotificationService().sendTokenToBackend();
          } catch (e) {
            // Ignorer les erreurs FCM
          }

          // Rediriger vers la page d'accueil
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Gestion des erreurs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${responseData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//profileImagePath
  Future<String> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImagePath') ?? '';
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'Invité';
  }

  Future<String> getUserNumero() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('numero') ?? '';
  }

  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  Future<void> logoutUser(BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final url = Uri.parse('$domaineapi/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      setLoading(false); // Fin du chargement

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          // Déconnexion réussie
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Déconnexion réussie !'),
              backgroundColor: blueColor,
            ),
          );

          // Supprimer le token des shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.setBool('isLoggedIn', false);

          // Rediriger vers l'écran de connexion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Gestion des erreurs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${responseData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteUser(BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final url = Uri.parse('$domaineapi/dropUserInTable');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({
          'id': await _getUserId(),
        }),
      );

      setLoading(false); // Fin du chargement

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          // Suppression réussie
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte supprimé avec succès !'),
              backgroundColor: blueColor,
            ),
          );

          // Supprimer le token des shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.setBool('isLoggedIn', false);

          // Rediriger vers l'écran d'inscription
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Gestion des erreurs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${responseData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Essayer une connexion sociale directe (retourne true si réussi, false si numéro requis)
  Future<bool> trySocialLogin({
    required String provider,
    required String token,
    required String email,
    required String name,
    required BuildContext context,
    required Function setLoading,
  }) async {
    setLoading(true);

    final url = Uri.parse('$domaineapi/social-login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': provider,
          'token': token,
          'email': email,
          'name': name,
        }),
      );

      setLoading(false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: blueColor,
            ),
          );

          // Stocker les informations utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? name);
          await prefs.setString('email', responseData['email'] ?? email);
          await prefs.setString('numero', responseData['numero'] ?? '');
          await prefs.setString('profileImagePath', responseData['image'] ?? '');

          // Récupérer les achats
          try {
            final cartController = Get.find<CartController>();
            await cartController.fetchAchats();
          } catch (e) {
            // CartController non initialisé, ignorer
          }

          // Envoyer le token FCM au backend
          try {
            await FirebaseNotificationService().sendTokenToBackend();
          } catch (e) {
            // Ignorer les erreurs FCM
          }

          // Rediriger vers la page d'accueil
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
            (Route<dynamic> route) => false,
          );
          return true;
        }
        return false;
      } else if (response.statusCode == 422) {
        // Numéro requis - nouvel utilisateur
        return false;
      }
      return false;
    } catch (error) {
      setLoading(false);
      return false;
    }
  }

  // Méthode pour la connexion sociale (Google/Apple)
  Future<void> socialLogin({
    required String provider,
    required String token,
    required String email,
    required String name,
    String? numero,
    required BuildContext context,
    required Function setLoading,
  }) async {
    setLoading(true);

    final url = Uri.parse('$domaineapi/social-login');

    try {
      final Map<String, dynamic> body = {
        'provider': provider,
        'token': token,
        'email': email,
        'name': name,
      };

      // Ajouter le numéro si fourni
      if (numero != null && numero.isNotEmpty) {
        body['numero'] = numero;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      setLoading(false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: blueColor,
            ),
          );

          // Stocker les informations utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? name);
          await prefs.setString('email', responseData['email'] ?? email);
          await prefs.setString('numero', responseData['numero'] ?? '');
          await prefs.setString('profileImagePath', responseData['image'] ?? '');

          // Récupérer les achats
          try {
            final cartController = Get.find<CartController>();
            await cartController.fetchAchats();
          } catch (e) {
            // CartController non initialisé, ignorer
          }

          // Envoyer le token FCM au backend
          try {
            await FirebaseNotificationService().sendTokenToBackend();
          } catch (e) {
            // Ignorer les erreurs FCM
          }

          // Rediriger vers la page d'accueil
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${responseData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 422) {
        // Erreur de validation
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message'] ?? 'Erreur de validation'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody['message'] ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  // Méthode pour envoyer l'OTP à l'email de l'utilisateur
  Future<void> sendOtpMdp(String email, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final response = await http.post(
      Uri.parse('$domaineapi/send-otp-mdp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'user': email, // Assuming 'id_user' is the email in your case
      }),
    );

    setLoading(false); // Fin du chargement

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: email)),
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour vérifier l'OTP
  Future<void> verifyOtpMdp(String email, String otp, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final response = await http.post(
      Uri.parse('$domaineapi/verify-otp'),
      body: {
        'user': email,
        'otp': otp,
      },
    );

    setLoading(false); // Fin du chargement

    if (response.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ResetPwd(email: email)),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> resetPassword(String email, String newPassword, BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final response = await http.post(
      Uri.parse('$domaineapi/update-password-mdp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'new_password': newPassword,
      }),
    );

    setLoading(false); // Fin du chargement

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
