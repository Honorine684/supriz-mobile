// ignore_for_file: prefer_const_constructors

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';

class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});

  @override
  State<AssistanceScreen> createState() => _AssistanceScreenState();
}

class _AssistanceScreenState extends State<AssistanceScreen> {
  Future<List<dynamic>>? _faqFuture;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _faqFuture = fetchFaqs();
  }

  Future<List<dynamic>> fetchFaqs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$domaineapi/faq'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        return data['faq'];
      } else {
        throw Exception('Aucune FAQ trouvée');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentification requise');
    } else {
      throw Exception('Erreur lors de la récupération des FAQ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Aide"),
      body: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Logo
                    Image.asset(logo, height: 50),
                    SizedBox(height: 16),
                    // Titre
                    Text(
                      'Comment pouvons-nous vous aider?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    // FAQ accordéon
                    FutureBuilder<List<dynamic>>(
                      future: _faqFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: blueColor),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: greyColor, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'Impossible de charger les FAQ',
                                    style: TextStyle(color: greyColor),
                                  ),
                                  SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _faqFuture = fetchFaqs();
                                      });
                                    },
                                    child: Text('Réessayer', style: TextStyle(color: blueColor)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text(
                                'Aucune FAQ disponible',
                                style: TextStyle(color: greyColor),
                              ),
                            ),
                          );
                        } else {
                          return Column(
                            children: snapshot.data!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final faq = entry.value;
                              return _buildFaqItem(
                                index: index,
                                question: faq['asq'] ?? '',
                                answer: faq['response'] ?? '',
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    // Contact support
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: blueColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.support_agent, color: blueColor, size: 40),
                          SizedBox(height: 12),
                          Text(
                            "Besoin d'aide supplémentaire?",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: blackColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Contactez notre équipe de support",
                            style: TextStyle(
                              fontSize: 14,
                              color: greyColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Ouvrir WhatsApp ou email
                            },
                            icon: Icon(Icons.chat, size: 18),
                            label: Text('Nous contacter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueColor,
                              foregroundColor: whiteColor,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
    );
  }

  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? blueColor : greyColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: blueColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Q${index + 1}',
                            style: TextStyle(
                              color: blueColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      AnimatedRotation(
                        duration: Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: blueColor,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: SizedBox.shrink(),
                    secondChild: Padding(
                      padding: EdgeInsets.only(top: 12, left: 44),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: roscColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'R: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: blueColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                answer,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: blackColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
