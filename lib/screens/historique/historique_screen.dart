import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/services/historique_service.dart';
import 'package:supriz/widgets/appbar_custom.dart';

class HistoriquesScreen extends StatefulWidget {
  const HistoriquesScreen({super.key});

  @override
  _HistoriquesScreenState createState() => _HistoriquesScreenState();
}

class _HistoriquesScreenState extends State<HistoriquesScreen> {
  List<HistoriqueItem> historiques = [];
  bool isLoading = true; // Indicateur de chargement

  @override
  void initState() {
    super.initState();
    fetchHistoriques();
  }

  Future<void> fetchHistoriques() async {
    try {
      final service = HistoriqueService();
      final data = await service.fetchHistoriques();
      setState(() {
        historiques = data;
        isLoading = false; // Fin du chargement
      });
    } catch (e) {
      print('Erreur: $e');
      // Vous pouvez également afficher un message d'erreur à l'utilisateur
      setState(() {
        isLoading = false; // Fin du chargement même en cas d'erreur
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Historiques"),
      body: Column(
        children: [
          Expanded(
            child: isLoading // Vérifie si le chargement est en cours
                ? const Center(
              child: CircularProgressIndicator(), // Cercle de chargement
            )
                : historiques.isEmpty // Vérifie s'il n'y a pas d'historiques
                ? const Center(
              child: Text(
                'Aucun Historique',
                style: TextStyle(fontSize: 25, color: blueColor),
              ),
            )
                : ListView.builder(
              itemCount: historiques.length,
              itemBuilder: (context, index) {
                return HistoriqueWidget(
                  historique: historiques[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HistoriqueWidget extends StatelessWidget {
  final HistoriqueItem historique;

  const HistoriqueWidget({super.key, required this.historique});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            historique.text,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8.0),
          Text(
            "Prix total : ${historique.prix} FCFA",
            style: const TextStyle(
                color: blueColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            "Code : ${historique.code}",
            style: const TextStyle(
                color: blueColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                historique.time,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Text(
                historique.date,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
