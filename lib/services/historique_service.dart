import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../consts/consts.dart';

class HistoriqueService {
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
          // Parser la date ISO et formater en français
          String formattedDate = '';
          String formattedTime = '';

          try {
            final createdAt = item['created_at'];
            if (createdAt != null) {
              final dateTime = DateTime.parse(createdAt);
              formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
              formattedTime = DateFormat('HH:mm').format(dateTime);
            }
          } catch (_) {
            formattedDate = '-';
            formattedTime = '-';
          }

          return HistoriqueItem(
            text: item['description']?.toString() ?? 'Sans description',
            prix: item['prix']?.toString() ?? '0',
            code: item['code_historiques']?.toString() ?? '-',
            date: formattedDate,
            time: formattedTime,
          );
        }).toList();
      } else {
        throw Exception('Échec du chargement des historiques');
      }
    } catch (e) {
      print('Erreur historique: $e');
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
