import 'dart:convert';
import 'package:http/http.dart' as http;
import '../consts/strings.dart'; // Assure-toi que ce fichier contient la variable `domaineapi`
import '../models/publicite.dart';

class PubliciteService {
  PubliciteService();

  Future<List<Publicite>> fetchPublicites() async {
    final response = await http.get(Uri.parse('$domaineapi/publicites'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((publicite) => Publicite.fromJson(publicite, domaineapi)).toList();
    } else {
      throw Exception('Failed to load publicites');
    }
  }
}
