// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:supriz/screens/notifications/notifications_screen.dart';
import '../../consts/colors.dart';
import '../../consts/images.dart';
import '../../models/publicite.dart';
import '../produits/supriz.dart';
import '../profil/profil_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int, String) onCategorySelected;

  HomeScreen({super.key, required this.onCategorySelected});

  final List<String> imageUrls = [
    crsImg1,
    crsImg2,
    crsImg3,
    crsImg4,
  ];

  final List<Publicite> publicites = [
    Publicite(
        id: 1, pathImage: crsImg1, sousCategorie: 0, categorie: "Pantalons"),
    Publicite(id: 2, pathImage: crsImg2, sousCategorie: 1, categorie: "Jupes"),
    Publicite(id: 3, pathImage: crsImg3, sousCategorie: 2, categorie: "Robes"),
    Publicite(id: 4, pathImage: crsImg4, sousCategorie: 0, categorie: "Vestes"),
  ];

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
    // Verrouille l'orientation en mode portrait
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
                const Text(
                  "Bienvenue John Doe",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildImageSwiper(),
                const SizedBox(height: 15),
                _buildProductHeader(context),
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
                  return GestureDetector(
                    onTap: () {
                      if (item['index'] == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SurprizScreen()),
                        );
                      } else {
                        onCategorySelected(
                            item['index'], item['subCategory'] ?? "");
                      }
                    },
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
                            style: const TextStyle(
                                color: whiteColor, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
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
          Image.asset(
            logo,
            height: 28,
          ),
          const SizedBox(width: 10),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: whiteColor,
              radius: 15,
              child: Icon(
                Icons.account_circle,
                color: blackColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSwiper() {
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
                publicite.sousCategorie ?? 0, publicite.categorie ?? "");
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                publicite.pathImage,
                height: MediaQuery.of(context).size.height * 0.25,
                fit: BoxFit.fill,
              ),
            ),
          ),
        );
      },
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  Widget _buildProductHeader(BuildContext context) {
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
          onPressed: () {},
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
