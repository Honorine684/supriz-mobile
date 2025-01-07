import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/panier_service.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  final PanierService _panierService = PanierService();

  List<Map<String, dynamic>> get cartItems => [..._cartItems];

  int get distinctProductCount => _cartItems.length;

  Future<void> addToCart(
      Product product, int quantity, String personalization) async {
    try {
      final response =
          await _panierService.addToCart(product.id, quantity, personalization);
      if (response['status']) {
        final index =
            _cartItems.indexWhere((item) => item['product'] == product);
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
}
