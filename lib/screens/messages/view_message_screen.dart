// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../consts/consts.dart';
import '../../services/message_service.dart';
import '../../widgets/toast_notification.dart';

class ViewMessageScreen extends StatefulWidget {
  final String slug;

  const ViewMessageScreen({super.key, required this.slug});

  @override
  State<ViewMessageScreen> createState() => _ViewMessageScreenState();
}

class _ViewMessageScreenState extends State<ViewMessageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _errorType;
  PublicMessageItem? _message;
  final MessageService _messageService = MessageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingMusic = false;
  Map<String, int> _reactions = {};
  String? _deviceId;

  // Emojis disponibles pour les réactions
  final List<String> _availableEmojis = ['❤️', '😍', '🎉', '👏', '🙏', '😢'];

  // Carousel images
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _initDeviceId();
    _loadMessage();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _imageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // Démarrer l'auto-scroll du carousel
  void _startAutoScroll(int totalImages) {
    _autoScrollTimer?.cancel();
    if (totalImages <= 1) return;

    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_userInteracting && mounted) {
        int nextIndex = (_currentImageIndex + 1) % totalImages;
        _imageController.animateToPage(
          nextIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Réinitialiser le timer après interaction utilisateur
  void _resetAutoScrollTimer(int totalImages) {
    _userInteracting = false;
    _startAutoScroll(totalImages);
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString('device_id');
    if (storedDeviceId == null) {
      storedDeviceId = Uuid().v4();
      await prefs.setString('device_id', storedDeviceId);
    }
    _deviceId = storedDeviceId;
  }

  Future<void> _loadMessage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      final message = await _messageService.getPublicMessage(
        widget.slug,
        deviceId: _deviceId,
      );
      setState(() {
        _message = message;
        _reactions = Map.from(message.reactions);
        _isLoading = false;
      });

      // Jouer la musique automatiquement si disponible
      if (message.musique != null) {
        _playMusic(message.musique!.fichierUrl);
      }
    } catch (e) {
      String errorMsg = e.toString();
      String? errorType;

      if (errorMsg.contains('MESSAGE_EXPIRED')) {
        errorMsg = 'Ce message a expiré';
        errorType = 'expired';
      } else if (errorMsg.contains('UNIQUE_VIEW_EXPIRED')) {
        errorMsg = 'Ce message a déjà été consulté';
        errorType = 'unique_view_expired';
      } else if (errorMsg.contains('ALREADY_VIEWED')) {
        errorMsg = 'Vous avez déjà vu ce message';
        errorType = 'already_viewed';
      } else if (errorMsg.contains('MAX_VIEWS_REACHED')) {
        errorMsg = 'Ce message a atteint le nombre maximum de vues';
        errorType = 'max_views';
      } else if (errorMsg.contains('MESSAGE_INACTIVE')) {
        errorMsg = 'Ce message n\'est plus disponible';
        errorType = 'inactive';
      } else {
        errorMsg = 'Impossible de charger le message';
      }

      setState(() {
        _errorMessage = errorMsg;
        _errorType = errorType;
        _isLoading = false;
      });
    }
  }

  Future<void> _playMusic(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _isPlayingMusic = true);

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlayingMusic = false);
        }
      });
    } catch (e) {
      // Ignorer les erreurs de lecture
    }
  }

  void _toggleMusic() async {
    if (_isPlayingMusic) {
      await _audioPlayer.pause();
      setState(() => _isPlayingMusic = false);
    } else if (_message?.musique != null) {
      await _audioPlayer.resume();
      setState(() => _isPlayingMusic = true);
    }
  }

  Future<void> _addReaction(String emoji) async {
    // Mise à jour optimiste : afficher immédiatement
    final oldReactions = Map<String, int>.from(_reactions);
    setState(() {
      _reactions[emoji] = (_reactions[emoji] ?? 0) + 1;
    });

    try {
      final newReactions = await _messageService.addReaction(
        widget.slug,
        emoji,
        deviceId: _deviceId,
      );
      if (mounted) {
        setState(() {
          _reactions = newReactions;
        });
      }
    } catch (e) {
      // En cas d'erreur, restaurer l'ancien état
      if (mounted) {
        setState(() {
          _reactions = oldReactions;
        });
        ToastNotification.error(context, 'Impossible d\'envoyer la réaction. Veuillez réessayer.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/Wrapped_Gift.gif',
            width: 150,
            height: 150,
          ),
          SizedBox(height: 24),
          Text(
            'Chargement du message...',
            style: TextStyle(color: whiteColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    IconData icon;
    Color iconColor;

    switch (_errorType) {
      case 'expired':
        icon = Icons.timer_off;
        iconColor = Colors.orange;
        break;
      case 'unique_view_expired':
        icon = Icons.visibility_off;
        iconColor = Colors.orange;
        break;
      case 'already_viewed':
        icon = Icons.visibility_off;
        iconColor = Colors.blue;
        break;
      case 'max_views':
        icon = Icons.visibility_off;
        iconColor = Colors.purple;
        break;
      case 'inactive':
        icon = Icons.block;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.error_outline;
        iconColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: iconColor),
            ),
            SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: TextStyle(color: whiteColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text('Retour', style: TextStyle(color: whiteColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (_message!.backgroundPath != null)
          Image.asset(
            _message!.backgroundPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Color(0xFF1a1a2e)),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
            ),
          ),

        // Overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Header avec bouton retour et musique
              _buildHeader(),

              // Contenu principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Images si présentes
                      if (_message!.images != null && _message!.images!.isNotEmpty)
                        _buildImages(),

                      SizedBox(height: 24),

                      // Titre avec police Montserrat
                      Text(
                        _message!.titre,
                        style: GoogleFonts.montserrat(
                          color: whiteColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Message avec police Montserrat
                      if (_message!.contenu != null && _message!.contenu!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          _message!.contenu!,
                          style: GoogleFonts.montserrat(
                            color: whiteColor.withValues(alpha: 0.9),
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      SizedBox(height: 32),

                      // Vues
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, color: whiteColor.withValues(alpha: 0.7), size: 18),
                          SizedBox(width: 6),
                          Text(
                            '${_message!.viewsCount} vue${_message!.viewsCount > 1 ? 's' : ''}',
                            style: TextStyle(color: whiteColor.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Réactions
                      _buildReactions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton retour
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: whiteColor, size: 28),
          ),

          // Catégorie
          if (_message!.categorie != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _message!.categorie!,
                style: TextStyle(color: whiteColor, fontWeight: FontWeight.w500),
              ),
            ),

          // Bouton musique
          if (_message!.musique != null)
            IconButton(
              onPressed: _toggleMusic,
              icon: Icon(
                _isPlayingMusic ? Icons.music_note : Icons.music_off,
                color: whiteColor,
                size: 28,
              ),
            )
          else
            SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildImages() {
    final images = _message!.images!;

    // Si une seule image, afficher en grand
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: images.first,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 280,
            color: Colors.grey.withValues(alpha: 0.3),
            child: Center(child: CircularProgressIndicator(color: whiteColor)),
          ),
        ),
      );
    }

    // Démarrer l'auto-scroll si pas déjà démarré
    if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll(images.length);
      });
    }

    // Si 2+ images, afficher en carousel plein écran avec auto-scroll
    return Column(
      children: [
        // Carousel d'images avec détection d'interaction
        GestureDetector(
          onPanDown: (_) {
            // L'utilisateur touche l'écran, arrêter l'auto-scroll
            _userInteracting = true;
            _autoScrollTimer?.cancel();
          },
          onPanEnd: (_) {
            // L'utilisateur a fini d'interagir, redémarrer après 2s
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) _resetAutoScrollTimer(images.length);
            });
          },
          onPanCancel: () {
            // L'utilisateur a annulé, redémarrer après 2s
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) _resetAutoScrollTimer(images.length);
            });
          },
          child: SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _imageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: Colors.grey.withValues(alpha: 0.3),
                        child: Center(child: CircularProgressIndicator(color: whiteColor)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        // Indicateur de pages avec boutons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton précédent
            if (images.length > 2)
              GestureDetector(
                onTap: () {
                  _userInteracting = true;
                  _autoScrollTimer?.cancel();
                  if (_currentImageIndex > 0) {
                    _imageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  Future.delayed(Duration(seconds: 2), () {
                    if (mounted) _resetAutoScrollTimer(images.length);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: whiteColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_left, color: whiteColor, size: 20),
                ),
              ),
            SizedBox(width: 12),
            // Indicateur numérique
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: whiteColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '${_currentImageIndex + 1} / ${images.length}',
                    style: GoogleFonts.montserrat(
                      color: whiteColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Bouton suivant
            if (images.length > 2)
              GestureDetector(
                onTap: () {
                  _userInteracting = true;
                  _autoScrollTimer?.cancel();
                  if (_currentImageIndex < images.length - 1) {
                    _imageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  Future.delayed(Duration(seconds: 2), () {
                    if (mounted) _resetAutoScrollTimer(images.length);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: whiteColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right, color: whiteColor, size: 20),
                ),
              ),
          ],
        ),
        // Points indicateurs
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => Container(
              width: _currentImageIndex == index ? 24 : 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _currentImageIndex == index
                    ? whiteColor
                    : whiteColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactions() {
    return Column(
      children: [
        // Afficher les réactions existantes
        if (_reactions.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _reactions.entries.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: whiteColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text(
                      '${entry.value}',
                      style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        SizedBox(height: 20),

        // Boutons pour ajouter des réactions
        if (_message!.canReact)
          Column(
            children: [
              Text(
                'Réagissez à ce message',
                style: TextStyle(color: whiteColor.withValues(alpha: 0.7), fontSize: 14),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _availableEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () => _addReaction(emoji),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: whiteColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: whiteColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }
}
