// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/services/message_service.dart';
import 'package:supriz/widgets/appbar_custom.dart';
import 'package:supriz/widgets/skeleton_loader.dart';

class HistoriquesScreen extends StatefulWidget {
  const HistoriquesScreen({super.key});

  @override
  State<HistoriquesScreen> createState() => _HistoriquesScreenState();
}

class _HistoriquesScreenState extends State<HistoriquesScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;
  List<MessageItem> _messages = [];
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    messagesRefreshNotifier.addListener(_silentRefresh);
    _loadMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messagesRefreshNotifier.removeListener(_silentRefresh);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Rafraîchir silencieusement quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  // Rafraîchissement silencieux (sans indicateur de chargement)
  Future<void> _silentRefresh() async {
    try {
      final messages = await _messageService.fetchMessages();
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    } catch (e) {
      // Ignorer les erreurs en mode silencieux
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await _messageService.fetchMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les messages';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMessage(MessageItem message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le message'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${message.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _messageService.deleteMessage(message.id);
        _loadMessages();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message supprimé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleMessageStatus(MessageItem message) async {
    try {
      await _messageService.toggleMessageStatus(message.id);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du changement de statut'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _shareMessage(MessageItem message) {
    Share.share(
      'Découvre mon message Supriz : ${message.shareUrl}',
      subject: message.titre,
    );
  }

  void _copyLink(MessageItem message) {
    Clipboard.setData(ClipboardData(text: message.shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien copié !'), backgroundColor: blueColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: "Mes Messages"),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: List.generate(4, (_) => MessageCardSkeleton()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.error_outline, size: 50, color: Colors.red),
              ),
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: blackColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadMessages,
                icon: Icon(Icons.refresh),
                label: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: whiteColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: blueColor,
      child: _messages.isEmpty
          ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: greyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(Icons.mail_outline, size: 60, color: greyColor),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vos messages créés apparaîtront ici',
                          style: TextStyle(fontSize: 14, color: greyColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tirez vers le bas pour rafraîchir',
                          style: TextStyle(fontSize: 12, color: greyColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageCard(_messages[index]);
              },
            ),
    );
  }

  String? _getMessageImageUrl(MessageItem message) {
    if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
      return message.mediaUrl;
    }
    if (message.images != null && message.images!.isNotEmpty) {
      return message.images!.first;
    }
    return null;
  }

  Widget _buildMessageCard(MessageItem message) {
    final bool isActif = message.isActive && !message.isExpired;
    final bool hasViews = message.viewsCount > 0;
    final imageUrl = _getMessageImageUrl(message);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                // Image ou placeholder
                imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: blueColor.withValues(alpha: 0.1),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: blueColor.withValues(alpha: 0.1),
                          child: Icon(Icons.card_giftcard, color: blueColor, size: 50),
                        ),
                      )
                    : Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [blueColor.withValues(alpha: 0.2), blueColor.withValues(alpha: 0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.card_giftcard, color: blueColor, size: 50),
                      ),
                // Badge statut
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActif ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActif ? 'Actif' : (message.isExpired ? 'Expiré' : 'Inactif'),
                      style: TextStyle(color: whiteColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Badge catégorie
                if (message.categorie != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roscColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.categorie!,
                        style: TextStyle(color: blueColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Contenu
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.titre,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.contenu != null && message.contenu!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    message.contenu!,
                    style: TextStyle(fontSize: 14, color: greyColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 12),
                // Infos - Lu/Non lu au lieu du nombre de vues
                Row(
                  children: [
                    Icon(
                      hasViews ? Icons.visibility : Icons.visibility_off_outlined,
                      size: 16,
                      color: hasViews ? blueColor : greyColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      hasViews ? 'Lu' : 'Non lu',
                      style: TextStyle(fontSize: 12, color: hasViews ? blueColor : greyColor),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.timer_outlined, size: 16, color: greyColor),
                    SizedBox(width: 4),
                    Text('Expire: ${message.dateExpiration}', style: TextStyle(fontSize: 12, color: greyColor)),
                  ],
                ),
                // Réactions (sans numérotation)
                if (message.reactions.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.reactions.entries.map((entry) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: blueColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(entry.key, style: TextStyle(fontSize: 18)),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    // Masquer Copier et Partager si le message est expiré
                    if (!message.isExpired) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyLink(message),
                          icon: Icon(Icons.copy, size: 18),
                          label: Text('Copier'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: blueColor,
                            side: BorderSide(color: blueColor),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareMessage(message),
                          icon: Icon(Icons.share, size: 18),
                          label: Text('Partager'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueColor,
                            foregroundColor: whiteColor,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    // Pousse le menu à droite si message expiré
                    if (message.isExpired) Spacer(),
                    // Menu actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: greyColor),
                      onSelected: (value) {
                        if (value == 'toggle') {
                          _toggleMessageStatus(message);
                        } else if (value == 'delete') {
                          _deleteMessage(message);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                message.isActive ? Icons.visibility_off : Icons.visibility,
                                color: greyColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(message.isActive ? 'Désactiver' : 'Activer'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
