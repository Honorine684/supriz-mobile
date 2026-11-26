// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts/consts.dart';
import '../../services/message_service.dart';
import '../../services/audio_cache_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/toast_notification.dart';

class CreateMessageFlow extends StatefulWidget {
  final String category;
  final int categoryId;
  final String? placeholderTexte;
  final String? giftImage;
  final VoidCallback? onMessageCreated;

  const CreateMessageFlow({
    super.key,
    required this.category,
    required this.categoryId,
    this.placeholderTexte,
    this.giftImage,
    this.onMessageCreated,
  });

  @override
  State<CreateMessageFlow> createState() => _CreateMessageFlowState();
}

class _CreateMessageFlowState extends State<CreateMessageFlow> {
  int _currentStep = 0;
  int _selectedBackgroundIndex = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedExpiration = '24h';
  final List<File?> _selectedImages = [null, null, null];
  // Légende de chaque photo (même index que _selectedImages), facultative
  final List<TextEditingController> _captionControllers =
      List.generate(3, (_) => TextEditingController());
  static const int _captionMaxLength = 30;
  // Nom affiché en signature sous la lettre (nom du compte)
  String? _senderName;
  bool _isLoading = false;
  final MessageService _messageService = MessageService();

  // Option vue unique
  bool _uniqueView = false;

  // Musique
  List<MusiqueItem> _musiques = [];
  MusiqueItem? _selectedMusique;
  bool _isLoadingMusiques = false;
  String? _musiquesError;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioCacheService _audioCacheService = AudioCacheService();
  int? _playingMusiqueId;
  int? _loadingMusiqueId; // Pour afficher le chargement pendant le buffering

  // Résultat de la création
  String? _createdSlug;
  String? _shareUrl;
  bool _showQRCode = false;

  // Aperçu cadeau
  bool _previewGiftOpened = false;

  // Index de la photo du dessus dans la pile de polaroids de l'aperçu
  int _previewImageIndex = 0;

  // Backgrounds depuis l'API
  List<ArrierePlanItem> _arrierePlans = [];
  bool _isLoadingArrierePlans = false;
  String? _arrierePlansError;

  // Backgrounds par défaut si l'API échoue
  final List<String> _defaultBackgrounds = [
    'assets/images/s1.jpg',
    'assets/images/s2.jpg',
    'assets/images/s3.png',
    'assets/images/s4.png',
    'assets/images/s5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadMusiques();
    _loadArrierePlans();
    _loadSenderName();
  }

