import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/widgets/appbar_custom.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _showingDialog = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _saveProfileImage(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imagePath);
    profileImageNotifier.value = File(imagePath);
  }

  void _showConfirmationDialog(BuildContext context, String message, Function onConfirm) {
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
        /*
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChangePhotoScreen(image: _profileImage)),
        );
        if (result != null && result is File) {
          setState(() {
            _profileImage = result;
          });
          _saveProfileImage(result.path);
        }
         */
      },
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Modifier le nom et le prenom",
          () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ChangeNomPrenomScreen()),
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
                      child: CircleAvatar(
                        radius: profileImageSize / 2,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage(profilImag) as ImageProvider<Object>,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: (MediaQuery.of(context).size.width - profileImageSize) / 2 - 15,
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
                const Text(
                  "John Doe",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing),
                _buildInfoRow(context, "Nom et Prenom", "John Doe", _showEditUsernameDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, 'Numéro', "**********", _showEditNumberDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, 'Email', "john.doe@gmail.com", _showEditEmailDialog),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, 'Mot de passe', '********', _showEditPasswordDialog),
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

  Widget _buildInfoRow(BuildContext context, String label, String value, Function(BuildContext) onTap) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        flexibleSpace: Image.asset(
          appbarImg,
          fit: BoxFit.cover,
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          color: whiteColor,
          icon: const Icon(
            Icons.arrow_back,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                    child: const Text(
                      "Email: changeme@changeme.com",
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}

class ChangeNomPrenomScreen extends StatefulWidget {
  const ChangeNomPrenomScreen({super.key});

  @override
  _ChangeNomPrenomScreenState createState() => _ChangeNomPrenomScreenState();
}

class _ChangeNomPrenomScreenState extends State<ChangeNomPrenomScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        flexibleSpace: Image.asset(appbarImg, fit: BoxFit.cover,),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          color: whiteColor,
          icon: const Icon(Icons.arrow_back, size: 28,),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child:
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Modifier le nom et le prénom",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: cloudColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      "Nom et Prenom : John Doe",
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        hintText: 'Entrer le nouveau prénom',
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
                      onPressed: (){

                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}

class ChangeNumberScreen extends StatefulWidget {
  const ChangeNumberScreen({super.key});

  @override
  _ChangeNumberScreenState createState() => _ChangeNumberScreenState();
}

class _ChangeNumberScreenState extends State<ChangeNumberScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        flexibleSpace: Image.asset(
          appbarImg,
          fit: BoxFit.cover,
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          color: whiteColor,
          icon: const Icon(
            Icons.arrow_back,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                    child: const Text(
                      "Numéro: +33123456789",
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
                  Container(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        flexibleSpace: Image.asset(
          appbarImg,
          fit: BoxFit.cover,
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          color: whiteColor,
          icon: const Icon(
            Icons.arrow_back,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                  Container(
                    width: 500,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              obscureText ? Icons.visibility_off : Icons.visibility ,
              color: Colors.grey,
            ),
            onPressed: onTap,
          ),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  void _validateAndSubmit() {
    if (newPasswordController.text != confirmPasswordController.text) {
      // Afficher un message d'erreur si les mots de passe ne correspondent pas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
        ),
      );
      return;
    }

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe modifié avec succès'),
      ),
    );
  }
}

/*
class ChangePhotoScreen extends StatefulWidget {
  final File? image;

  const ChangePhotoScreen({super.key, this.image});

  @override
  _ChangePhotoScreenState createState() => _ChangePhotoScreenState();
}

class _ChangePhotoScreenState extends State<ChangePhotoScreen> {
  File? _image;

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', _image!.path);
      profileImageNotifier.value = _image;
      Navigator.of(context).pop(_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        flexibleSpace: Image.asset(appbarImg, fit: BoxFit.cover,),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          color: whiteColor,
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                        radius: 100,
                        backgroundImage: _image != null ? FileImage(_image!) : const AssetImage(profilImag) as ImageProvider,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 500,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: blueColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: blueColor,
                    backgroundColor: whiteColor,
                    side: const BorderSide(color: blueColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Choisir une photo de profil'),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 500,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: blueColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

 */
