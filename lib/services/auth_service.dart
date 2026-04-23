import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/screens/auth/login_screen.dart';
import 'package:supriz/screens/auth/register_screen.dart';
import 'package:supriz/widgets/toast_notification.dart';
import '../consts/strings.dart';
import '../screens/auth/opt_screen.dart';
import '../screens/auth/reset_pwd.dart';
import '../screens/home/bottom_navigation.dart';
import '../consts/global.dart';
import 'firebase_notification_service.dart';

class AuthService {

  // Fonction pour rendre les messages d'erreur plus clairs
  String _formatErrorMessage(String? message) {
    if (message == null || message.isEmpty) {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    // Traduction des messages courants
    final messageLower = message.toLowerCase();

    // Email
    if (messageLower.contains('email') && (messageLower.contains('exist') || messageLower.contains('taken') || messageLower.contains('already'))) {
      return 'Cet email est déjà utilisé.';
    }
    if (messageLower.contains('email') && (messageLower.contains('invalid') || messageLower.contains('format'))) {
      return 'L\'adresse email n\'est pas valide.';
    }
    if (messageLower.contains('email') && (messageLower.contains('not found') || messageLower.contains('no user') || messageLower.contains('doesn\'t exist'))) {
      return 'Aucun compte trouvé avec cet email.';
    }
    if (messageLower.contains('email') && messageLower.contains('required')) {
      return 'Veuillez entrer votre adresse email.';
    }

    // Mot de passe
    if (messageLower.contains('password') && (messageLower.contains('incorrect') || messageLower.contains('wrong') || messageLower.contains('invalid'))) {
      return 'Mot de passe incorrect.';
    }
    if (messageLower.contains('password') && messageLower.contains('required')) {
      return 'Veuillez entrer votre mot de passe.';
    }
    if (messageLower.contains('password') && (messageLower.contains('short') || messageLower.contains('minimum') || messageLower.contains('at least'))) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (messageLower.contains('password') && messageLower.contains('match')) {
      return 'Les mots de passe ne correspondent pas.';
    }

    // Identifiants
    if (messageLower.contains('credentials') || messageLower.contains('login failed') || messageLower.contains('authentication failed')) {
      return 'Email ou mot de passe incorrect.';
    }

    // Session
    if (messageLower.contains('unauthorized') || messageLower.contains('unauthenticated') || messageLower.contains('not logged')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    // Code de vérification (OTP)
    if (messageLower.contains('otp') && (messageLower.contains('invalid') || messageLower.contains('incorrect') || messageLower.contains('wrong'))) {
      return 'Code de vérification incorrect.';
    }
    if (messageLower.contains('otp') && messageLower.contains('expired')) {
      return 'Code expiré. Demandez un nouveau code.';
    }
    if (messageLower.contains('code') && (messageLower.contains('invalid') || messageLower.contains('incorrect'))) {
      return 'Code de vérification incorrect.';
    }

    // Token
    if (messageLower.contains('token') && (messageLower.contains('invalid') || messageLower.contains('malformed'))) {
      return 'Session invalide. Veuillez vous reconnecter.';
    }
    if (messageLower.contains('token') && messageLower.contains('expired')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }

    // Numéro de téléphone
    if (messageLower.contains('numero') && (messageLower.contains('exist') || messageLower.contains('taken') || messageLower.contains('already') || messageLower.contains('unique') || messageLower.contains('duplicate'))) {
      return 'Ce numéro de téléphone est déjà utilisé par un autre compte.';
    }
    if (messageLower.contains('phone') && (messageLower.contains('exist') || messageLower.contains('taken') || messageLower.contains('already') || messageLower.contains('unique') || messageLower.contains('duplicate'))) {
      return 'Ce numéro de téléphone est déjà utilisé par un autre compte.';
    }
    if ((messageLower.contains('numero') || messageLower.contains('phone')) && messageLower.contains('invalid')) {
      return 'Le numéro de téléphone n\'est pas valide.';
    }
    // Message Laravel: "The numero has already been taken"
    if (messageLower.contains('has already been taken')) {
      if (messageLower.contains('numero') || messageLower.contains('phone')) {
        return 'Ce numéro de téléphone est déjà utilisé par un autre compte.';
      }
      if (messageLower.contains('email')) {
        return 'Cet email est déjà utilisé par un autre compte.';
      }
      return 'Cette information est déjà utilisée par un autre compte.';
    }

    // Validation - messages spécifiques par champ (français et anglais)
    if ((messageLower.contains('nom') || messageLower.contains('name')) && messageLower.contains('required')) {
      return 'Le nom est obligatoire.';
    }
    if (messageLower.contains('email') && messageLower.contains('required')) {
      return 'L\'email est obligatoire.';
    }
    if ((messageLower.contains('numero') || messageLower.contains('phone') || messageLower.contains('tel')) && messageLower.contains('required')) {
      return 'Le numéro de téléphone est obligatoire.';
    }
    if (messageLower.contains('password') && messageLower.contains('required')) {
      return 'Le mot de passe est obligatoire.';
    }
    // Messages Laravel génériques
    if (messageLower.contains('the') && messageLower.contains('field') && messageLower.contains('required')) {
      return 'Veuillez remplir tous les champs.';
    }
    if (messageLower.contains('validation') || messageLower.contains('required field')) {
      return 'Veuillez remplir tous les champs correctement.';
    }
    if (messageLower.contains('must be') && messageLower.contains('characters')) {
      return 'Le format des données n\'est pas correct.';
    }

    // Nom d'utilisateur
    if (messageLower.contains('name') && messageLower.contains('required')) {
      return 'Veuillez entrer votre nom.';
    }
    if (messageLower.contains('user') && (messageLower.contains('exist') || messageLower.contains('taken'))) {
      return 'Ce nom d\'utilisateur est déjà pris.';
    }

    // Compte
    if (messageLower.contains('account') && messageLower.contains('disabled')) {
      return 'Ce compte a été désactivé.';
    }
    if (messageLower.contains('account') && (messageLower.contains('not verified') || messageLower.contains('unverified'))) {
      return 'Compte non vérifié. Vérifiez votre email.';
    }
    if (messageLower.contains('account') && messageLower.contains('locked')) {
      return 'Compte bloqué. Contactez le support.';
    }

    // Serveur
    if (messageLower.contains('server') || messageLower.contains('internal') || messageLower.contains('500')) {
      return 'Erreur serveur. Veuillez réessayer plus tard.';
    }

    // Connexion
    if (messageLower.contains('network') || messageLower.contains('connection') || messageLower.contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    }

    // Tentatives
    if (messageLower.contains('too many') || messageLower.contains('rate limit') || messageLower.contains('throttle')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }

    // Si le message est court et lisible (pas de texte technique), le garder
    if (message.length < 80 &&
        !message.contains('Exception') &&
        !message.contains('Error:') &&
        !message.contains('null') &&
        !message.contains('undefined') &&
        !RegExp(r'[{}\[\]]').hasMatch(message)) {
      return message;
    }

    return 'Une erreur est survenue. Veuillez réessayer.';
  }

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
        ToastNotification.success(context, 'Inscription réussie !');
        // Envoyer l'OTP
        await sendOtpIns(email, context, setLoading);
      } else {
        // Gestion des erreurs
        final responseData = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseData['message']));
      }
    } catch (error) {
      setLoading(false); // Fin du chargement
      ToastNotification.error(context, 'Connexion impossible. Vérifiez votre connexion internet.');
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
      ToastNotification.success(context, 'Code de vérification envoyé par email.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
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
      ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
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
          ToastNotification.success(context, 'Connexion réussie !');

          // Stocker le token dans shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token'] ?? '');
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? ''); // Stocker le nom de l'utilisateur
          await prefs.setString('numero', responseData['numero'] ?? ''); // Stocker le numéro de l'utilisateur
          await prefs.setString('email', responseData['email'] ?? ''); // Stocker l'email de l'utilisateur
          await prefs.setString('profileImagePath', responseData['image'] ?? ''); // Stocker l'URL de l'image de profil de l'utilisateur

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
          ToastNotification.error(context, _formatErrorMessage(responseData['message']));
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
      }
    } catch (error) {
      setLoading(false);
      ToastNotification.error(context, 'Connexion impossible. Vérifiez votre connexion internet.');
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
          ToastNotification.success(context, 'Déconnexion réussie !');

          // Supprimer le token et les données utilisateur des shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.setBool('isLoggedIn', false);
          // Nettoyer les données de photo de profil pour éviter le partage entre comptes
          await prefs.remove('localProfileImagePath');
          await prefs.remove('profileImagePath');
          await prefs.remove('name');
          await prefs.remove('email');
          await prefs.remove('numero');
          // Réinitialiser le notifier de photo de profil
          profileImageNotifier.value = null;

          // Déconnecter Google pour permettre de choisir un autre compte
          try {
            await GoogleSignIn().signOut();
          } catch (e) {
            // Ignorer les erreurs de déconnexion Google
          }

          // Rediriger vers l'écran de connexion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Gestion des erreurs
          ToastNotification.error(context, _formatErrorMessage(responseData['message']));
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
      }
    } catch (error) {
      setLoading(false);
      ToastNotification.error(context, 'Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  Future<void> deleteUser(BuildContext context, Function setLoading) async {
    setLoading(true); // Début du chargement

    final url = Uri.parse('$domaineapi/deletecompte');
    final token = await _getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('deleteUser response: ${response.statusCode} - ${response.body}');

      setLoading(false); // Fin du chargement

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status']) {
          // Suppression réussie
          ToastNotification.success(context, 'Compte supprimé avec succès !');

          // Supprimer le token et les données utilisateur des shared_preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.setBool('isLoggedIn', false);
          // Nettoyer les données de photo de profil
          await prefs.remove('localProfileImagePath');
          await prefs.remove('profileImagePath');
          await prefs.remove('name');
          await prefs.remove('email');
          await prefs.remove('numero');
          // Réinitialiser le notifier de photo de profil
          profileImageNotifier.value = null;

          // Rediriger vers l'écran d'inscription
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Gestion des erreurs
          ToastNotification.error(context, _formatErrorMessage(responseData['message']));
        }
      } else {
        final responseBody = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
      }
    } catch (error) {
      setLoading(false);
      ToastNotification.error(context, 'Connexion impossible. Vérifiez votre connexion internet.');
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
          ToastNotification.success(context, 'Connexion réussie !');

          // Stocker les informations utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? name);
          await prefs.setString('email', responseData['email'] ?? email);
          await prefs.setString('numero', responseData['numero'] ?? '');
          await prefs.setString('profileImagePath', responseData['image'] ?? '');

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
          ToastNotification.success(context, 'Connexion réussie !');

          // Stocker les informations utilisateur
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('name', responseData['name'] ?? name);
          await prefs.setString('email', responseData['email'] ?? email);
          await prefs.setString('numero', responseData['numero'] ?? '');
          await prefs.setString('profileImagePath', responseData['image'] ?? '');

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
          ToastNotification.error(context, _formatErrorMessage(responseData['message']));
        }
      } else if (response.statusCode == 422) {
        // Erreur de validation
        final responseBody = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseBody['message'] ?? 'Veuillez vérifier vos informations.'));
      } else {
        final responseBody = jsonDecode(response.body);
        ToastNotification.error(context, _formatErrorMessage(responseBody['message'] ?? 'Impossible de se connecter.'));
      }
    } catch (error) {
      setLoading(false);
      ToastNotification.error(context, 'Connexion impossible. Vérifiez votre connexion internet.');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
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
      ToastNotification.success(context, 'Code de vérification envoyé par email.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: email)),
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
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
      ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
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
      ToastNotification.success(context, 'Mot de passe modifié. Vous pouvez vous connecter.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ToastNotification.error(context, _formatErrorMessage(responseBody['message']));
    }
  }
}
