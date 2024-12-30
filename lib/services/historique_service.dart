import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../consts/consts.dart';

class HistoriqueService {
  // Remplacez cette constante par l'URL de votre API
  static const String apiUrl = '$domaineapi/historiques';

  Future<List<HistoriqueItem>> fetchHistoriques() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return HistoriqueItem(
            text: item['description'],
            prix: item['prix'].toString(),
            code: item['code_historiques'],
            date: item['created_at'].split('T')[0], // Formatage de la date
            time: item['created_at'].split('T')[1].split('.')[0], // Formatage de l'heure
          );
        }).toList();
      } else {
        // Gérer les erreurs ici
        throw Exception('Échec du chargement des historiques');
      }
    } catch (e) {
      print('Erreur: $e');
      // Vous pouvez également afficher un message d'erreur à l'utilisateur
      throw Exception('Erreur lors de la récupération des historiques');
    }
  }
}

class HistoriqueItem {
  final String text;
  final String prix;
  final String code;
  final String date;
  final String time;

  HistoriqueItem({
    required this.text,
    required this.prix,
    required this.code,
    required this.date,
    required this.time,
  });
}
