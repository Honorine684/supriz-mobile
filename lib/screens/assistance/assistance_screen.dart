// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../consts/images.dart';
import '../../consts/strings.dart';
import '../../widgets/appbar_custom.dart';

const Color cloudColor = Color(0xFFE0E0E0);
const Color grayColor = Color(0xFF9E9E9E);

class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});

  @override
  _AssistanceScreenState createState() => _AssistanceScreenState();
}

class _AssistanceScreenState extends State<AssistanceScreen> {
  Future<List<dynamic>>? _faqFuture;

  @override
  void initState() {
    super.initState();
    _fetchAndUpdateFAQs(); // Récupération initiale des FAQ
  }

  void _fetchAndUpdateFAQs() {
    setState(() {
      _faqFuture = fetchFaqs();
    });
  }

  Future<List<dynamic>> fetchFaqs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token stocké : $token');

    final response = await http.get(
      Uri.parse('$domaineapi/faq'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('URL de la requête : ${Uri.parse('$domaineapi/faq')}');
    print('Réponse de l\'API : ${response.body}');

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
      throw Exception(
          'Erreur lors de la récupération des FAQ : ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Aide"),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder<List<dynamic>>(
          future: _faqFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('Chargement en cours...');
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print('Erreur : ${snapshot.error}');
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              print('Aucune FAQ disponible');
              return const Center(child: Text('Aucune FAQ disponible'));
            } else {
              print('FAQ disponibles : ${snapshot.data!.length}');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      logo,
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Comment pouvons-nous vous aider?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final faq = snapshot.data![index];
                        print('FAQ : $faq');
                        return _buildQuestionItem(
                          faq['asq'],
                          faq['response'],
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuestionItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cloudColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Q: $question',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "R: ",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    answer,
                    style: const TextStyle(
                      color: grayColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
