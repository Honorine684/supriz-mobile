// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/widgets/appbar_custom.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
    {
      'message':
          'Lorem ipsum dolor sit amet consectetur. Ut tricies nec eu malesuada quam. Turpis tempor egestas risus libero nascetur dictum donec blandit.',
      'date': '11/05/2024',
      'time': '11:30'
    },
  ];

  bool isLoading = true;
  late List<bool> expandedList;

  @override
  void initState() {
    super.initState();
    expandedList = List<bool>.filled(notifications.length, false);
    // Simulate loading
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Notifications"),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: blueColor))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isExpanded = expandedList[index];
                  final message = notification['message']!;
                  final truncatedMessage = message.length > 100
                      ? '${message.substring(0, 100)}...'
                      : message;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white,
                    child: ExpansionTile(
                      leading: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: blueColor,
                            child: Icon(Icons.notifications_outlined, color: Colors.white),
                          ),
                          Text(notification['time']!),
                        ],
                      ),
                      title: Text(
                        isExpanded ? message : truncatedMessage,
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: Column(
                        children: [
                          Icon(Icons.more_horiz, color: blueColor,),
                          SizedBox(height: 4),
                          Text(notification['date']!),
                        ],
                      ),
                      onExpansionChanged: (value) {
                        setState(() {
                          expandedList[index] = value;
                        });
                      },
                      initiallyExpanded: isExpanded,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

