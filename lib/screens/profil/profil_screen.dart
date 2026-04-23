// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/services/profil_service.dart';
import 'package:supriz/widgets/appbar_custom.dart';
import 'package:supriz/widgets/toast_notification.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String? storedName;
  String? storedNumero;
  String? storedEmail;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _chargeInfo();
    _loadProfileImage();
    profileImageNotifier.addListener(_updateProfileImage);
  }

  @override
  void dispose() {
    profileImageNotifier.removeListener(_updateProfileImage);
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localImagePath = prefs.getString('localProfileImagePath');

    if (localImagePath != null && File(localImagePath).existsSync()) {
      profileImageNotifier.value = File(localImagePath);
    } else {
      String? profileImagePath = prefs.getString('profileImagePath');
      if (profileImagePath != null) {
        String fullImagePath = "$domaineapiImage/$profileImagePath";
        File? imageFile = await _downloadImage(fullImagePath);
        if (imageFile != null) {
          await prefs.setString('localProfileImagePath', imageFile.path);
          profileImageNotifier.value = imageFile;
        }
      }
    }
  }

  Future<File?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/profile_image.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  void _updateProfileImage() {
    setState(() {
      _profileImage = profileImageNotifier.value;
    });
  }

  Future<void> _saveProfileImage(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imagePath);
    profileImageNotifier.value = File(imagePath);
  }

  Future<void> _chargeInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedName = prefs.getString('name');
      storedNumero = prefs.getString('numero');
      storedEmail = prefs.getString('email');
    });
  }

  void _showEditDialog(BuildContext context, String title, Widget screen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Non', style: TextStyle(color: greyColor)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => screen),
                    ).then((_) => _chargeInfo());
                  },
                  child: Text('Oui', style: TextStyle(color: blueColor)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      try {
        final profilService = ProfilService();
        await profilService.updateProfileImage(file);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('localProfileImagePath', file.path);
        profileImageNotifier.value = file;
        if (mounted) {
          ToastNotification.success(context, 'Photo de profil mise à jour');
        }
      } catch (e) {
        if (mounted) {
          ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: 'Profil'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            // Photo de profil
            Stack(
                        children: [
                          ValueListenableBuilder<File?>(
                            valueListenable: profileImageNotifier,
                            builder: (context, image, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: whiteColor, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: greyColor.withOpacity(0.2),
                                  backgroundImage: image != null ? FileImage(image) : null,
                                  child: image == null
                                      ? Icon(Icons.person, color: greyColor, size: 60)
                                      : null,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndSaveImage,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: blueColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: whiteColor, width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: whiteColor,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            SizedBox(height: 16),
            // Nom
            Text(
              storedName != null && storedName!.isNotEmpty
                  ? storedName![0].toUpperCase() + storedName!.substring(1)
                  : 'Utilisateur',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 20),
            // Infos cards
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.person_outline,
                            label: "Nom",
                            value: storedName ?? '',
                            onTap: () => _showEditDialog(
                              context,
                              "Modifier le nom d'utilisateur ?",
                              ChangeNomScreen(),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.phone_outlined,
                            label: "Numéro",
                            value: storedNumero ?? '',
                            onTap: () => _showEditDialog(
                              context,
                              "Modifier le numéro ?",
                              ChangeNumberScreen(),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.email_outlined,
                            label: "Email",
                            value: storedEmail ?? '',
                            onTap: () => _showEditDialog(
                              context,
                              "Modifier l'email ?",
                              ChangeEmailScreen(),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.lock_outline,
                            label: "Mot de passe",
                            value: '••••••••',
                            onTap: () => _showEditDialog(
                              context,
                              "Modifier le mot de passe ?",
                              ChangePasswordScreen(),
                            ),
                          ),
                        ],
                      ),
                    ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greyColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: blueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: blueColor, size: 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: greyColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : '-',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: greyColor),
          ],
        ),
      ),
    );
  }
}

// ========== Écrans de modification ==========

class ChangeNomScreen extends StatefulWidget {
  const ChangeNomScreen({super.key});

