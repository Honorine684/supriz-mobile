// lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/appbar_custom.dart';
import 'cart_item.dart';
import 'cart_provider.dart';

class PanierScreen extends StatelessWidget {
  const PanierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: "Panier"),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text('Votre panier est vide.'))
          : ListView.builder(
              itemCount: cartProvider.items.length,
              itemBuilder: (ctx, index) {
                final cartItem = cartProvider.items[index];
                final product = cartItem.product;
                return CartItem(
                  index: index,
                  quantity: cartItem
                      .quantity, // Utilisation de la quantité du produit
                  isSelected: false, // Vous pouvez gérer la sélection ici
                  onQuantityChanged: (newQuantity) {
                    // Mettez à jour la quantité ici
                    cartProvider.updateQuantity(product.id, newQuantity);
                  },
                  onSelected: () {
                    // Gérez la sélection ici
                  },
                  onRemove: () {
                    cartProvider.removeFromCart(product.id);
                  },
                );
              },
            ),
    );
  }
}
