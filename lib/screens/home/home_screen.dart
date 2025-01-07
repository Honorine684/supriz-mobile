import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/screens/notifications/notifications_screen.dart';
import '../../models/publicite.dart';
import '../historique/historique_screen.dart';
import '../produits/supriz.dart';
import '../profil/profil_screen.dart';
import '../../services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/publicite_service.dart'; // Import du service de publicité

class HomeScreen extends StatefulWidget {
  final Function(int, String) onCategorySelected;

  const HomeScreen({super.key, required this.onCategorySelected});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Invité';
  File? _profileImage;
  late Future<List<Publicite>> _publicitesFuture;
  late PubliciteService _publiciteService;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _publiciteService = PubliciteService();
    _publicitesFuture = _publiciteService.fetchPublicites();
    _loadUserName();
    profileImageNotifier.addListener(_updateProfileImage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
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

  Future<void> _loadUserName() async {
    final userName = await AuthService().getUserName();
    setState(() {
      _userName = userName;
    });
  }

  final List<Map<String, dynamic>> gridItems = [
    {
      "title": "Hommes",
      "image": produit1,
      "index": 0,
      "subCategory": "T-shirts"
    },
    {"title": "Femmes", "image": produit2, "index": 1, "subCategory": "Robes"},
    {
      "title": "Enfants",
      "image": produit3,
      "index": 2,
      "subCategory": "T-shirts"
    },
    {"title": "Supriz", "image": produit4, "index": 3},
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Bienvenue ${_userName.isNotEmpty ? _userName[0].toUpperCase() + _userName.substring(1) : ''}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<Publicite>>(
                  future: _publicitesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: blueColor,
                      );
                    } else if (snapshot.hasError) {
                      return const Text("Erreur de chargement des publicités");
                    } else {
                      return ImageSwiper(
                          publicites: snapshot.data!,
                          onCategorySelected: widget.onCategorySelected);
                    }
                  },
                ),
                const SizedBox(height: 15),
                ProductHeader(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HistoriquesScreen()),
                  );
                }),
                const SizedBox(height: 5),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: gridItems.length,
                itemBuilder: (context, index) {
                  final item = gridItems[index];
                  return GridItem(
                    item: item,
                    onTap: () {
                      if (item['index'] == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SurprizScreen()),
                        );
                      } else {
                        widget.onCategorySelected(
                            item['index'], item['subCategory'] ?? "");
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: whiteColor,
      surfaceTintColor: whiteColor,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset(logo, height: 28),
          const SizedBox(width: 10),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()),
            );
          },
        ),
        IconButton(
          icon: ValueListenableBuilder<File?>(
            valueListenable: profileImageNotifier,
            builder: (context, image, child) {
              return CircleAvatar(
                radius: 14,
                backgroundColor: whiteColor,
                backgroundImage: image != null ? FileImage(image) : null,
                child: image == null
                    ? Icon(
                  Icons.account_circle,
                  color: blackColor,
                  size: 28,
                )
                    : null,
              );
            },
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilScreen()),
            );
          },
        ),
      ],
    );
  }
}

class ImageSwiper extends StatelessWidget {
  final List<Publicite> publicites;
  final Function(int, String) onCategorySelected;

  const ImageSwiper(
      {super.key, required this.publicites, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Swiper(
      layout: SwiperLayout.TINDER,
      itemHeight: 220.0,
      itemWidth: double.infinity,
      itemCount: publicites.length,
      autoplay: true,
      autoplayDisableOnInteraction: true,
      autoplayDelay: 5000,
      loop: true,
      onIndexChanged: (index) {},
      itemBuilder: (BuildContext context, int index) {
        final publicite = publicites[index];
        return GestureDetector(
          onTap: () {
            onCategorySelected(
                publicite.typeCategorieId ?? 0, publicite.nameSousCategories ?? "");
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: publicite.pathImage,
                height: MediaQuery.of(context).size.height * 0.25,
                fit: BoxFit.fill,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        );
      },
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }
}

class ProductHeader extends StatelessWidget {
  final VoidCallback onPressed;

  const ProductHeader({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Produits",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: roscColor,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.history, size: 18, color: Colors.black),
          label: const Text(
            "Historiques",
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class GridItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const GridItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item['image'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              item['title'],
              style: const TextStyle(color: whiteColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
