// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/widgets/appbar_custom.dart';

import '../../widgets/our_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Liste des notifications à afficher
  final List<Map<String, String>> notifications = [
    {
      'message':
      'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
    {
      'message':
      'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
    {
      'message':
      'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
    {
      'message':
      'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
    {
      'message':
      'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
  ];

  bool allRead = false;

  void markAllAsRead() {
    setState(() {
      allRead = true;
    });
  }

  void deleteAll() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Notifications"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: ourButton(
                        text: 'Tout marquer comme lu',
                        fontSize: 14,
                        backgroundColor: roscColor,
                        textColor: blackColor,
                        fontWeight: FontWeight.normal,
                        onPressed: markAllAsRead,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: ourButton(
                        text: 'Tout supprimer',
                        fontSize: 14,
                        backgroundColor: roscColor,
                        textColor: blackColor,
                        fontWeight: FontWeight.normal,
                        onPressed: deleteAll,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: notifications.isEmpty
                ? Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(seconds: 2),
                child: Text(
                  'Aucune notification',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            )
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Dismissible(
                  // Utilisation de UniqueKey pour chaque Dismissible
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    // Supprimer la notification de la liste
                    setState(() {
                      if (index < notifications.length) {
                        notifications.removeAt(index);
                      }
                    });
                  },
                  // Ajout de confirmDismiss pour confirmer la suppression
                  confirmDismiss: (DismissDirection direction) async {
                    return true;
                  },
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Column(
                        children: [
                          const CircleAvatar(
                            backgroundColor: blueColor,
                            child: Icon(Icons.notifications_outlined,
                                color: whiteColor),
                          ),
                          Text(notification['time']!,
                              style: const TextStyle(fontSize: 10.0)),
                        ],
                      ),
                      title: Text(notification['message']!,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        children: [
                          allRead
                              ? const Icon(Icons.check,
                              color: Colors.green)
                              : const Icon(Icons.more_horiz),
                          SizedBox(height: 4),
                          Text(notification['date']!),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
