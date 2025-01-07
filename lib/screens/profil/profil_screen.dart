// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/services/profil_service.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/appbar_custom.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String? storedFirstname;
  String? storedName;
  String? storedNumero;
  String? storedEmail;
  bool _showingDialog = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _chargeInfo();
    _loadProfileImage();
    ;
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
      print('Local Image Path: $localImagePath'); // Ajoutez cette ligne pour le débogage
      profileImageNotifier.value = File(localImagePath);
    } else {
      String? profileImagePath = prefs.getString('profileImagePath');
      if (profileImagePath != null) {
        String fullImagePath = "$domaineapiImage/$profileImagePath";
        print('Profile Image Path: $fullImagePath'); // Ajoutez cette ligne pour le débogage

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
        print('Image downloaded to ${file.path}'); // Ajoutez cette ligne pour le débogage
        return file;
      }
    } catch (e) {
      print('Error downloading image: $e');
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

  void _showConfirmationDialog(
      BuildContext context, String message, Function onConfirm) {
    setState(() {
      _showingDialog = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  message,
                  style: const TextStyle(fontFamily: 'bold', fontSize: 18),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showingDialog = false;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Non',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showingDialog = false;
                        });
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: const Text(
                        'Oui',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _showingDialog = false;
      });
    });
  }

  void _showEditPhotoDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Modifier la photo de profil",
      () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => ChangePhotoScreen(image: _profileImage)),
        );
        if (result != null && result is File) {
          setState(() {
            _profileImage = result;
          });
          _saveProfileImage(result.path);
        }
      },
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Modifier le nom d'utilisateur",
      () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => const ChangeNomPrenomScreen()),
        );
      },
    );
  }

  void _showEditNumberDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Modifier le numéro de téléphone",
      () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ChangeNumberScreen()),
        );
      },
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Modifier l'adresse email",
      () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ChangeEmailScreen()),
        );
      },
    );
  }

  void _showEditPasswordDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      'Modifier le mot de passe',
      () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
      },
    );
  }

  Future<void> _chargeInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedFirstname = prefs.getString('firstname');
      storedName = prefs.getString('name');
      storedNumero = prefs.getString('numero');
      storedEmail = prefs.getString('email');
    });
  }

  @override
  Widget build(BuildContext context) {
    double profileImageSize = MediaQuery.of(context).size.width * 0.3;
    double spacing = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: spacing),
                Stack(
                  children: [
                    Center(
                      child: ValueListenableBuilder<File?>(
                        valueListenable: profileImageNotifier,
                        builder: (context, image, child) {
                          return CircleAvatar(
                            backgroundColor: whiteColor,
                            radius: profileImageSize / 2,
                            backgroundImage:
                                image != null ? FileImage(image) : null,
                            child: image == null
                                ? Icon(
                                    Icons.account_circle,
                                    color: blackColor,
                                    size: profileImageSize + 10,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: (MediaQuery.of(context).size.width -
                                  profileImageSize) /
                              2 -
                          15,
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            size: 25,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            _showEditPhotoDialog(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing / 2),
                Text(
                  "${storedName![0].toUpperCase() + storedName!.substring(1)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing),
                _buildInfoRow(
                    context,
                    "Nom d'utilisateur",
                    "${storedName![0].toUpperCase() + storedName!.substring(1)}",
                    _showEditUsernameDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                    context, 'Numéro', "$storedNumero", _showEditNumberDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                    context, 'Email', "$storedEmail", _showEditEmailDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, 'Mot de passe', '********',
                    _showEditPasswordDialog),
              ],
            ),
          ),
          if (_showingDialog)
            Positioned(
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      Function(BuildContext) onTap) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: cloudColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  final ProfilService _ProfilService =
      ProfilService(); // Récupère le prénom depuis les prefs
  String? storedEmail;
  void _chargeInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedEmail = prefs.getString('email');
    });
  }

  @override
  Widget build(BuildContext context) {
    _chargeInfo();
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Modifier l'email",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: cloudColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      "Email: $storedEmail",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: 'Entrer le nouveau email',
                        hintStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateEmail();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _updateEmail() async {
    try {
      final response = await _ProfilService.updateEmail(emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email mis à jour avec succès'),
        ),
      );

      Navigator.of(context).pop(true);
      //Navigator.of(context).push(
      //MaterialPageRoute(builder: (context) => const ProfilScreen()),
      //);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour de l\'email: $e'),
        ),
      );
    }
  }
}

class ChangeNomPrenomScreen extends StatefulWidget {
  const ChangeNomPrenomScreen({super.key});

