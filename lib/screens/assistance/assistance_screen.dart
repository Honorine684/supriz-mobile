// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../../consts/consts.dart';
import '../../widgets/appbar_custom.dart';

class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});

  @override
  State<AssistanceScreen> createState() => _AssistanceScreenState();
}

class _AssistanceScreenState extends State<AssistanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Aide"),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
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
                'Comment pouvons nous vous aidez?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _buildQuestionItem(
                    'Quelle est le but de l’application?',
                    'Cette application vise à faciliter la tâche aux utilisateurs de vite trouver un cadeau pour un proche ou pour soi-même.',
                  ),
                  _buildQuestionItem(
                    'Comment puis-je créer un compte?',
                    "Pour créer un compte, cliquez sur le bouton d'inscription et suivez les instructions.",
                  ),
                  _buildQuestionItem(
                    'Quelle est le but de l’application?',
                    'Cette application vise à faciliter la tâche aux utilisateurs de vite trouver un cadeau pour un proche ou pour soi-même.',
                  ),
                  _buildQuestionItem(
                    'Comment puis-je créer un compte?',
                    "Pour créer un compte, cliquez sur le bouton d'inscription et suivez les instructions.",
                  ),
                  _buildQuestionItem(
                    'Quelle est le but de l’application?',
                    'Cette application vise à faciliter la tâche aux utilisateurs de vite trouver un cadeau pour un proche ou pour soi-même.',
                  ),
                  _buildQuestionItem(
                    'Comment puis-je créer un compte?',
                    "Pour créer un compte, cliquez sur le bouton d'inscription et suivez les instructions.",
                  ),
                ],
              ),
            ),
          ],
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