  Future<void> _loadSenderName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name')?.trim();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _senderName = name);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    for (final controller in _captionControllers) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMusiques() async {
    setState(() {
      _isLoadingMusiques = true;
      _musiquesError = null;
    });
    try {
      // Charger les musiques de la catégorie sélectionnée
      print('Loading musiques for category: ${widget.category} (ID: ${widget.categoryId})');
      final musiques = await _messageService.getMusiques(categorieId: widget.categoryId);
      print('Loaded ${musiques.length} musiques for categoryId: ${widget.categoryId}');
      if (mounted) {
        setState(() {
          _musiques = musiques;
          _isLoadingMusiques = false;
        });

        // Précharger les fichiers audio en arrière-plan pour réduire la latence
        if (musiques.isNotEmpty) {
          final urls = musiques.map((m) => m.fichierUrl).toList();
          _audioCacheService.preloadAll(urls);
        }
      }
    } catch (e) {
      print('Error loading musiques: $e');
      if (mounted) {
        setState(() {
          _isLoadingMusiques = false;
          _musiquesError = e.toString();
        });
      }
    }
  }

  Future<void> _loadArrierePlans() async {
    setState(() {
      _isLoadingArrierePlans = true;
      _arrierePlansError = null;
    });
    try {
      final arrierePlans = await _messageService.getArrierePlans(categorieId: widget.categoryId);
      if (mounted) {
        setState(() {
          _arrierePlans = arrierePlans;
          _isLoadingArrierePlans = false;
        });
      }
    } catch (e) {
      print('Error loading arrière-plans: $e');
      if (mounted) {
        setState(() {
          _isLoadingArrierePlans = false;
          _arrierePlansError = e.toString();
        });
      }
    }
  }

  /// Obtenir le nombre total d'arrière-plans disponibles
  int get _backgroundsCount {
    return _arrierePlans.isNotEmpty ? _arrierePlans.length : _defaultBackgrounds.length;
  }

  /// Obtenir le chemin/URL de l'arrière-plan à l'index donné
  String _getBackgroundPath(int index) {
    if (_arrierePlans.isNotEmpty && index < _arrierePlans.length) {
      return _arrierePlans[index].imageUrl;
    } else if (index < _defaultBackgrounds.length) {
      return _defaultBackgrounds[index];
    }
    return _defaultBackgrounds.first;
  }

  /// Vérifier si l'arrière-plan est une image réseau
  bool _isNetworkBackground(int index) {
    return _arrierePlans.isNotEmpty && index < _arrierePlans.length;
  }

  /// Widget pour afficher une image d'arrière-plan (réseau ou asset)
  Widget _buildBackgroundImage(int index, {BoxFit fit = BoxFit.cover}) {
    final path = _getBackgroundPath(index);
    if (_isNetworkBackground(index)) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: greyColor.withValues(alpha: 0.2),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(blueColor),
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: greyColor.withValues(alpha: 0.2),
          child: Icon(Icons.image, color: greyColor, size: 16),
        ),
      );
    } else {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: greyColor.withValues(alpha: 0.2),
          child: Icon(Icons.image, color: greyColor, size: 16),
        ),
      );
    }
  }

  Future<void> _playMusique(MusiqueItem musique) async {
    try {
      if (_playingMusiqueId == musique.id) {
        // Arrêter la musique en cours
        await _audioPlayer.stop();
        setState(() {
          _playingMusiqueId = null;
          _loadingMusiqueId = null;
        });
      } else {
        // Afficher le chargement
        setState(() {
          _loadingMusiqueId = musique.id;
          _playingMusiqueId = null;
        });

        await _audioPlayer.stop();

        // Utiliser le cache pour une lecture plus rapide
        // Si le fichier est déjà en cache, il sera lu instantanément
        // Sinon, il sera téléchargé puis lu
        final playablePath = await _audioCacheService.downloadAndCache(musique.fichierUrl);

        // Vérifier si c'est un chemin local ou une URL
        if (playablePath.startsWith('/')) {
          // Chemin local - lecture instantanée
          await _audioPlayer.setSource(DeviceFileSource(playablePath));
        } else {
          // URL - fallback sur le streaming
          await _audioPlayer.setSource(UrlSource(playablePath));
        }
        await _audioPlayer.resume();

        if (mounted) {
          setState(() {
            _playingMusiqueId = musique.id;
            _loadingMusiqueId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMusiqueId = null;
          _playingMusiqueId = null;
        });
        ToastNotification.error(context, 'Impossible de lire la musique');
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validation avant d'aller à la musique
      if (_titleController.text.isEmpty) {
        ToastNotification.error(context, 'Veuillez entrer un titre');
        return;
      }
      if (_messageController.text.isEmpty) {
        ToastNotification.error(context, 'Veuillez entrer une description');
        return;
      }
      // Vérifier qu'au moins une image est sélectionnée
      final hasImage = _selectedImages.any((img) => img != null);
      if (!hasImage) {
        ToastNotification.error(context, 'Veuillez ajouter au moins une image');
        return;
      }
    }

    if (_currentStep < 2) {
      _audioPlayer.stop();
      setState(() {
        _playingMusiqueId = null;
        _loadingMusiqueId = null;
        _currentStep++;
        // Réinitialiser l'aperçu du cadeau quand on arrive à l'aperçu
        if (_currentStep == 2) {
          _previewGiftOpened = false;
        }
      });
    } else {
      _createMessage();
    }
  }

  void _previousStep() {
    _audioPlayer.stop();
    if (_currentStep > 0) {
      setState(() {
        _playingMusiqueId = null;
        _loadingMusiqueId = null;
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _createMessage() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      List<File>? imageFiles;
      final List<String?> imageCaptions = [];
      final images = _selectedImages.where((img) => img != null).toList();
      if (images.isNotEmpty) {
        imageFiles = images.cast<File>();
      }
      // Légendes alignées sur la liste compactée des photos
      for (int i = 0; i < _selectedImages.length; i++) {
        if (_selectedImages[i] != null) {
          final caption = _captionControllers[i].text.trim();
          imageCaptions.add(caption.isNotEmpty ? caption : null);
        }
      }

      final result = await _messageService.createMessage(
        titre: _titleController.text,
        contenu: _messageController.text.isNotEmpty ? _messageController.text : null,
        sousCategorieId: widget.categoryId,
        images: imageFiles,
        imageCaptions: imageCaptions,
        backgroundPath: _getBackgroundPath(_selectedBackgroundIndex),
        musiqueId: _selectedMusique?.id,
        expiration: _selectedExpiration,
        uniqueView: _uniqueView,
      );

      if (result['success'] == true) {
        setState(() {
          _createdSlug = result['slug'];
          _shareUrl = result['shareUrl'] ?? 'https://supriz.bj/message/${result['slug']}';
          _currentStep = 3; // Page de résultat
        });

        // Rafraîchir la page d'accueil
        widget.onMessageCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      print('Picking image for index $index');
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Image picked: ${image.path}');
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          maxWidth: 800,
          maxHeight: 800,
          compressQuality: 90,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Carré comme sur le web
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recadrer l\'image',
              toolbarColor: blueColor,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: blueColor,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true, // Verrouillé sur carré
              hideBottomControls: true, // Cacher les contrôles pour forcer le carré
              aspectRatioPresets: [
                CropAspectRatioPreset.square, // Uniquement carré disponible
              ],
            ),
            IOSUiSettings(
              title: 'Recadrer l\'image',
              aspectRatioLockEnabled: true, // Verrouillé sur carré
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true, // Cacher le sélecteur de ratio
              aspectRatioPresets: [
                CropAspectRatioPreset.square, // Uniquement carré disponible
              ],
            ),
          ],
        );

        print('Cropped file: ${croppedFile?.path}');
        if (croppedFile != null) {
          setState(() => _selectedImages[index] = File(croppedFile.path));
          print('Image saved at index $index');
        } else {
          print('Crop cancelled');
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking/cropping image: $e');
      if (mounted) {
        ToastNotification.error(context, 'Une erreur est survenue. Veuillez réessayer.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: whiteColor),
          onPressed: _currentStep < 3 ? _previousStep : () => Navigator.pop(context),
        ),
        title: Text(
          _currentStep < 3 ? widget.category : 'Message créé',
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: blueColor),
            Image.asset(
              'assets/images/appbarImg.png',
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
      body: _currentStep < 3 ? _buildStepContent() : _buildResultPage(),
      bottomNavigationBar: _currentStep < 3 ? _buildBottomButtons() : null,
    );
  }

  Widget _buildStepContent() {
    return Column(
      children: [
        // Stepper indicator
        _buildStepIndicator(),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: _currentStep == 0
                ? _buildMessageStep()
                : _currentStep == 1
                    ? _buildMusicStep()
                    : _buildPreviewStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          _buildStepCircle(0, 'Message'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Musique'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Aperçu'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? blueColor : whiteColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? blueColor : greyColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? whiteColor : greyColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? blueColor : greyColor,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(bottom: 20),
        color: isActive ? blueColor : greyColor.withValues(alpha: 0.3),
      ),
    );
  }

  // ===== STEP 1: Message Form =====
  Widget _buildMessageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rédigez votre message',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Personnalisez le contenu de votre message',
          style: TextStyle(fontSize: 14, color: greyColor),
        ),
        SizedBox(height: 24),

        // Titre
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Titre *', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _titleController,
              builder: (context, value, child) {
                final length = value.text.length;
                final color = length > 54 ? Colors.red : (length > 42 ? Colors.orange : greyColor);
                return Text(
                  '$length/60',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 60,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: widget.placeholderTexte ?? 'Ex: Joyeux anniversaire !',
            hintStyle: TextStyle(color: greyColor),
            filled: true,
            fillColor: greyColor.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: blueColor, width: 2),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Message
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Message *', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                final length = value.text.length;
                final color = length > 450 ? Colors.red : (length > 350 ? Colors.orange : greyColor);
                return Text(
                  '$length/500',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: 'Écrivez votre message ici...',
            hintStyle: TextStyle(color: greyColor),
            filled: true,
            fillColor: greyColor.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: blueColor, width: 2),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Images
        Text('Images *', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
        SizedBox(height: 8),
        CustomPaint(
          painter: DottedBorderPainter(
            color: blueColor,
            strokeWidth: 1.5,
            gap: 5,
            radius: 12,
          ),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD), // Bleu ciel
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(3, (index) => Expanded(child: _buildImageSlot(index))),
            ),
          ),
        ),
        // Légende par photo (affichée sous le polaroid)
        if (_selectedImages.any((img) => img != null)) ...[
          SizedBox(height: 12),
          Text('Légendes (facultatif)', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
          SizedBox(height: 8),
          for (int i = 0; i < _selectedImages.length; i++)
            if (_selectedImages[i] != null) _buildCaptionField(i),
        ],
        SizedBox(height: 20),

        // Vue unique
        _buildUniqueViewChip(),
        SizedBox(height: 16),

        // Expiration (masqué si vue unique activée)
        if (!_uniqueView) ...[
          Text('Durée de validité', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildExpirationChip('24h'),
              _buildExpirationChip('48h'),
              _buildExpirationChip('72h'),
            ],
          ),
        ] else ...[
          // Info pour l'utilisateur quand vue unique est activée
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le message disparaîtra après la première vue ou après 24h si non consulté.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageSlot(int index) {
    final hasImage = _selectedImages[index] != null;

    return GestureDetector(
      onTap: () => hasImage
          ? setState(() {
              _selectedImages[index] = null;
              _captionControllers[index].clear();
            })
          : _pickImage(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        height: 80,
        decoration: BoxDecoration(
          color: hasImage ? null : greyColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasImage ? blueColor : greyColor.withValues(alpha: 0.3)),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_selectedImages[index]!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Icon(Icons.close, color: whiteColor, size: 14),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: greyColor, size: 24),
                  SizedBox(height: 4),
                  Text('Photo ${index + 1}', style: TextStyle(fontSize: 10, color: greyColor)),
                ],
              ),
      ),
    );
  }

  Widget _buildCaptionField(int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedImages[index]!, width: 44, height: 44, fit: BoxFit.cover),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _captionControllers[index],
              maxLength: _captionMaxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Légende de la photo ${index + 1}',
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: greyColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: greyColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: blueColor, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundItem(int index) {
    final isSelected = _selectedBackgroundIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedBackgroundIndex = index),
      child: Container(
        width: 60,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? blueColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackgroundImage(index),
              if (isSelected)
                Container(
                  color: blueColor.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
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

  Widget _buildExpirationChip(String value) {
    final isSelected = _selectedExpiration == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedExpiration = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? blueColor : whiteColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? blueColor : greyColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? whiteColor : blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUniqueViewChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _uniqueView = !_uniqueView;
          // Forcer 24h quand vue unique est activée
          if (_uniqueView) {
            _selectedExpiration = '24h';
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _uniqueView ? Colors.orange : whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _uniqueView ? Colors.orange : greyColor.withValues(alpha: 0.3),
            width: _uniqueView ? 2 : 1,
          ),
          boxShadow: _uniqueView ? [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _uniqueView ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: _uniqueView ? whiteColor : greyColor,
            ),
            SizedBox(width: 8),
            Text(
              'Vue unique',
              style: TextStyle(
                color: _uniqueView ? whiteColor : blackColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (_uniqueView) ...[
              SizedBox(width: 8),
              Icon(Icons.check_circle, size: 18, color: whiteColor),
            ],
          ],
        ),
      ),
    );
  }

  // ===== STEP 2: Music Selection =====
  Widget _buildMusicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez une musique',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ajoutez une musique de fond à votre message (optionnel)',
          style: TextStyle(fontSize: 14, color: greyColor),
        ),
        SizedBox(height: 24),

        if (_isLoadingMusiques)
          Column(
            children: List.generate(4, (_) => MusicItemSkeleton()),
          )
        else if (_musiquesError != null)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Erreur: $_musiquesError',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMusiques,
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            ),
          )
        else if (_musiques.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.music_off, color: greyColor, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Aucune musique disponible',
                    style: TextStyle(color: greyColor, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vous pouvez continuer sans musique',
                    style: TextStyle(color: greyColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Si une musique est sélectionnée, afficher seulement celle-ci
          if (_selectedMusique != null)
            _buildSelectedMusicItem(_selectedMusique!)
          else
            // Sinon afficher toutes les musiques
            ...List.generate(_musiques.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildMusicItem(_musiques[index]),
              );
            }),
        ],
      ],
    );
  }

  // Item de musique non sélectionné (liste complète)
  Widget _buildMusicItem(MusiqueItem musique) {
    final isPlaying = _playingMusiqueId == musique.id;
    final isLoading = _loadingMusiqueId == musique.id;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isPlaying || isLoading) ? blueColor.withValues(alpha: 0.05) : greyColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPlaying || isLoading) ? blueColor.withValues(alpha: 0.3) : greyColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Bouton Play/Pause pour écouter
          GestureDetector(
            onTap: isLoading ? null : () => _playMusique(musique),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isPlaying || isLoading) ? blueColor : blueColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: (isPlaying || isLoading) ? whiteColor : blueColor,
                        size: 24,
                      ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Info musique
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musique.titre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                    fontSize: 15,
                  ),
                ),
                if (musique.artiste != null) ...[
                  SizedBox(height: 4),
                  Text(
                    musique.artiste!,
                    style: TextStyle(color: greyColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          // Bouton pour sélectionner
          GestureDetector(
            onTap: () {
              _audioPlayer.stop();
              setState(() {
                _selectedMusique = musique;
                _playingMusiqueId = null;
                _loadingMusiqueId = null;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Choisir',
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Item de musique sélectionné (avec croix pour désélectionner)
  Widget _buildSelectedMusicItem(MusiqueItem musique) {
    final isPlaying = _playingMusiqueId == musique.id;
    final isLoading = _loadingMusiqueId == musique.id;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blueColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: blueColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Bouton Play/Pause
          GestureDetector(
            onTap: isLoading ? null : () => _playMusique(musique),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isPlaying || isLoading) ? blueColor : blueColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: (isPlaying || isLoading) ? whiteColor : blueColor,
                        size: 24,
                      ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Info musique
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musique.titre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                    fontSize: 15,
                  ),
                ),
                if (musique.artiste != null) ...[
                  SizedBox(height: 4),
                  Text(
                    musique.artiste!,
                    style: TextStyle(color: greyColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          // Bouton croix pour désélectionner
          GestureDetector(
            onTap: () {
              _audioPlayer.stop();
              setState(() {
                _selectedMusique = null;
                _playingMusiqueId = null;
                _loadingMusiqueId = null;
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ===== STEP 3: Preview =====
  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu de votre message',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Vérifiez votre message avant de l\'envoyer',
          style: TextStyle(fontSize: 14, color: greyColor),
        ),
        SizedBox(height: 24),

        // Card preview - Gift ou Message
        GestureDetector(
          onTap: () {
            if (!_previewGiftOpened) {
              setState(() => _previewGiftOpened = true);
            }
          },
          child: Container(
            width: double.infinity,
            height: 460,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                  // Background
                  _buildBackgroundImage(_selectedBackgroundIndex),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Contenu : Gift ou Message
                  if (!_previewGiftOpened)
                    // Vue cadeau (avant ouverture)
                    _buildGiftView()
                  else
                    // Vue message (après ouverture)
                    _buildMessageView(),
                ],
              ),
            ),
          ),
        ),
        // Bouton pour réinitialiser l'aperçu
        if (_previewGiftOpened)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _previewGiftOpened = false),
                icon: Icon(Icons.refresh, size: 18, color: blueColor),
                label: Text('Revoir le cadeau', style: TextStyle(color: blueColor)),
              ),
            ),
          ),
        SizedBox(height: 20),

        // Arrière-plan
        CustomPaint(
          painter: DottedBorderPainter(
            color: blueColor,
            strokeWidth: 1.5,
            gap: 5,
            radius: 16,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD), // Bleu ciel
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Changer l\'arrière-plan', style: TextStyle(fontWeight: FontWeight.w500, color: blackColor)),
                SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _backgroundsCount,
                    itemBuilder: (context, index) => _buildBackgroundItem(index),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Infos
        if (_uniqueView)
          // Affichage pour vue unique
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text(
                  'Vue unique (expire après 24h si non vu)',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          // Affichage normal pour expiration
          Row(
            children: [
              Icon(Icons.timer_outlined, color: greyColor, size: 18),
              SizedBox(width: 8),
              Text('Expire dans $_selectedExpiration', style: TextStyle(color: greyColor)),
            ],
          ),
      ],
    );
  }

  // Vue du cadeau (avant ouverture)
  Widget _buildGiftView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Badge catégorie
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: blueColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.category,
              style: TextStyle(color: whiteColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        // Musique indicator
        if (_selectedMusique != null)
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: whiteColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, color: blueColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      _selectedMusique!.titre,
                      style: TextStyle(color: blueColor, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Contenu centré : GIF + Indice (sans titre)
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GIF du cadeau - depuis le backend ou par défaut
              widget.giftImage != null
                  ? Image.network(
                      widget.giftImage!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: 140,
                          height: 140,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/Wrapped_Gift.gif',
                        width: 140,
                        height: 140,
                      ),
                    )
                  : Image.asset(
                      'assets/images/Wrapped_Gift.gif',
                      width: 140,
                      height: 140,
                    ),
              SizedBox(height: 20),
              // Indice pour cliquer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Clique pour ouvrir',
                    style: TextStyle(
                      color: whiteColor.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.touch_app, color: whiteColor.withValues(alpha: 0.9), size: 18),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Lot 5 : aperçu identique à la page web (pile de polaroids, lettre) =====
  static const Color _kraftColor = Color(0xFFC9A27A);
  static const Color _paperColor = Color(0xFFFFFDF8);
  static const Color _inkColor = Color(0xFF2A1D10);
  static const Color _handInkColor = Color(0xFF2B2B2B);

  // Vue du message dans l'aperçu (après ouverture du cadeau)
  Widget _buildMessageView() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: SingleChildScrollView(child: _buildMessageContent()),
    );
  }

  // Contenu du message : musique + planche kraft (aperçu et page de résultat)
  Widget _buildMessageContent() {
    final images = _selectedImages.whereType<File>().toList();
    final captions = <String>[
      for (int i = 0; i < _selectedImages.length; i++)
        if (_selectedImages[i] != null) _captionControllers[i].text.trim(),
    ];

    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Music indicator en haut
            if (_selectedMusique != null)
              Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: whiteColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, color: blueColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      _selectedMusique!.titre,
                      style: TextStyle(color: blueColor, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            // Planche kraft
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: BoxDecoration(
                color: _kraftColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleController.text.isNotEmpty ? _titleController.text : 'Titre',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: _inkColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (images.isNotEmpty) _buildPolaroidStack(images, captions),
                  if (images.length > 1)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Touche la photo pour voir la suivante · ${(_previewImageIndex % images.length) + 1} / ${images.length}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E3420),
                        ),
                      ),
                    ),
                  if (_messageController.text.trim().isNotEmpty) ...[
                    SizedBox(height: 14),
                    _buildLetterNote(_messageController.text.trim()),
                  ],
                ],
              ),
            ),
          ],
    );
  }

  // Pile de polaroids : un toucher fait passer la photo du dessus en dessous
  Widget _buildPolaroidStack(List<File> images, List<String> captions) {
    const double cardWidth = 170;
    const spots = <List<double>>[
      // [rotation en degrés, décalage x, décalage y]
      [-2, 0, 0],
      [6, 12, 7],
      [-8, -14, 10],
    ];
    final count = images.length;
    final top = _previewImageIndex % count;

    Widget card(int index, int pos) {
      final spot = spots[math.min(pos, spots.length - 1)];
      final caption = index < captions.length ? captions[index] : '';
      return GestureDetector(
        key: ValueKey(index),
        onTap: count > 1 ? () => setState(() => _previewImageIndex = (top + 1) % count) : null,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          width: cardWidth,
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          transformAlignment: Alignment.center,
          transform: Matrix4.translationValues(spot[1], spot[2], 0)
            ..rotateZ(spot[0] * math.pi / 180),
          decoration: BoxDecoration(
            color: _paperColor,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3C230A).withValues(alpha: 0.28),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.file(images[index], fit: BoxFit.cover),
              ),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _handInkColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: cardWidth + 40,
      height: cardWidth + 34 + (count > 1 ? 26 : 10),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // De la photo la plus au fond à celle du dessus
          for (int pos = count - 1; pos >= 0; pos--) card((top + pos) % count, pos),
        ],
      ),
    );
  }

  // Lettre : tronquée en fondu si elle est longue, avec « Lire la lettre »
  Widget _buildLetterNote(String text) {
    final textStyle = GoogleFonts.caveat(fontSize: 19, height: 1.22, color: _handInkColor);
    final signatureStyle = GoogleFonts.caveat(fontSize: 18, color: blueColor);
    const int previewLines = 4;
    const double notePadding = 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          maxLines: previewLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth - notePadding * 2);
        final isLong = painter.didExceedMaxLines;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(notePadding),
              decoration: BoxDecoration(
                color: _paperColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3C230A).withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: isLong
                  ? ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.55, 1],
                      ).createShader(rect),
                      child: Text(text, style: textStyle, maxLines: previewLines, overflow: TextOverflow.clip),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(text, style: textStyle),
                        if (_senderName != null)
                          Text('— $_senderName', textAlign: TextAlign.right, style: signatureStyle),
                      ],
                    ),
            ),
            if (isLong)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: () => _openLetterSheet(text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: whiteColor,
                    minimumSize: Size(0, 44),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    shape: StadiumBorder(),
                  ),
                  child: Text('Lire la lettre', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
          ],
        );
      },
    );
  }

  // Lettre complète sur une feuille lignée qui monte du bas de l'écran
  void _openLetterSheet(String text) {
    const double lineHeight = 32;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.86),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: CustomPaint(
              painter: _LinedPaperPainter(lineHeight: lineHeight),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.caveat(fontSize: 22, height: lineHeight / 22, color: _handInkColor),
                    ),
                    if (_senderName != null)
                      Text(
                        '— $_senderName',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.caveat(fontSize: 21, height: lineHeight / 21, color: blueColor),
                      ),
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueColor,
                          foregroundColor: whiteColor,
                          minimumSize: Size(0, 44),
                          padding: EdgeInsets.symmetric(horizontal: 22),
                          shape: StadiumBorder(),
                        ),
                        child: Text('Fermer la lettre', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== RESULT PAGE =====
  Widget _buildResultPage() {
    final shareLink = _shareUrl ?? 'https://supriz.bj/message/$_createdSlug';

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 10),

            if (!_showQRCode) ...[
              // Container avec background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background image
                      Positioned.fill(
                        child: _buildBackgroundImage(_selectedBackgroundIndex),
                      ),
                      // Overlay gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Contenu
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildMessageContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // QR Code Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'QR Code de votre message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Scannez pour voir le message',
                      style: TextStyle(fontSize: 14, color: greyColor),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: blueColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: shareLink,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: whiteColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Image.asset(logo, height: 30),
                  ],
                ),
              ),
            ],
            SizedBox(height: 24),

            // Lien de partage
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lien de partage',
                    style: TextStyle(fontSize: 14, color: blackColor, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: greyColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            shareLink,
                            style: TextStyle(fontSize: 13, color: blackColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ToastNotification.success(context, 'Lien copié !');
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: blueColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.copy, color: whiteColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Boutons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share('Découvre mon message surprise ! 🎁\n\n$shareLink');
                },
                icon: Icon(Icons.share),
                label: Text('Partager le message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: whiteColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _showQRCode = !_showQRCode);
                },
                icon: Icon(_showQRCode ? Icons.image_outlined : Icons.qr_code),
                label: Text(_showQRCode ? 'Voir le message' : 'Afficher le QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: blueColor,
                  side: BorderSide(color: blueColor),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.add_circle_outline, size: 18),
              label: Text('Créer un autre message'),
              style: TextButton.styleFrom(foregroundColor: greyColor),
            ),
          ],
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: blueColor,
                side: BorderSide(color: blueColor),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_currentStep == 0 ? 'Annuler' : 'Précédent'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                foregroundColor: whiteColor,
                disabledBackgroundColor: blueColor.withValues(alpha: 0.6),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: whiteColor, strokeWidth: 2),
                    )
                  : Text(_currentStep == 2 ? 'Créer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour dessiner une bordure en pointillés
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? gap : gap;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Papier ligné de la lettre complète (même rendu que la page web)
class _LinedPaperPainter extends CustomPainter {
  final double lineHeight;

  _LinedPaperPainter({required this.lineHeight});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFDF8));
    final linePaint = Paint()
      ..color = const Color(0xFFD9E4EE)
      ..strokeWidth = 1;
    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) => oldDelegate.lineHeight != lineHeight;
}