  @override
  State<ChangeNomScreen> createState() => _ChangeNomScreenState();
}

class _ChangeNomScreenState extends State<ChangeNomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ProfilService _profilService = ProfilService();
  bool _isLoading = false;

  Future<void> _updateName() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _profilService.updateName(_controller.text);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _controller.text);
      if (mounted) {
        ToastNotification.success(context, 'Nom mis à jour');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildEditScreen(
      context: context,
      title: "Modifier le nom",
      controller: _controller,
      hint: "Entrez le nouveau nom",
      isLoading: _isLoading,
      onSave: _updateName,
    );
  }
}

class ChangeNumberScreen extends StatefulWidget {
  const ChangeNumberScreen({super.key});

  @override
  State<ChangeNumberScreen> createState() => _ChangeNumberScreenState();
}

class _ChangeNumberScreenState extends State<ChangeNumberScreen> {
  final ProfilService _profilService = ProfilService();
  bool _isLoading = false;
  String _completeNumber = '';

  Future<void> _updateNumber() async {
    if (_completeNumber.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _profilService.updateNumber(_completeNumber);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('numero', _completeNumber);
      if (mounted) {
        ToastNotification.success(context, 'Numéro mis à jour');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Modifier le numéro"),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            IntlPhoneField(
              decoration: InputDecoration(
                hintText: "Numéro de téléphone",
                hintStyle: TextStyle(color: greyColor),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: EdgeInsets.only(left: 10),
              showDropdownIcon: true,
              dropdownIcon: Icon(Icons.keyboard_arrow_down, color: greyColor),
              pickerDialogStyle: PickerDialogStyle(
                searchFieldInputDecoration: InputDecoration(
                  hintText: 'Rechercher un pays',
                  hintStyle: TextStyle(color: greyColor),
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
                _completeNumber = phone.completeNumber;
              },
              validator: (phone) {
                if (phone == null || phone.number.isEmpty) {
                  return 'Ce champ est requis';
                }
                if (phone.number.length != 10) {
                  return 'Le numéro doit contenir 10 chiffres';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: whiteColor)
                    : Text('Enregistrer', style: TextStyle(color: whiteColor, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ProfilService _profilService = ProfilService();
  bool _isLoading = false;

  Future<void> _updateEmail() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _profilService.updateEmail(_controller.text);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _controller.text);
      if (mounted) {
        ToastNotification.success(context, 'Email mis à jour');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildEditScreen(
      context: context,
      title: "Modifier l'email",
      controller: _controller,
      hint: "Entrez le nouvel email",
      keyboardType: TextInputType.emailAddress,
      isLoading: _isLoading,
      onSave: _updateEmail,
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final ProfilService _profilService = ProfilService();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    if (_newController.text != _confirmController.text) {
      ToastNotification.error(context, 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _profilService.updatePassword(_oldController.text, _newController.text);
      if (mounted) {
        ToastNotification.success(context, 'Mot de passe mis à jour');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: 'Modifier le mot de passe'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildPasswordField(
              controller: _oldController,
              label: "Ancien mot de passe",
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              controller: _newController,
              label: "Nouveau mot de passe",
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmController,
              label: "Confirmer le mot de passe",
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: whiteColor)
                    : Text('Enregistrer', style: TextStyle(color: whiteColor, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
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
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: greyColor),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// Helper pour construire les écrans d'édition simples
Widget _buildEditScreen({
  required BuildContext context,
  required String title,
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  required bool isLoading,
  required VoidCallback onSave,
}) {
  return Scaffold(
    backgroundColor: whiteColor,
    appBar: CustomAppBar(title: title),
    body: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: greyColor, fontSize: 14),
              filled: true,
              fillColor: greyColor.withValues(alpha: 0.1),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                keyboardType == TextInputType.emailAddress
                    ? Icons.email_outlined
                    : Icons.person_outline,
                color: greyColor,
              ),
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: whiteColor)
                  : Text('Enregistrer', style: TextStyle(color: whiteColor, fontSize: 16)),
            ),
          ),
        ],
      ),
    ),
  );
}
