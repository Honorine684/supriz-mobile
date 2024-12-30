import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/consts/consts.dart';
import '../models/achat.dart';


class AchatService {
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Achat>> fetchAchats() async {
    String? token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$domaineapi/panier-product'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true) {
        final List<dynamic> detailsProduits = data['data']['detailsProduits'];
        return detailsProduits.map((json) => Achat.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load achats');
      }
    } else {
      throw Exception('Failed to load achats');
    }
  }
}
