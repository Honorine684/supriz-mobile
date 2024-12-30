// notification_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supriz/consts/consts.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../services/notification_service.dart';
import '../../widgets/appbar_custom.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initializeNotifications();
    fetchNotifications();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    List<NotificationItem> fetchedNotifications = await _notificationService.fetchNotifications();
    setState(() {
      notifications = fetchedNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Notifications"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 16.0, left: 10.0, right: 10.0, bottom: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ourButton(
                  onPress: () async {
                    await _notificationService.markAllAsRead();
                    setState(() {
                      notifications.forEach((notification) {
                        notification.isRead = true;
                      });
                    });
                  },
                  color: roscColor,
                  textColor: blackColor,
                  title: 'Tout marqué comme lu',
                ).box.height(35).make(),
                ourButton(
                  onPress: () async {
                    await _notificationService.deleteAllNotifications();
                    setState(() {
                      notifications.clear();
                    });
                  },
                  color: roscColor,
                  textColor: blackColor,
                  title: 'Tout effacé',
                ).box.height(35).make(),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
              child: Text(
                'Aucune notification',
                style: TextStyle(fontSize: 15),
              ),
            )
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationWidget(
                  notification: notifications[index],
                  onTap: () {
                    setState(() {
                      notifications[index].isExpanded =
                      !notifications[index].isExpanded;
                    });
                    _notificationService.markAsRead(notifications[index]);
                  },
                  onDelete: () async {
                    await _notificationService.deleteNotification(notifications[index]);
                    setState(() {
                      notifications.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final int id;
  final String text;
  final String time;
  final String date;
  bool isRead;
  bool isExpanded;
  bool send;

  NotificationItem({
    required this.id,
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

class NotificationWidget extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: notification.isRead ? Colors.white : Colors.grey[200],
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Column(
                children: [
                  const CircleAvatar(
                    backgroundColor: blueColor,
                    child:
                    Icon(Icons.notifications_outlined, color: whiteColor),
                  ),
                  const SizedBox(height: 10.0),
                  Text(notification.time,
                      style: const TextStyle(fontSize: 10.0)),
                ],
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  notification.displayText,
                  style: const TextStyle(fontSize: 13.0),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showPopupMenu(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4.0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_horiz, size: 20.0),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(notification.date,
                      style: const TextStyle(fontSize: 10.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Supprimer'),
                onTap: () {
                  onDelete();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget ourButton({
  required VoidCallback onPress,
  required Color color,
  required Color textColor,
  required String title,
  double borderRadius = 8.0,
  IconData? icon,
}) {
  return ElevatedButton(
    onPressed: onPress,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.all(7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, color: textColor),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ],
    ),
  );
}
