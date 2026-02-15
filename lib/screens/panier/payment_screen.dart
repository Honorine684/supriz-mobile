// ignore_for_file: prefer_const_constructors

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/screens/panier/payment_popup_webview.dart';
import 'package:supriz/widgets/appbar_custom.dart';
import '../../consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_controller.dart';

class PaymentPage extends StatefulWidget {
  final String selectedMethod;
  const PaymentPage({super.key, required this.selectedMethod});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<http.Response> _makeRequest(
      Uri uri, Map<String, String> headers, String body) async {
    http.Response response = await http.post(uri, headers: headers, body: body);

    // Vérifiez si la réponse est une redirection
    if (response.statusCode == 302) {
      String location = response.headers['location']!;
      return await _makeRequest(Uri.parse(location), headers, body);
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final deliveryFee = cartController.cartItems.fold<int>(
      0,
      (sum, item) =>
          sum + ((item['product'].prixLivraison as num).round()).toInt(),
    );
    final double totalAmount = cartController.totalAmount + deliveryFee;
    final TextEditingController paiementNumberController =
        TextEditingController();

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Paiement"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPaymentOption(mtn, 'Mobile Money'),
                  _buildPaymentOption(moov, 'Moov Money'),
                  _buildPaymentOption(celtis, 'Celtis Cash'),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Prix d'achat",
                      style: TextStyle(
                          fontSize: 16,
                          color: blueColor,
                          fontWeight: FontWeight.bold)),
                  Text('${cartController.totalAmount.toInt()} FCFA',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Frais de livraison",
                      style: TextStyle(
                          fontSize: 16,
                          color: blueColor,
                          fontWeight: FontWeight.bold)),
                  Text("$deliveryFee FCFA",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant total',
                    style: TextStyle(
                      fontSize: 16,
                      color: blueColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${totalAmount.toInt()} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: paiementNumberController,
                keyboardType: TextInputType.number,
                cursorColor: blueColor, // Couleur du curseur
                maxLength: 8,
                enabled: !_isLoading, // Désactive le champ de saisie pendant le chargement
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isLoading ? Colors.grey : blueColor, // Change la couleur de la bordure
                    ),
                  ),
                  hintText: 'Entrer le numéro de paiement',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0), // Ajustez le padding selon vos besoins
                    child: Text(
                      "🇧🇯", // Drapeau du Bénin
                      style: const TextStyle(fontSize: 20), // Taille ajustée
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isLoading ? Colors.grey : blueColor, // Change la couleur de la bordure
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey, // Change la couleur de la bordure
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: _isLoading ? Colors.grey : Colors.black, // Change la couleur du texte
                  ),
                ),
              ),
              const SizedBox(height: 15),
// Bouton pour lancer le décaissement et afficher la WebView dans un Dialog
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (paiementNumberController.text.isEmpty ||
                      paiementNumberController.text.length != 8) {
                    _showErrorDialog(context,
                        'Veuillez entrer un numéro de paiement valide.');
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final firstname = prefs.getString('name');
                  final email = prefs.getString('email');

                  final response = await _makeRequest(
                    Uri.parse('$domaineapi/create-transaction'),
                    {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    jsonEncode({
                      'amount': totalAmount.toInt(),
                      'currency': 'XOF',
                      'name': firstname,
                      'email': email,
                      'phone_number':
                      '+229${paiementNumberController.text}',
                      'phone_number_country': 'bj',
                    }),
                  );

                  setState(() {
                    _isLoading = false;
                  });

                  if (response.statusCode == 200) {
                    final responseData = jsonDecode(response.body);
                    final transactionUrl =
                    responseData['transaction_url']['url'];
                    final code = responseData['code'];
                    print('Transaction URL: $transactionUrl');

                    // Afficher la WebView dans un Dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PaymentPopupWebView(
                            url: transactionUrl, code: code);
                      },
                    );
                  } else {
                    _showErrorDialog(context,
                        'Erreur lors du décaissement. Veuillez réessayer.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Lancer le décaissement'),
              ),
              const SizedBox(height: 24),
              const Text(
                '1. Assurez-vous que votre numéro est correct et suffisamment approvisionné avec le montant total.',
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Lancer le décaissement en appuyant sur le bouton.',
              ),
              const SizedBox(height: 8),
              const Text(
                '3. Lorsque vous y êtes invité, confirmez le dépôt en entrant votre PIN.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, String title) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: widget.selectedMethod == method
                  ? vertpan
                  : Colors.grey.shade300,
              width: 3.0,
            ),
          ),
          padding: const EdgeInsets.all(5.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              method,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
