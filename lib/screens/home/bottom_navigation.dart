// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../consts/consts.dart';
import '../assistance/assistance_screen.dart';
import '../panier/cart_controller.dart'; // Assurez-vous d'importer le bon fichier
import '../panier/panier_screen.dart';
import '../parametres/parametres_screen.dart';
import '../produits/produits_screen.dart';
import 'home_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;
  String _selectedSubCategory = "T-shirts";
  DateTime? _lastPressedAt; // Variable pour enregistrer le moment du premier appui

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomeScreen(onCategorySelected: _onCategorySelected),
      ProduitScreen(initialCategoryIndex: _selectedCategoryIndex, initialSubCategory: _selectedSubCategory),
      PanierScreen(),
      ParametresScreen(),
      AssistanceScreen(),
    ]);
  }

  void _onCategorySelected(int categoryIndex, String subCategory) {
    setState(() {
      _selectedCategoryIndex = categoryIndex;
      _selectedSubCategory = subCategory;
      _currentIndex = 1;
      _pages[1] = ProduitScreen(initialCategoryIndex: _selectedCategoryIndex, initialSubCategory: _selectedSubCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cartController = Get.find<CartController>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _pages[_currentIndex],
        bottomNavigationBar: _buildBottomNavigationBar(screenHeight),
        floatingActionButton: Obx(() {
          final cartItemCount = cartController.distinctProductCount;
          return _buildFloatingActionButton(cartItemCount);
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_lastPressedAt == null || DateTime.now().difference(_lastPressedAt!) > Duration(seconds: 2)) {
      // Premier appui ou délai dépassé
      _lastPressedAt = DateTime.now();
      return false; // Empêche la fermeture de l'application
    }
    return true; // Permet la fermeture de l'application
  }

  // Barre de navigation inférieure
  Widget _buildBottomNavigationBar(double screenHeight) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: const EdgeInsets.only(left: 20.0, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 30)],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  iconPath: 'assets/icons/acceuil.svg',
                  label: "Accueil",
                  index: 0,
                  screenHeight: screenHeight,
                ),
                _buildNavItem(
                  iconPath: 'assets/icons/produits.svg',
                  label: "Produits",
                  index: 1,
                  screenHeight: screenHeight,
                ),
              ],
            ),
          ),
          const SizedBox(width: 50),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  iconPath: 'assets/icons/parametres.svg',
                  label: "Paramètres",
                  index: 3,
                  screenHeight: screenHeight,
                ),
                _buildNavItem(
                  icon: Icons.support_agent_outlined,
                  label: "Assistance",
                  index: 4,
                  screenHeight: screenHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bouton flottant pour le panier
  Widget _buildFloatingActionButton(int cartItemCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          shape: CircleBorder(),
          onPressed: () {
            setState(() {
              _currentIndex = 2;
            });
          },
          backgroundColor: _currentIndex == 2 ? blueColor : roscColor,
          child: SvgPicture.asset(
            'assets/icons/panier.svg',
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              _currentIndex == 2 ? Colors.white : Colors.black,
              BlendMode.srcIn,
            ),
          ),
        ),
        if (cartItemCount > 0)
          Positioned(
            right: 7,
            top: 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? roscColor : blueColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$cartItemCount',
                  style: TextStyle(
                    color: _currentIndex == 2 ? blackColor : whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Élément de la barre de navigation
  Widget _buildNavItem({
    String? iconPath,
    IconData? icon,
    required String label,
    required int index,
    required double screenHeight,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index; // Met à jour l'index actif
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            SvgPicture.asset(
              iconPath,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                isActive ? blueColor : Colors.black45,
                BlendMode.srcIn,
              ),
            ),
          if (icon != null)
            Icon(
              icon,
              color: isActive ? blueColor : Colors.black45,
              size: 30,
            ),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: screenHeight * 0.015,
                color: isActive ? blueColor : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
