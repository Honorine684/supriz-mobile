// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';

class MessageResultScreen extends StatefulWidget {
  final Map<String, dynamic> messageData;
  final int selectedBackgroundIndex;
  final List<String> backgrounds;

  const MessageResultScreen({
    super.key,
    required this.messageData,
    required this.selectedBackgroundIndex,
    required this.backgrounds,
  });

  @override
  State<MessageResultScreen> createState() => _MessageResultScreenState();
}

class _MessageResultScreenState extends State<MessageResultScreen> {
  String get _title => widget.messageData['title'] ?? 'Mon message';
  String get _message => widget.messageData['message'] ?? '';
  String get _expiration => widget.messageData['expiration'] ?? '24h';
  String? get _music => widget.messageData['music'];
  List<String> get _images =>
      List<String>.from(widget.messageData['images'] ?? []);
  String? get _slug => widget.messageData['slug'];

  // Lien de partage - utilise le slug de l'API
  String get _shareLink {
    if (_slug != null) {
      return 'https://supriz.bj/message/$_slug';
    }
    return 'https://supriz.bj/message/unknown';
  }
  bool _showCopySuccess = false;

  // Slider pour les images
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareLink));
    setState(() => _showCopySuccess = true);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopySuccess = false);
    });
  }

  void _shareMessage() async {
    try {
      await Share.share(
        'Découvre mon message surprise ! 🎁\n\n$_shareLink',
        subject: _title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      // Générer le QR code en image
      final qrValidationResult = QrValidator.validate(
        data: _shareLink,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/qr_code_supriz.png';
        final picData = await painter.toImageData(300);

        if (picData != null) {
          final buffer = picData.buffer.asUint8List();
          final file = File(path);
          await file.writeAsBytes(buffer);

          // Partager le fichier
          await Share.shareXFiles(
            [XFile(path)],
            text: 'QR Code pour mon message Supriz',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('QR Code prêt à partager !'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPreview() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _buildPreviewDialog(),
    );
  }

  String get _formattedExpirationDate {
    final now = DateTime.now();
    final hours = _expiration == '48h' ? 48 : 24;
    final expireDate = now.add(Duration(hours: hours));
    return '${expireDate.day.toString().padLeft(2, '0')}/${expireDate.month.toString().padLeft(2, '0')}/${expireDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8EDF2),
      appBar: CustomAppBar(title: 'Résultat'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + Badge Actif
            _buildTitleRow(),
            SizedBox(height: 20),
            // Card message
            _buildMessageCard(),
            SizedBox(height: 20),
            // Expiration + Aperçu
            _buildExpirationRow(),
            SizedBox(height: 25),
            // QR Code
            _buildQRCodeSection(),
            SizedBox(height: 25),
            // Lien de partage
            _buildShareLinkSection(),
            SizedBox(height: 20),
            // Boutons d'action
            _buildActionButtons(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFC7E9D7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Actif',
            style: TextStyle(
              color: Color(0xFF047857),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFC8DFE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images en slider ou image unique
          _buildImageSlider(),
          // Contenu texte
          if (_message.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              _message,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    // Si pas d'images utilisateur, afficher le background
    if (_images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          widget.backgrounds[widget.selectedBackgroundIndex],
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
        ),
      );
    }

    // Une seule image : pas de slider ni de dots
    if (_images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_images.first),
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
        ),
      );
    }

    // Plusieurs images : slider + dots
    return Column(
      children: [
        // Slider
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300),
            child: PageView.builder(
              controller: _imagePageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.file(
                  File(_images[index]),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(0xFFE0E0E0),
                    child: Icon(Icons.image, color: greyColor, size: 40),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_images.length, (index) {
            final isActive = _currentImageIndex == index;
            return Container(
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Color(0xFF005792) : Color(0xFF005792).withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExpirationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Expire le $_formattedExpirationDate',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF4B5563),
          ),
        ),
        GestureDetector(
          onTap: _showPreview,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFD1E3EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, color: Color(0xFF005792), size: 16),
                SizedBox(width: 8),
                Text(
                  'Aperçu',
                  style: TextStyle(
                    color: Color(0xFF005792),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: QrImageView(
          data: _shareLink,
          version: QrVersions.auto,
          size: 180,
          backgroundColor: whiteColor,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ),
      ),
    );
  }

  Widget _buildShareLinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lien de partage',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5563),
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Lien dans un fond gris
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _shareLink,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 10),
              // Bouton copier
              GestureDetector(
                onTap: _copyLink,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF005792),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.copy, color: whiteColor, size: 20),
                ),
              ),
            ],
          ),
        ),
        if (_showCopySuccess)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '✓ Lien copié!',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton Partager
        Expanded(
          child: GestureDetector(
            onTap: _shareMessage,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, color: Color(0xFF005792), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Partager',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF005792),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 15),
        // Bouton QR Code
        Expanded(
          child: GestureDetector(
            onTap: _downloadQRCode,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, color: Color(0xFF005792), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'QR Code',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF005792),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Popup Aperçu ----
  Widget _buildPreviewDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Contenu principal
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Stack(
                children: [
                  // Arrière-plan avec le background sélectionné
                  Positioned.fill(
                    child: Image.asset(
                      widget.backgrounds[widget.selectedBackgroundIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00789C), Color(0xFF00A3CE)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Contenu
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        // Badge musique
                        if (_music != null) _buildMusicBadge(),
                        SizedBox(height: 20),
                        // Carte blanche du message
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPreviewWhiteCard(),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bouton fermer
          Positioned(
            top: -10,
            right: -10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: whiteColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.close, color: Color(0xFF1A1A1A), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicBadge() {
    final parts = _music!.split(' - ');
    final title = parts.first;
    final artist = parts.length > 1 ? parts.last : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: whiteColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, color: Color(0xFF005792), size: 16),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF005792),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (artist.isNotEmpty)
                Text(
                  artist.toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFF005792).withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewWhiteCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Padding(
            padding: EdgeInsets.fromLTRB(25, 25, 25, 20),
            child: Text(
              _title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          // Image(s) pleine largeur
          _buildPreviewImages(),
          // Contenu du message
          if (_message.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 25, 25),
              child: Text(
                _message,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.7,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewImages() {
    // Pas d'images utilisateur : afficher le background
    if (_images.isEmpty) {
      return Image.asset(
        widget.backgrounds[widget.selectedBackgroundIndex],
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
      );
    }

    // Une seule image
    if (_images.length == 1) {
      return Image.file(
        File(_images.first),
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
      );
    }

    // Plusieurs images : slider + dots
    return _ImageSliderWidget(images: _images);
  }
}

// Widget séparé pour gérer le state du slider dans le popup
class _ImageSliderWidget extends StatefulWidget {
  final List<String> images;
  const _ImageSliderWidget({required this.images});

  @override
  State<_ImageSliderWidget> createState() => _ImageSliderWidgetState();
}

class _ImageSliderWidgetState extends State<_ImageSliderWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 400),
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.file(
                File(widget.images[index]),
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Color(0xFFE0E0E0),
                  child: Icon(Icons.image, color: greyColor, size: 40),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            final isActive = _currentIndex == index;
            return Container(
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Color(0xFF005792)
                    : Color(0xFF005792).withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
