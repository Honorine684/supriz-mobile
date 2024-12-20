// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import '../../widgets/appbar_custom.dart';
import '../assistance/assistance_screen.dart';

class SurprizScreen extends StatefulWidget {
  const SurprizScreen({super.key});

  @override
  State<SurprizScreen> createState() => _SurprizScreenState();
}

class _SurprizScreenState extends State<SurprizScreen> {
  final List<String> images = [s1, s2, s3, s4, s5];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: 'Message Supriz'),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset(logo, height: 50)),
            const SizedBox(height: 10),
            const Text(
              "Exprimer vos voeux, souhaits, et remerciements à vos proches avec élégance et authenticité pour diverses occasions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: "Roboto-Regular", fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            // Bouton suivant et Images en format Gridview lorsque le page surpiz sera disponible
            /*
            ourButton(
              onPress: () => Get.to(() => const sSupriz()),
              color: vertpan,
              textColor: whiteColor,
              title: "Suivant",
            ).box.width(double.infinity).make(),
            const SizedBox(height: 15),

            Expanded(
              child: MasonryGridView.builder(
                gridDelegate:
                const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final bool isSmall = index % 2 == 0;
                  final double height = isSmall ? 197 : 310;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(images[index],
                        height: height, width: 170, fit: BoxFit.cover),
                  );
                },
              ),
            ),


            // Bouton et Afficher une seule image qui occupe tout l'espace restant
            ourButton(
              onPress: () => Get.to(() => const CommingSoon()),
              color: vertpan,
              textColor: whiteColor,
              text: "Suivant",
            ).box.width(double.infinity).make(),

             */
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  bgimg,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: blueColor,
        foregroundColor: whiteColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AssistanceScreen()),
          );
        },
        child: const Icon(Icons.support_agent_outlined, size: 35),
      ),
    );
  }
}

class CommingSoon extends StatelessWidget {
  const CommingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Message Supriz'),
      body: Center(
        child: Image.asset(
          comingsoon,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

/*
class sSupriz extends StatefulWidget {
  const sSupriz({super.key});

  @override
  State<sSupriz> createState() => _sSuprizState();
}

class _sSuprizState extends State<sSupriz> {
  final _formKey = GlobalKey<FormState>();
  String? _occasion;
  String? _recipientName;
  String? _additionalInfo;
  String? _whatsappNumber;

  String _selectedPaymentMethod = '';

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(selectedMethod: _selectedPaymentMethod),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.05,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentOption(mtn, 'Mobile Money'),
                    _buildPaymentOption(moov, 'Moov Money'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentOption(celtis, 'Celtis Cash'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre moyen de paiement',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String method, String title) {
    return GestureDetector(
      onTap: () {
        _selectPaymentMethod(method);
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              method,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: AppBar(
          flexibleSpace: Image.asset(appbarImg, fit: BoxFit.cover),
          title:
          const Text('Message Supriz', style: TextStyle(color: whiteColor)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            color: whiteColor,
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset(logo, height: 50)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        hintText: 'Occasion', border: OutlineInputBorder()),
                    items: [
                      'Anniversaire',
                      'Carte de voeux',
                      'Mariage',
                      'Soutenance',
                      'Célébration',
                    ]
                        .map((String value) => DropdownMenuItem<String>(
                      value: value, child: Text(value),),)
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => _occasion = value),
                    validator: (value) => value == null
                        ? 'Veuillez sélectionner une occasion'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(
                        hintText: "Nom et prénoms du destinataire",
                        border: OutlineInputBorder()),
                    onChanged: (value) =>
                        setState(() => _recipientName = value),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Veuillez entrer le nom du destinataire'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                        hintText: "Entrer votre souhait...",
                        border: OutlineInputBorder()),
                    onChanged: (value) =>
                        setState(() => _additionalInfo = value),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(
                            color: Colors.green, FontAwesomeIcons.whatsapp),
                        hintText: "Entrez votre numéro WhatsApp",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) =>
                        setState(() => _whatsappNumber = value),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Veuillez entrer votre numéro WhatsApp'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prix :',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('1500 FCFA',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ourButton(
                    onPress: _showPaymentDialog,
                    color: vertpan,
                    textColor: whiteColor,
                    title: "Acheter",
                  ).box.width(double.infinity).make(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 */
