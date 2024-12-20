import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts/colors.dart';
import '../../consts/images.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    // Naviguer vers l'écran de registre
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildOnboardingPage(
                onb1,
                "Bienvenue sur Supriz !",
                "L’application idéale pour trouver le cadeau parfait pour vos proches à chaque occasion. Plus besoin de passer des heures à chercher, nous sommes là pour vous aider à faire plaisir en un clin d'œil.",
              ),
              _buildOnboardingPage(
                onb2,
                "Trouver un cadeau n'a jamais été aussi facile !",
                "Découvrez une sélection de cadeaux personnalisables et non personnalisables pour toutes les occasions. Vous avez accès à une vaste gamme de cadeaux adaptés à chaque évènement",
              ),
              _buildOnboardingPage(
                onb3,
                "On se charge de la livraison !",
                "Supriz garantit une livraison rapide et fiable, directement à vous ou à votre destinataire.",
              ),
            ],
          ),
          if (_currentPage > 0)
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: blackColor),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        color: whiteColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _currentPage != 2
                  ? TextButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(
                        color: blackColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: blackColor,
                      size: 16,
                    ),
                  ],
                ),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _completeOnboarding,
                child: const Text(
                  'Terminer',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(
      String imagePath,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 220,
            width: 290,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: grayColor,
            ),
          ),
        ],
      ),
    );
  }
}
