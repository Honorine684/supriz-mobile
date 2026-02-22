// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/screens/notifications/notifications_screen.dart';
import 'package:supriz/widgets/skeleton_loader.dart';
import '../../models/publicite.dart';
import '../profil/profil_screen.dart';
import '../../services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/publicite_service.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../birthdays/birthdays_list_screen.dart';
import '../historique/historique_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onCreateMessagePressed;
  final VoidCallback? onViewAllPressed;

  const HomeScreen({
    super.key,
    this.onCreateMessagePressed,
    this.onViewAllPressed,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _userName = 'Invité';
  File? _profileImage;
  late Future<List<Publicite>> _publicitesFuture;
  late PubliciteService _publiciteService;
  final MessageService _messageService = MessageService();
  List<MessageItem> _messagesRecents = [];
  bool _isLoadingMessages = true;

  // Méthode publique pour rafraîchir les messages (appelée depuis l'extérieur)
  Future<void> refreshMessages() async {
    setState(() => _isLoadingMessages = true);
    await _loadMessages();
    setState(() {
      _publicitesFuture = _publiciteService.fetchPublicites();
    });
  }

  // Rafraîchissement silencieux (sans indicateur de chargement)
  Future<void> _silentRefresh() async {
    try {
      final messages = await _messageService.fetchMessages();
      if (mounted) {
        setState(() {
          _messagesRecents = messages.take(6).toList();
        });
      }
    } catch (e) {
      // Ignorer les erreurs en mode silencieux
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Rafraîchir silencieusement quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
      _loadNotificationCount(); // Rafraîchir le compteur de notifications
    }
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileImage();
    _publiciteService = PubliciteService();
    _publicitesFuture = _publiciteService.fetchPublicites();
    _loadUserName();
    _loadMessages();
    _loadNotificationCount();
    profileImageNotifier.addListener(_updateProfileImage);
    messagesRefreshNotifier.addListener(_silentRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageService.fetchMessages();
      if (mounted) {
        setState(() {
          _messagesRecents = messages.take(6).toList(); // Afficher les 6 derniers
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService().fetchNotifications();
      // Mettre en cache les notifications
      notificationsCache.value = notifications;
      notificationsLoaded = true;
      // Mettre à jour le compteur
      final unreadCount = notifications.where((n) => !n.isRead).length;
      notificationCountNotifier.value = unreadCount;
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profileImageNotifier.removeListener(_updateProfileImage);
    messagesRefreshNotifier.removeListener(_silentRefresh);
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localImagePath = prefs.getString('localProfileImagePath');

    if (localImagePath != null && File(localImagePath).existsSync()) {
      profileImageNotifier.value = File(localImagePath);
    } else {
      String? profileImagePath = prefs.getString('profileImagePath');
      if (profileImagePath != null) {
        String fullImagePath = "$domaineapiImage/$profileImagePath";
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
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
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

  String _getFirstName() {
    if (_userName.isEmpty) return '';
    // Prendre le premier mot (prénom)
    final firstName = _userName.split(' ').first.trim();
    if (firstName.isEmpty) return '';
    // Mettre la première lettre en majuscule
    return firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === PARTIE FIXE (ne scroll pas) ===
          // Bienvenue
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                "Bienvenue ${_getFirstName()}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Bannière CTA si pas de messages, sinon carrousel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: (!_isLoadingMessages && _messagesRecents.isEmpty)
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0066B3), // Bleu
                          Color(0xFF1B8B5A), // Vert
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créez votre premier message Supriz',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Partagez des moments éphémères avec vos proches',
                          style: TextStyle(
                            color: whiteColor.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        Material(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            onTap: widget.onCreateMessagePressed,
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Text(
                                'Créer mon message supriz',
                                style: TextStyle(
                                  color: Color(0xFF0066B3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<Publicite>>(
                    future: _publicitesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 155,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          height: 180,
                          child: Center(
                            child: Text("Erreur de chargement des publicités"),
                          ),
                        );
                      } else {
                        return ImageSwiper(
                          publicites: snapshot.data!,
                        );
                      }
                    },
                  ),
          ),
          SizedBox(height: 20),
          // Section Messages récents (titre)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Messages récents",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAllPressed,
                  child: Text(
                    "Voir tout",
                    style: TextStyle(
                      color: blueColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          // === PARTIE SCROLLABLE (messages récents uniquement) ===
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshMessages,
              color: blueColor,
              child: _isLoadingMessages
                  ? ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return _buildMessageCardSkeleton();
                      },
                    )
                  : _messagesRecents.isEmpty
                      ? ListView(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 50, horizontal: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    // Icône personnalisée style paquet
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE8E0D5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 40,
                                            color: Color(0xFFB8A99A),
                                          ),
                                          Positioned(
                                            right: 12,
                                            bottom: 12,
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFD4C9BC),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Color(0xFF9A8B7A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Aucun message supriz pour le moment,',
                                      style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'veuillez ajouter un pour voir.',
                                      style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(left: 16, right: 16, bottom: 100),
                          itemCount: _messagesRecents.length,
                          itemBuilder: (context, index) {
                            return _buildMessageCardFromApi(_messagesRecents[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtenir l'URL de l'image du message (mediaUrl ou première image de la liste)
  String? _getMessageImageUrl(MessageItem message) {
    // Priorité : mediaUrl, puis première image de la liste
    if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
      return message.mediaUrl;
    }
    if (message.images != null && message.images!.isNotEmpty) {
      return message.images!.first;
    }
    return null;
  }

  Widget _buildMessageCardFromApi(MessageItem message) {
    final bool isActif = message.isActive && !message.isExpired;
    final bool hasViews = message.viewsCount > 0;

    return GestureDetector(
      onTap: () {
        // Naviguer vers l'historique des messages
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoriquesScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActif ? blueColor.withValues(alpha: 0.2) : greyColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [
          // Image - utiliser mediaUrl ou la première image de la liste
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _getMessageImageUrl(message) != null
                ? CachedNetworkImage(
                    imageUrl: _getMessageImageUrl(message)!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 70,
                      height: 70,
                      color: greyColor.withValues(alpha: 0.2),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 70,
                      height: 70,
                      color: blueColor.withValues(alpha: 0.1),
                      child: Icon(Icons.card_giftcard, color: blueColor),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: blueColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard, color: blueColor, size: 32),
                  ),
          ),
          SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.titre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                if (message.categorie != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roscColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.categorie!,
                      style: TextStyle(fontSize: 11, color: blackColor),
                    ),
                  ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: greyColor),
                    SizedBox(width: 4),
                    Text(
                      "Expire le ${message.dateExpiration}",
                      style: TextStyle(fontSize: 12, color: greyColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Statut et Réactions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActif ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActif ? 'Actif' : (message.isExpired ? 'Expiré' : 'Inactif'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isActif ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Afficher les réactions s'il y en a (sans numérotation)
              if (message.reactions.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: message.reactions.entries.map((entry) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: blueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(entry.key, style: TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasViews ? Icons.visibility : Icons.visibility_off_outlined,
                      size: 14,
                      color: hasViews ? blueColor : greyColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      hasViews ? 'Lu' : 'Non lu',
                      style: TextStyle(fontSize: 12, color: hasViews ? blueColor : greyColor),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageCardSkeleton() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyColor.withValues(alpha: 0.2)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              children: [
                Container(
                  height: 24,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: whiteColor,
      surfaceTintColor: whiteColor,
      centerTitle: false,
      title: Image.asset(logo, height: 28),
      actions: [
        // Anniversaires
        IconButton(
          icon: Icon(Icons.cake_outlined, color: blackColor, size: 26),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BirthdaysListScreen()),
            );
            // Rafraichir les rappels de notification au retour
            NotificationService().scheduleAllBirthdayReminders();
          },
        ),
        // Notification avec badge
        ValueListenableBuilder<int>(
          valueListenable: notificationCountNotifier,
          builder: (context, count, child) {
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: blackColor, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationScreen()),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: blueColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Avatar profil
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilScreen()),
              );
            },
            child: ValueListenableBuilder<File?>(
              valueListenable: profileImageNotifier,
              builder: (context, image, child) {
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: greyColor.withOpacity(0.2),
                  backgroundImage: image != null ? FileImage(image) : null,
                  child: image == null
                      ? Icon(Icons.person, color: greyColor, size: 24)
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ImageSwiper extends StatelessWidget {
  final List<Publicite> publicites;

  const ImageSwiper({
    super.key,
    required this.publicites,
  });

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Swiper(
        itemCount: publicites.length,
        autoplay: true,
        autoplayDisableOnInteraction: true,
        autoplayDelay: 5000,
        loop: true,
        viewportFraction: 0.9,
        scale: 0.95,
        pagination: SwiperPagination(
          alignment: Alignment.bottomCenter,
          builder: DotSwiperPaginationBuilder(
            activeColor: blueColor,
            color: greyColor.withOpacity(0.3),
            size: 8,
            activeSize: 8,
          ),
        ),
        itemBuilder: (BuildContext context, int index) {
          final publicite = publicites[index];
          return GestureDetector(
            onTap: () {
              // Ouvrir le lien seulement s'il est défini
              if (publicite.lien != null && publicite.lien!.isNotEmpty) {
                _openLink(publicite.lien!);
              }
              // Sinon ne rien faire
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: publicite.pathImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: greyColor.withOpacity(0.1),
                    child: Center(child: CircularProgressIndicator(color: blueColor)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: greyColor.withOpacity(0.1),
                    child: Center(child: Icon(Icons.error, color: greyColor)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
