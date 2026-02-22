// notification_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supriz/consts/consts.dart';
import '../../services/notification_service.dart';
import '../../widgets/appbar_custom.dart';
import '../../consts/global.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notificationService.initializeNotifications();
    _loadNotifications();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshNotifications();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (notificationsLoaded && notificationsCache.value.isNotEmpty) {
      setState(() {
        notifications = List.from(notificationsCache.value);
      });
      _updateNotificationCount();
    } else {
      await _refreshNotifications();
    }
  }

  Future<void> _refreshNotifications() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      List<NotificationItem> fetchedNotifications = await _notificationService.fetchNotifications();
      setState(() {
        notifications = fetchedNotifications;
        _isLoading = false;
      });
      notificationsCache.value = fetchedNotifications;
      notificationsLoaded = true;
      _updateNotificationCount();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchNotifications() async {
    await _refreshNotifications();
  }

  void _updateNotificationCount() {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    notificationCountNotifier.value = unreadCount;
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
    notificationsCache.value = List.from(notifications);
    _updateNotificationCount();
  }

  Future<void> _deleteAll() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Supprimer toutes les notifications ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: blackColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Supprimer', style: TextStyle(color: whiteColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _notificationService.deleteAllNotifications();
      setState(() {
        notifications.clear();
      });
      notificationsCache.value = [];
      _updateNotificationCount();
    }
  }

  Future<void> _deleteNotification(int index) async {
    final deletedNotification = notifications[index];

    // Animation de suppression
    setState(() {
      notifications.removeAt(index);
    });

    await _notificationService.deleteNotification(deletedNotification);
    notificationsCache.value = List.from(notifications);
    _updateNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: "Notifications"),
      body: Column(
        children: [
          // Header avec actions
          if (notifications.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: blueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: blueColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (unreadCount > 0)
                    _ActionButton(
                      label: 'Tout lire',
                      onTap: _markAllAsRead,
                    ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Effacer',
                    onTap: _deleteAll,
                    isDestructive: true,
                  ),
                ],
              ),
            ),

          // Liste des notifications
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNotifications,
              color: blueColor,
              child: _isLoading && notifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(blueColor),
                      ),
                    )
                  : notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return _NotificationCard(
                              notification: notifications[index],
                              onTap: () {
                                setState(() {
                                  notifications[index].isRead = true;
                                });
                                _notificationService.markAsRead(notifications[index]);
                                notificationsCache.value = List.from(notifications);
                                _updateNotificationCount();
                              },
                              onDelete: () => _deleteNotification(index),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucune notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: blackColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos notifications apparaîtront ici',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final bool hasLongText = notification.text.length > 100;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: whiteColor,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          if (hasLongText) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(16),
            border: !notification.isRead
                ? Border.all(color: blueColor.withValues(alpha: 0.3), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey.shade100
                      : blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: notification.isRead ? Colors.grey.shade400 : blueColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    if (notification.titre != null && notification.titre!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          notification.titre!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: notification.isRead
                                ? Colors.grey.shade700
                                : blackColor,
                          ),
                        ),
                      ),
                    // Description
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        notification.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: notification.isRead
                              ? Colors.grey.shade600
                              : blackColor,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondChild: Text(
                        notification.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: notification.isRead
                              ? Colors.grey.shade600
                              : blackColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    // Indicateur flèche pour voir plus/moins
                    if (hasLongText)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: blueColor,
                            size: 20,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(notification.date, notification.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: blueColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String date, String time) {
    // Simplifier l'affichage
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]} à $time';
    }
    return '$date $time';
  }
}

class NotificationItem {
  final int id;
  final String? titre;
  final String text;
  final String time;
  final String date;
  bool isRead;
  bool isExpanded;
  bool send;

  NotificationItem({
    required this.id,
    this.titre,
    required this.text,
    required this.time,
    required this.date,
    this.isRead = false,
    this.isExpanded = false,
    this.send = false,
  });

  String get displayText {
    if (isExpanded || text.length <= 100) {
      return text;
    } else {
      return '${text.substring(0, 100)}...';
    }
  }
}
