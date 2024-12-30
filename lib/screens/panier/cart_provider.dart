import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../consts/consts.dart';
import '../../models/product.dart';
import '../../services/panier_service.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  final PanierService _panierService = PanierService();

  List<Map<String, dynamic>> get cartItems => [..._cartItems];

  int get distinctProductCount => _cartItems.length;

  Future<void> addToCart(Product product, int quantity, String personalization) async {
    try {
      final response = await _panierService.addToCart(product.id, quantity, personalization);
      if (response['status']) {
        final index = _cartItems.indexWhere((item) => item['product'] == product);
        if (index >= 0) {
          _cartItems[index]['quantity'] += quantity;
        } else {
          _cartItems.add({
            'product': product,
            'quantity': quantity,
            'isSelected': false,
            'achat_id': response['achat_id']
          });
        }
        notifyListeners();
      } else {
        throw Exception('Failed to add to cart');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout au panier: $e');
    }
  }

  Future<void> updateQuantity(Product product, int quantity, int achatId) async {
    final index = _cartItems.indexWhere((item) => item['product'] == product);
    if (index >= 0 && quantity > 0) {
      _cartItems[index]['quantity'] = quantity;
      notifyListeners();

      String? token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$domaineapi/update-quantity'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'achat_id': achatId,
          'qte_achat': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour de la quantité');
      }
    } else {
      throw Exception('Produit non trouvé dans le panier ou quantité invalide.');
    }
  }

  Future<void> removeFromCart(Product product) async {
    final index = _cartItems.indexWhere((item) => item['product'] == product);
    if (index >= 0) {
      final achatId = _cartItems[index]['achat_id'];
      String? token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('$domaineapi/remove-from-cart/delete/$achatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['status']) {
        _cartItems.removeAt(index);
        notifyListeners();
      } else {
        throw Exception('Erreur lors de la suppression de l\'article');
      }
    } else {
      throw Exception('Produit non trouvé dans le panier.');
    }
  }

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final product = item['product'] as Product;
      double productPrice;

      if (product.price is String) {
        productPrice = double.tryParse(
            (product.price as String).replaceAll('.', '').replaceAll(',', '.')
        ) ?? 0.0;
      } else if (product.price is double) {
        productPrice = product.price;
      } else {
        productPrice = 0.0;
      }

      return sum + (productPrice * (item['quantity'] as int));
    });
  }

  String get formattedTotalAmount {
    final total = totalAmount;
    return NumberFormat('#,##0.00', 'fr_FR').format(total);
  }

  bool get allItemsSelected {
    return _cartItems.every((item) => item['isSelected'] == true);
  }
}
