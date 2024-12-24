// lib/providers/cart_provider.dart

import 'package:flutter/material.dart';
import '../../models/product.dart';

class CartProductItem {
  final Product product;
  int quantity;

  CartProductItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartProductItem> _items = [];

  List<CartProductItem> get items => _items;

  int get distinctProductCount => _items.length;

  void addToCart(Product product, int quantity) {
    final existingItemIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += quantity;
    } else {
      _items.add(CartProductItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    final existingItemIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity = newQuantity;
      notifyListeners();
    }
  }
}
