// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../consts/consts.dart';
import '../../services/message_service.dart';
import '../assistance/assistance_screen.dart';
import '../historique/historique_screen.dart';
import '../messages/create_message_flow.dart';
import '../messages/message_result_screen.dart';
import '../parametres/parametres_screen.dart';
import 'home_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  // Clé globale pour accéder au HomeScreenState
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // Catégories d'événements chargées depuis le backend
  List<SuprizCategory> _categories = [];
  bool _isLoadingCategories = false;
  final MessageService _messageService = MessageService();

  // Icônes par défaut pour les catégories (fallback si pas d'icône du backend)
  final Map<String, IconData> _defaultCategoryIcons = {
    'Anniversaire': Icons.cake,
    'Mariage': Icons.favorite,
    'Voeux': Icons.card_giftcard,
    'Vœux': Icons.card_giftcard,
    'Nouvel an': Icons.celebration,
    'Noël': Icons.ac_unit,
  };

  // Pages créées en lazy pour éviter les problèmes de callback
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _pages = [
      HomeScreen(
        key: _homeScreenKey,
        onCreateMessagePressed: () => _showCategoriesBottomSheet(),
        onViewAllPressed: () => _goToHistorique(),
      ),
      HistoriquesScreen(),
      Container(), // Placeholder pour le bouton +
      ParametresScreen(),
      AssistanceScreen(),
    ];
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await _messageService.getCategories();
      // Debug: afficher les catégories reçues
      for (var cat in categories) {
        print('Category: ${cat.name}, icone: ${cat.icone}');
      }
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // Méthode pour rafraîchir la page d'accueil
  void refreshHomeScreen() {
    _homeScreenKey.currentState?.refreshMessages();
  }

  void _goToHistorique() {
    setState(() {
      _currentIndex = 1; // Index de l'historique
    });
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de drag
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            // Titre
            Text(
              "Créer un message",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Choisissez une catégorie",
              style: TextStyle(
                fontSize: 14,
                color: greyColor,
              ),
            ),
            SizedBox(height: 16),
            // Grille de catégories
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _isLoadingCategories
                  ? _buildCategoriesSkeleton()
                  : _categories.isEmpty
                      ? Text(
                          "Aucune catégorie disponible",
                          style: TextStyle(color: greyColor),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
                        ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(SuprizCategory category) {
    // Icône par défaut basée sur le nom de la catégorie
    final defaultIcon = _defaultCategoryIcons[category.name] ?? Icons.category;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // Naviguer vers le flux de création de message
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateMessageFlow(
              category: category.name,
              categoryId: category.id,
              placeholderTexte: category.placeholderTexte,
              giftImage: category.giftImage,
              onMessageCreated: refreshHomeScreen,
            ),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 24,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: blueColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: blueColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône depuis le backend ou icône par défaut
            if (category.icone != null && category.icone!.isNotEmpty)
              Image.network(
                category.icone!,
                width: 32,
                height: 32,
                color: blueColor,
                errorBuilder: (context, error, stackTrace) => Icon(
                  defaultIcon,
                  color: blueColor,
                  size: 32,
                ),
              )
            else
              Icon(defaultIcon, color: blueColor, size: 32),
            SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: blueColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSkeleton() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        6,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: MediaQuery.of(context).size.width / 3 - 24,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex == 2 ? 0 : _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void _handleBackPress() {
    if (_lastPressedAt == null ||
        DateTime.now().difference(_lastPressedAt!) > Duration(seconds: 2)) {
      _lastPressedAt = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appuyez à nouveau pour quitter"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      margin: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Groupe gauche
          _buildNavItem(
            iconPath: 'assets/icons/acceuil.svg',
            label: "Accueil",
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.history,
            label: "Historique",
            index: 1,
          ),
          // Espace pour le FAB
          SizedBox(width: 50),
          // Groupe droite
          _buildNavItem(
            iconPath: 'assets/icons/parametres.svg',
            label: "Paramètres",
            index: 3,
          ),
          _buildNavItem(
            icon: Icons.support_agent,
            label: "Assistance",
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: blueColor,
        boxShadow: [
          BoxShadow(
            color: blueColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: _showCategoriesBottomSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: whiteColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    String? iconPath,
    IconData? icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  isActive ? blueColor : greyColor,
                  BlendMode.srcIn,
                ),
              ),
            if (icon != null)
              Icon(
                icon,
                color: isActive ? blueColor : greyColor,
                size: 26,
              ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
                color: isActive ? blueColor : greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour le formulaire de création de message - Style moderne
class CreateMessageBottomSheet extends StatefulWidget {
  final String category;
  final ScrollController scrollController;
  final VoidCallback? onMessageCreated;

  const CreateMessageBottomSheet({
    super.key,
    required this.category,
    required this.scrollController,
    this.onMessageCreated,
  });

  @override
  State<CreateMessageBottomSheet> createState() => _CreateMessageBottomSheetState();
}

class _CreateMessageBottomSheetState extends State<CreateMessageBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedExpiration = '24h'; // 24h ou 48h
  String? _selectedMusic;
  int? _selectedMusicIndex;
  final List<File?> _selectedImages = [null, null, null]; // 3 slots d'images
  bool _isMusicExpanded = false;
  int? _playingMusicIndex;

  // Liste des musiques avec leurs infos
  final List<Map<String, String>> _musicOptions = [
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
    {'title': 'Joyeuse anniversaire', 'artist': 'SIDIKI DIABATE'},
  ];

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // Ouvrir le crop modal comme Cropper.js sur le web
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          maxWidth: 800,
          maxHeight: 800,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer l\'image',
              toolbarColor: Color(0xFF005792),
              toolbarWidgetColor: Colors.white,
              statusBarColor: Color(0xFF004472),
              backgroundColor: Colors.white,
              activeControlsWidgetColor: Color(0xFF005792),
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
              showCropGrid: true,
              hideBottomControls: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            IOSUiSettings(
              title: 'Recadrer l\'image',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _selectedImages[index] = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages[index] = null;
    });
  }

  void _togglePlayMusic(int index) {
    setState(() {
      if (_playingMusicIndex == index) {
        _playingMusicIndex = null; // Stop playing
      } else {
        _playingMusicIndex = index; // Start playing this one
      }
    });
  }

  void _selectMusic(int index) {
    setState(() {
      if (_selectedMusicIndex == index) {
        // Désélectionner si déjà sélectionné
        _selectedMusic = null;
        _selectedMusicIndex = null;
      } else {
        _selectedMusic = '${_musicOptions[index]['title']} - ${_musicOptions[index]['artist']}';
        _selectedMusicIndex = index;
      }
    });
  }

  void _improveMessageWithAI() {
    // TODO: Implémenter l'amélioration du message par IA
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Amélioration du message par IA...'),
        backgroundColor: blueColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setExpiration(String value) {
    setState(() {
      _selectedExpiration = value;
    });
  }

  void _onSubmit() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: blueColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final messageData = {
      'category': widget.category,
      'title': _titleController.text,
      'message': _messageController.text,
      'images': _selectedImages.where((img) => img != null).map((img) => img!.path).toList(),
      'expiration': _selectedExpiration,
      'music': _selectedMusic,
    };

    Navigator.pop(context);
    // Afficher la prévisualisation en bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => MessagePreviewBottomSheet(
          messageData: messageData,
          scrollController: scrollController,
          onMessageCreated: widget.onMessageCreated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Champ Titre
                  _buildLabel('Titre du message *'),
                  SizedBox(height: 10),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Ex: Joyeux anniversaire John Doe',
                    maxLines: 1,
                  ),
                  SizedBox(height: 24),

                  // Champ Message avec baguette magique IA
                  _buildLabel('Message'),
                  SizedBox(height: 10),
                  _buildMessageFieldWithAI(),
                  SizedBox(height: 24),

                  // Section Images - 3 zones
                  _buildLabel('Image'),
                  SizedBox(height: 10),
                  _buildImageSection(),
                  SizedBox(height: 24),

                  // Date d'expiration
                  _buildExpirationDate(),
                  SizedBox(height: 24),

                  // Sélection de musique
                  _buildMusicSelector(),
                  SizedBox(height: 32),

                  // Bouton Suivant
                  _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 12),
        // Indicateur de drag moderne
        Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(height: 20),
        // Header bleu avec titre
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: blueColor,
          ),
          child: Text(
            widget.category,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: whiteColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: blackColor,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        color: blackColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: greyColor,
          fontSize: 15,
        ),
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
    );
  }

  Widget _buildImageSection() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Color(0xFFCCCCCC),
        strokeWidth: 1.5,
        gap: 6,
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 3 zones d'images
            Row(
              children: List.generate(3, (index) => _buildImageSlot(index)),
            ),
            SizedBox(height: 12),
            Text(
              'Max 10 MB par image',
              style: TextStyle(
                fontSize: 12,
                color: greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    final hasImage = _selectedImages[index] != null;

    return Expanded(
      child: GestureDetector(
        onTap: () => hasImage ? _removeImage(index) : _pickImage(index),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          height: 100,
          decoration: BoxDecoration(
            color: hasImage ? Color(0xFFF0F0F0) : Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage ? blueColor : Color(0xFFE0E0E0),
              width: hasImage ? 2 : 1,
            ),
          ),
          child: hasImage
              ? Stack(
                  children: [
                    // Afficher la vraie image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index]!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Bouton de suppression
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFFAAAAAA),
                      size: 28,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Photo ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMessageFieldWithAI() {
    return Stack(
      children: [
        TextField(
          controller: _messageController,
          maxLines: 5,
          style: TextStyle(
            fontSize: 15,
            color: blackColor,
          ),
          decoration: InputDecoration(
            hintText: 'Écrivez votre message ici...',
            hintStyle: TextStyle(
              color: greyColor,
              fontSize: 15,
            ),
            filled: true,
            fillColor: greyColor.withValues(alpha: 0.1),
            contentPadding: EdgeInsets.fromLTRB(16, 16, 50, 16),
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
        // Baguette magique IA
        Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: _improveMessageWithAI,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_fix_high,
                  color: whiteColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationDate() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cloudColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Expire dans',
            style: TextStyle(
              fontSize: 14,
              color: blackColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12),
          // Bouton 24h
          GestureDetector(
            onTap: () => _setExpiration('24h'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedExpiration == '24h' ? blueColor : whiteColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedExpiration == '24h' ? blueColor : Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                '24h',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedExpiration == '24h' ? whiteColor : blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Bouton 48h
          GestureDetector(
            onTap: () => _setExpiration('48h'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedExpiration == '48h' ? blueColor : whiteColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedExpiration == '48h' ? blueColor : Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                '48h',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedExpiration == '48h' ? whiteColor : blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: whiteColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule, color: blueColor, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cliquable
          GestureDetector(
            onTap: () {
              setState(() {
                _isMusicExpanded = !_isMusicExpanded;
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
                          'Musiques',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Sélectionnez une musique pour amplifier l'émotion a fais passé.",
                          style: TextStyle(
                            fontSize: 12,
                            color: greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isMusicExpanded ? 0 : 0.5,
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
          // Liste des musiques
          if (_isMusicExpanded) ...[
            ...List.generate(_musicOptions.length, (index) => _buildMusicItem(index)),
          ],
        ],
      ),
    );
  }

  Widget _buildMusicItem(int index) {
    final music = _musicOptions[index];
    final isSelected = _selectedMusicIndex == index;
    final isPlaying = _playingMusicIndex == index;

    return GestureDetector(
      onTap: () => _selectMusic(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? blueColor.withOpacity(0.08) : Colors.transparent,
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            left: BorderSide(
              color: isSelected ? blueColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icône de musique
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? blueColor : blueColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: whiteColor,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 12),
            // Infos de la musique
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music['title']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: blueColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    music['artist']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: greyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton Play/Pause
            GestureDetector(
              onTap: () => _togglePlayMusic(index),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: whiteColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: blueColor,
                    size: 22,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            // Bouton de sélection/désélection
            GestureDetector(
              onTap: () => _selectMusic(index),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? blueColor : whiteColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? blueColor : Color(0xFFE0E0E0),
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? Icons.close : Icons.check,
                    color: isSelected ? whiteColor : blueColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Suivant',
          style: TextStyle(
            color: whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Painter pour la bordure en pointillés
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dashWidth = 8.0;
    final radius = 12.0;

    // Top side
    double x = radius;
    while (x < size.width - radius) {
      path.moveTo(x, 0);
      path.lineTo(x + dashWidth > size.width - radius ? size.width - radius : x + dashWidth, 0);
      x += dashWidth + gap;
    }

    // Right side
    double y = radius;
    while (y < size.height - radius) {
      path.moveTo(size.width, y);
      path.lineTo(size.width, y + dashWidth > size.height - radius ? size.height - radius : y + dashWidth);
      y += dashWidth + gap;
    }

    // Bottom side
    x = size.width - radius;
    while (x > radius) {
      path.moveTo(x, size.height);
      path.lineTo(x - dashWidth < radius ? radius : x - dashWidth, size.height);
      x -= dashWidth + gap;
    }

    // Left side
    y = size.height - radius;
    while (y > radius) {
      path.moveTo(0, y);
      path.lineTo(0, y - dashWidth < radius ? radius : y - dashWidth);
      y -= dashWidth + gap;
    }

    // Corners (arcs)
    path.addArc(Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14159, 0.5);
    path.addArc(Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2), -1.5708, 0.5);
    path.addArc(Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2, radius * 2, radius * 2), 0, 0.5);
    path.addArc(Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2), 1.5708, 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Widget pour la prévisualisation du message en bottom sheet
class MessagePreviewBottomSheet extends StatefulWidget {
  final Map<String, dynamic> messageData;
  final ScrollController scrollController;
  final VoidCallback? onMessageCreated;

  const MessagePreviewBottomSheet({
    super.key,
    required this.messageData,
    required this.scrollController,
    this.onMessageCreated,
  });

  @override
  State<MessagePreviewBottomSheet> createState() => _MessagePreviewBottomSheetState();
}

class _MessagePreviewBottomSheetState extends State<MessagePreviewBottomSheet> {
  int _selectedBackgroundIndex = 0;
  bool _isBackgroundExpanded = true;
  bool _isLoading = false;
  final MessageService _messageService = MessageService();

  final List<String> _backgrounds = [
    'assets/images/s1.jpg',
    'assets/images/s2.jpg',
    'assets/images/s3.png',
    'assets/images/s4.png',
    'assets/images/s5.jpg',
  ];

  // Mapping des catégories vers leurs IDs (à adapter selon votre API)
  final Map<String, int> _categoryIds = {
    'Anniversaire': 1,
    'Mariage': 2,
    'Voeux': 3,
    'Vœux': 3,
    'Nouvel an': 4,
    'Noël': 5,
  };

  String get _category => widget.messageData['category'] ?? '';

  Future<void> _onGenerate() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Préparer les images
      List<File>? imageFiles;
      final images = widget.messageData['images'] as List<String>?;
      if (images != null && images.isNotEmpty) {
        imageFiles = images.map((path) => File(path)).toList();
      }

      // Récupérer l'ID de la catégorie
      final categoryId = _categoryIds[_category] ?? 1;

      // Appeler l'API pour créer le message
      final result = await _messageService.createMessage(
        titre: widget.messageData['title'] ?? 'Mon message',
        contenu: widget.messageData['message'],
        sousCategorieId: categoryId,
        images: imageFiles,
        backgroundPath: _backgrounds[_selectedBackgroundIndex],
        expiration: widget.messageData['expiration'] ?? '24h',
      );

      if (result['success'] == true) {
        // Ajouter le slug au messageData
        final updatedMessageData = Map<String, dynamic>.from(widget.messageData);
        updatedMessageData['slug'] = result['slug'];
        updatedMessageData['shareUrl'] = result['shareUrl'];

        if (mounted) {
          // Fermer le bottom sheet actuel
          Navigator.pop(context);

          // Rafraîchir la page d'accueil
          widget.onMessageCreated?.call();

          // Naviguer vers la page de résultat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageResultScreen(
                messageData: updatedMessageData,
                selectedBackgroundIndex: _selectedBackgroundIndex,
                backgrounds: _backgrounds,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du message: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 12),
        // Indicateur de drag
        Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(height: 16),
        // Header bleu avec titre de catégorie
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: blueColor,
          ),
          child: Text(
            _category,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: whiteColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
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
            // Juste le gift au centre (sans card blanc, sans titre, sans description)
            Center(
              child: Image.asset(
                'assets/images/Wrapped_Gift.gif',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.card_giftcard,
                  size: 150,
                  color: Colors.amber,
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
          // Header
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
                          'Sélectionnez un arrière plan pour donné plus vie a votre message.',
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
          // Liste des arrière-plans
          if (_isBackgroundExpanded)
            Container(
              height: 80,
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _backgrounds.length,
                itemBuilder: (context, index) => _buildBackgroundItem(index),
              ),
            ),
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
        width: 65,
        height: 65,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? blueColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
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
                  color: greyColor.withOpacity(0.2),
                  child: Icon(Icons.image, color: greyColor, size: 20),
                ),
              ),
              if (isSelected)
                Container(
                  color: blueColor.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: blueColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: whiteColor, size: 14),
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
              onPressed: () => Navigator.pop(context),
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
                disabledBackgroundColor: blueColor.withValues(alpha: 0.6),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
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

