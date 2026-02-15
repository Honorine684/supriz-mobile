import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/consts/consts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PanierService {
  final List<Map<String, dynamic>> _cartItems = [];

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance(); // Récupération des préférences
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> addToCart(int productId, int quantity, String description) async {
    String? token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$domaineapi/ajouter-au-panier'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Utilisation du token d'authentification
      },
      body: jsonEncode(<String, dynamic>{
        'product_id': productId,
        'qte_achat': quantity,
        'description_de_personnalisation': description,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add to cart');
    }
  }

  Future<Map<String, dynamic>> removeFromCart(int achatId) async {
    String? token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$domaineapi/remove-from-cart'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Utilisation du token d'authentification
      },
      body: jsonEncode(<String, dynamic>{
        'achat_id': achatId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to remove from cart');
    }
  }

  Future<Map<String, dynamic>> updateNumeroBeneficier(String beneficierNuber) async {
    String? token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$domaineapi/numero-beneficiere'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Utilisation du token d'authentification
      },
      body: jsonEncode(<String, dynamic>{
        'numero_beneficiere': beneficierNuber,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to remove from cart');
    }
  }

  Future<List<dynamic>> fetchAchats(String token) async {
    print('Fetching achats with token: $token');
    final url = Uri.parse('$domaineapi/panier-product');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token', // Ajouter le token d'authentification
      });

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        // Décoder la réponse JSON
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load achats');
      }
    } catch (e) {
      print('Error fetching achats: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  Future<bool> updateBeneficiaryNumber(String numeroBeneficier,String selectedOption) async {
    String? token = await _getAuthToken();

    final response = await http.post(
      Uri.parse('$domaineapi/numero-beneficiere'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'numero_beneficier': numeroBeneficier,
        'selectedOption':selectedOption
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