  @override
  _ChangeNomPrenomScreenState createState() => _ChangeNomPrenomScreenState();
}

class _ChangeNomPrenomScreenState extends State<ChangeNomPrenomScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final ProfilService _ProfilService = ProfilService();
  String? storedFirstname;
  String? storedName; // Récupère le prénom depuis les prefs

  void _chargeInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedFirstname = prefs.getString('firstname');
      storedName =
          prefs.getString('name'); // Récupère le prénom depuis les prefs
    });
  }

  @override
  Widget build(BuildContext context) {
    _chargeInfo();
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Modifier le nom d'utilisateur",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: cloudColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    /*
                    child:  Text(
                      "Nom et Prenom : $storedName $storedFirstname",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                     */
                    child: Text(
                      "Nom d'utilisateur: $storedName ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        hintText: 'Entrer le nouveau nom',
                        hintStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateName();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _updateName() async {
    try {
      // final response = await _ProfilService.updateName(_nomController.text, _prenomController.text);
      final response = await _ProfilService.updateName(_nomController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nom d'utilisateur mis à jour avec succès"),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du nom et prénom: $e'),
        ),
      );
    }
  }
}

class ChangeNumberScreen extends StatefulWidget {
  const ChangeNumberScreen({super.key});

  @override
  _ChangeNumberScreenState createState() => _ChangeNumberScreenState();
}

class _ChangeNumberScreenState extends State<ChangeNumberScreen> {
  final TextEditingController phoneController = TextEditingController();
  final ProfilService _ProfilService = ProfilService();
  // Récupère le prénom depuis les prefs
  String? storedNumero; // Récupère le prénom depuis les prefs

  void _chargeInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedNumero =
          prefs.getString('numero'); // Récupère le prénom depuis les prefs
    });
  }

  @override
  Widget build(BuildContext context) {
    _chargeInfo();
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Modifier le numero",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: cloudColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      "Numéro: $storedNumero",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        hintText: 'Entrer le nouveau numero',
                        hintStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateNumber();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _updateNumber() async {
    try {
      final response = await _ProfilService.updateNumber(phoneController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone mis à jour avec succès'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur lors de la mise à jour du numéro de téléphone: $e'),
        ),
      );
    }
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ProfilService _ProfilService = ProfilService();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Modifier le mot de passe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: cloudColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      "Mot de passe: *********",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: oldPasswordController,
                    hintText: "Entrer l'ancien mot de passe",
                    obscureText: _obscureOldPassword,
                    onTap: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: newPasswordController,
                    hintText: 'Entrer le nouveau mot de passe',
                    obscureText: _obscureNewPassword,
                    onTap: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    hintText: 'Confirmer le nouveau mot de passe',
                    obscureText: _obscureConfirmPassword,
                    onTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {
                        _validateAndSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onTap,
          ),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  void _validateAndSubmit() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      // Afficher un message d'erreur si les mots de passe ne correspondent pas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
        ),
      );
      return;
    }

    try {
      final response = await _ProfilService.updatePassword(
          oldPasswordController.text, newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du mot de passe: $e'),
        ),
      );
    }
  }
}

class ChangePhotoScreen extends StatefulWidget {
  final File? image;

  const ChangePhotoScreen({super.key, this.image});

  @override
  _ChangePhotoScreenState createState() => _ChangePhotoScreenState();
}

class _ChangePhotoScreenState extends State<ChangePhotoScreen> {
  File? _image;
  final ProfilService _ProfilService = ProfilService();

  @override
  void initState() {
    super.initState();
    _image = widget.image;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveImage() async {
    if (_image != null) {
      try {
        final response = await _ProfilService.updateProfileImage(_image!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImagePath', _image!.path);
        await prefs.setString('localProfileImagePath', _image!.path); // Enregistrer le chemin local
        profileImageNotifier.value = _image;
        Navigator.of(context).pop(_image);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Erreur lors de la mise à jour de la photo de profil: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double profileImageSize = MediaQuery.of(context).size.width / 2;
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Profil"),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Stack(
                  children: [
                    Center(
                      child: CircleAvatar(
                        backgroundColor: whiteColor,
                        radius: 100,
                        backgroundImage:
                        _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? Icon(
                          Icons.account_circle,
                          color: blackColor,
                          size: profileImageSize,
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: blueColor,
                    backgroundColor: whiteColor,
                    side: const BorderSide(color: blueColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Choisir une photo de profil'),
                ).box.width(500).make(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Enregistrer'),
                ).box.width(500).make(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
