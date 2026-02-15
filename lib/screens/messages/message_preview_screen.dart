// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../services/message_service.dart';
import 'message_result_screen.dart';

class MessagePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> messageData;

  const MessagePreviewScreen({super.key, required this.messageData});

  @override
  State<MessagePreviewScreen> createState() => _MessagePreviewScreenState();
}

class _MessagePreviewScreenState extends State<MessagePreviewScreen> {
  int _selectedBackgroundIndex = 0;
  bool _isBackgroundExpanded = true;
  bool _isLoading = false;
  final MessageService _messageService = MessageService();

  // Liste des arrière-plans disponibles
  final List<String> _backgrounds = [
    'assets/images/s1.jpg',
    'assets/images/s2.jpg',
    'assets/images/s3.png',
    'assets/images/s4.png',
    'assets/images/s5.jpg',
  ];

  String get _category => widget.messageData['category'] ?? '';
  int? get _categoryId => widget.messageData['categoryId'];
  String get _message => widget.messageData['message'] ?? '';
  String get _titre => widget.messageData['titre'] ?? _category;

  @override
  void initState() {
    super.initState();
    // Récupérer l'index du background s'il est passé
    final bgIndex = widget.messageData['backgroundIndex'];
    if (bgIndex != null && bgIndex is int && bgIndex < _backgrounds.length) {
      _selectedBackgroundIndex = bgIndex;
    }
  }

  Future<void> _onGenerate() async {
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: catégorie non trouvée'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _messageService.createMessage(
        titre: _titre,
        contenu: _message,
        sousCategorieId: _categoryId!,
        backgroundPath: _backgrounds[_selectedBackgroundIndex],
        expiration: '24h',
      );

      if (!mounted) return;

      // Naviguer vers l'écran de résultat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MessageResultScreen(
            messageData: {
              'id': result['id'],
              'slug': result['slug'],
              'title': _titre,
              'message': _message,
              'expiration': '24h',
            },
            selectedBackgroundIndex: _selectedBackgroundIndex,
            backgrounds: _backgrounds,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blueColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Contenu principal
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Aperçu du message
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildPreviewCard(),
                            SizedBox(height: 20),
                            _buildBackgroundSelector(),
                          ],
                        ),
                      ),
                    ),
                    // Boutons en bas
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Indicateur de drag
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: whiteColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(height: 16),
          // Titre de la catégorie
          Text(
            _category,
            style: TextStyle(
              color: whiteColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [blueColor.withOpacity(0.8), blueColor],
                  ),
                ),
              ),
            ),
            // Contenu du message
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gift icon
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/images/chapt.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.card_giftcard,
                          size: 100,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Message text
                    if (_message.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: whiteColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: blackColor,
                            height: 1.5,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isBackgroundExpanded = !_isBackgroundExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arrière plan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sélectionnez un arrière plan pour donner plus vie à votre message.',
                          style: TextStyle(
                            fontSize: 12,
                            color: greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isBackgroundExpanded ? 0 : 0.5,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: blackColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBackgroundExpanded) ...[
            Container(
              height: 90,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _backgrounds.length,
                itemBuilder: (context, index) => _buildBackgroundItem(index),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackgroundItem(int index) {
    final isSelected = _selectedBackgroundIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBackgroundIndex = index;
        });
      },
      child: Container(
        width: 70,
        height: 70,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? blueColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backgrounds[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: greyColor.withOpacity(0.3),
                  child: Icon(Icons.image, color: greyColor, size: 24),
                ),
              ),
              if (isSelected)
                Container(
                  color: blueColor.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: blueColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: whiteColor, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
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
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: blueColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Précédent',
                style: TextStyle(
                  color: blueColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Bouton Générer
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: whiteColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Générer',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
