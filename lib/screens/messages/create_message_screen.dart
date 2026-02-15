// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../services/message_service.dart';
import 'message_preview_screen.dart';

class CreateMessageScreen extends StatefulWidget {
  final String category;
  final int? categoryId;

  const CreateMessageScreen({
    super.key,
    required this.category,
    this.categoryId,
  });

  @override
  State<CreateMessageScreen> createState() => _CreateMessageScreenState();
}

class _CreateMessageScreenState extends State<CreateMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final PageController _pageController = PageController();
  final MessageService _messageService = MessageService();
  int _currentStep = 0; // 0: choix fond, 1: écrire message, 2: aperçu
  int _selectedBackgroundIndex = 0;
  int? _categoryId;
  bool _isLoadingCategory = true;

  // Liste des arrière-plans disponibles
  final List<String> _backgrounds = [
    'assets/images/s1.jpg',
    'assets/images/s2.jpg',
    'assets/images/s3.png',
    'assets/images/s4.png',
    'assets/images/s5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategoryId();
  }

  Future<void> _loadCategoryId() async {
    if (widget.categoryId != null) {
      setState(() {
        _categoryId = widget.categoryId;
        _isLoadingCategory = false;
      });
      return;
    }

    try {
      final categories = await _messageService.getCategories();
      final matchingCategory = categories.firstWhere(
        (cat) => cat.name.toLowerCase() == widget.category.toLowerCase() ||
                 cat.name == widget.category,
        orElse: () => categories.first,
      );
      if (mounted) {
        setState(() {
          _categoryId = matchingCategory.id;
          _isLoadingCategory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategory = false;
        });
      }
    }
  }

  // Messages suggérés par catégorie
  Map<String, List<String>> get _suggestedMessages => {
    'Anniversaire': [
      'Joyeux anniversaire ! Que cette journée soit remplie de joie et de bonheur.',
      'Un an de plus, une année de sagesse en plus ! Bonne fête !',
      'Que tous tes vœux se réalisent en cette journée spéciale !',
    ],
    'Mariage': [
      'Félicitations pour votre union ! Que votre amour grandisse chaque jour.',
      'Tous nos vœux de bonheur pour cette nouvelle vie à deux !',
      'Que votre mariage soit le début d\'une belle aventure !',
    ],
    'Voeux': [
      'Je te souhaite tout le bonheur du monde !',
      'Que la réussite accompagne chacun de tes pas.',
      'Mes meilleurs vœux pour toi et tes proches.',
    ],
    'Nouvel an': [
      'Bonne année ! Que 2025 soit remplie de succès et de bonheur.',
      'Nouvelle année, nouvelles opportunités ! Meilleurs vœux !',
      'Que cette nouvelle année t\'apporte tout ce que tu désires.',
    ],
    'Noël': [
      'Joyeux Noël ! Que la magie des fêtes illumine ton cœur.',
      'Paix, amour et joie en cette période de Noël.',
      'Que le Père Noël exauce tous tes souhaits !',
    ],
  };

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _generateMessage() {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez écrire un message')),
      );
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: catégorie non trouvée. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final messageData = {
      'category': widget.category,
      'categoryId': _categoryId,
      'titre': widget.category,
      'background': _backgrounds[_selectedBackgroundIndex],
      'backgroundIndex': _selectedBackgroundIndex,
      'message': _messageController.text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Naviguer vers l'écran de prévisualisation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePreviewScreen(messageData: messageData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: whiteColor,
        child: Column(
          children: [
            // Header bleu
            _buildHeader(),
            // Indicateur de progression
            _buildProgressIndicator(),
            // Contenu
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBackgroundSelection(),
                  _buildMessageInput(),
                  _buildPreview(),
                ],
              ),
            ),
            // Boutons navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(authBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: whiteColor),
                  onPressed: _previousStep,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Créer un message - ${widget.category}',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Fond'),
          Expanded(child: _buildStepLine(0)),
          _buildStepIndicator(1, 'Message'),
          Expanded(child: _buildStepLine(1)),
          _buildStepIndicator(2, 'Aperçu'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? blueColor : greyColor.withOpacity(0.3),
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? Icon(Icons.check, color: whiteColor, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? whiteColor : greyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? blueColor : greyColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 3,
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? blueColor : greyColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBackgroundSelection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez un arrière-plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sélectionnez l\'image de fond pour votre message',
            style: TextStyle(fontSize: 14, color: greyColor),
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _backgrounds.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedBackgroundIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBackgroundIndex = index;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? blueColor : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _backgrounds[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: greyColor.withOpacity(0.2),
                            child: Icon(Icons.image, color: greyColor, size: 40),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color: blueColor.withOpacity(0.3),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: blueColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, color: whiteColor, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final suggestions = _suggestedMessages[widget.category] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Écrivez votre message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Personnalisez le texte de votre message',
            style: TextStyle(fontSize: 14, color: greyColor),
          ),
          SizedBox(height: 20),
          // Zone de texte
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Tapez votre message ici...',
              hintStyle: TextStyle(color: greyColor, fontSize: 14),
              filled: true,
              fillColor: greyColor.withValues(alpha: 0.1),
              contentPadding: EdgeInsets.all(16),
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
          // Suggestions
          if (suggestions.isNotEmpty) ...[
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: blackColor,
              ),
            ),
            SizedBox(height: 12),
            ...suggestions.map((suggestion) => _buildSuggestionChip(suggestion)),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text = suggestion;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: roscColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: roscColor),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: blueColor, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(fontSize: 13, color: blackColor),
              ),
            ),
            Icon(Icons.add_circle_outline, color: blueColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu de votre message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blackColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vérifiez avant de générer',
            style: TextStyle(fontSize: 14, color: greyColor),
          ),
          SizedBox(height: 20),
          // Aperçu du message
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond
                  Image.asset(
                    _backgrounds[_selectedBackgroundIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: blueColor.withOpacity(0.3),
                    ),
                  ),
                  // Juste le gift au centre
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset(
                        'assets/images/chapt.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.card_giftcard,
                          size: 150,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: blueColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _currentStep == 0 ? 'Annuler' : 'Précédent',
                style: TextStyle(color: blueColor, fontSize: 16),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Bouton Suivant / Générer
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _generateMessage : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Générer' : 'Suivant',
                style: TextStyle(color: whiteColor, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
