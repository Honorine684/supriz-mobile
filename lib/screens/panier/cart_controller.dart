import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts/consts.dart';
import '../../models/product.dart';
import '../../services/panier_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  var cartItems = <Map<String, dynamic>>[].obs;
  final PanierService panierService = PanierService();

  CartController() {
    initialize();
  }

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> initialize() async {
    print('Initializing CartController');
    await fetchAchats();
  }

  static String _getFullImageUrl(String path) {
    const String baseUrl = '$domaineapiImage/';
    return baseUrl + path;
  }

  Future<void> fetchAchats() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token d\'authentification manquant.');
      }

      final List<dynamic> achatsData = await panierService.fetchAchats(token);
      print('Fetched achats: $achatsData');

      cartItems.value = achatsData.map((achat) {
        return {
          'product': Product(
            id: achat['product']['id'],
            title: achat['product']['title'],
            price: (achat['product']['prix_promo'] != null &&
                    achat['product']['prix_promo'] != 0)
                ? achat['product']['prix_promo'].toDouble()
                : (achat['product']['price'] as num?)?.toDouble() ?? 0.0,
            prixPromo: achat['product']['prix_promo'],
            evaluation: achat['product']['evaluation'],
            description:
                achat['product']['description'] ?? "Pas de description",
            prixLivraison: achat['product']['prixLivraison'],
            info: achat['product']['info'],
            images: [
              achat['product']['photo_main'],
              achat['product']['photo_secondary']
            ]
                .where((image) => image != null)
                .map((image) => _getFullImageUrl(image as String))
                .toList(),
            personnalisable: achat['product']['personnalisable'],
            statut: achat['product']['statut'],
            category: achat['product']['category'],
            subCategory: achat['product']['subCategory'],
            entreprise: achat['product']['entreprise'],
          ),
          'quantity': achat['quantity'],
          'achat_id': achat['achat_id'],
          'isSelected': false,
        };
      }).toList();
    } catch (e) {
      print('Error fetching achats: $e');
    }
  }

  void addToCart(Product product, int quantity, String personalisation) async {
    try {
      final response =
          await panierService.addToCart(product.id, quantity, personalisation);
      print('Add to cart response: $response');
      if (response['status']) {
        final index =
            cartItems.indexWhere((item) => item['product'] == product);
        if (index >= 0) {
          cartItems[index]['quantity'] += quantity;
        } else {
          cartItems.add({
            'product': product,
            'quantity': quantity,
            'isSelected': false,
            'achat_id': response['achat_id']
          });
        }
        update(); // Notifier les écouteurs des changements
      } else {
        print('Error adding to cart');
      }
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  void updateQuantity(Product product, int quantity, int achat_id) async {
    final index = cartItems.indexWhere((item) => item['product'] == product);
    if (index >= 0 && quantity > 0) {
      cartItems[index]['quantity'] = quantity;
      update(); // Notifier les écouteurs des changements

      String? token = await _getAuthToken();

      try {
        final response = await http.post(
          Uri.parse('$domaineapi/update-quantity'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'achat_id': achat_id,
            'qte_achat': quantity,
          }),
        );

        if (response.statusCode == 200) {
          print('Quantité mise à jour avec succès !');
          cartItems.refresh();
          update();
        } else {
          print(
              'Erreur lors de la mise à jour de la quantité : ${response.body}');
        }
      } catch (e) {
        print('Erreur de connexion : $e');
      }
    } else {
      print('Produit non trouvé dans le panier ou quantité invalide.');
    }
  }

  void removeFromCart(Product product) async {
    try {
      final index = cartItems.indexWhere((item) => item['product'] == product);
      if (index >= 0) {
        final achatId = cartItems[index]['achat_id'];

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
          cartItems.removeAt(index);
          update(); // Notifier les écouteurs des changements
        } else {
          print(
              'Erreur lors de la suppression de l\'article : ${responseBody['message']}');
        }
      } else {
        print('Produit non trouvé dans le panier.');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }

  void toggleItemSelected(int index) {
    cartItems[index]['isSelected'] = !(cartItems[index]['isSelected'] ?? false);
    update(); // Notifier les écouteurs des changements
  }

  void selectAllItems() {
    final allSelected = cartItems.every((item) => item['isSelected'] == true);
    for (var item in cartItems) {
      item['isSelected'] = !allSelected;
    }
    update(); // Notifier les écouteurs des changements
  }

  void deleteSelectedItems() async {
    List<int> selectedItemIds = cartItems
        .where((item) => item['isSelected'] == true)
        .map<int>((item) => item['achat_id'] as int)
        .toList();

    if (selectedItemIds.isEmpty) {
      print('Aucun article sélectionné');
      return;
    }

    String? token = await _getAuthToken();

    final response = await http.post(
      Uri.parse('$domaineapi/cart/remove-selected'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'selectedItemIds': selectedItemIds,
      }),
    );

    if (response.statusCode == 200) {
      cartItems.removeWhere((item) => item['isSelected'] == true);
      update(); // Notifier les écouteurs des changements
      print('Les articles sélectionnés ont été supprimés avec succès');
    } else {
      print('Erreur lors de la suppression des articles : ${response.body}');
    }
  }

  int get distinctProductCount => cartItems.length;

  double get totalAmount {
    return cartItems.fold(0.0, (sum, item) {
      final product = item['product'] as Product;

      double productPrice;

      if (product.price is String) {
        productPrice = double.tryParse((product.price as String)
                .replaceAll('.', '')
                .replaceAll(',', '.')) ??
            0.0;
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
    return cartItems.every((item) => item['isSelected'] == true);
  }
}

class CartItem extends StatelessWidget {
  final int index;
  final int quantity;
  final bool isSelected;
  final Function(int) onQuantityChanged;
  final VoidCallback onSelected;
  final VoidCallback onRemove;

  const CartItem({
    super.key,
    required this.index,
    required this.quantity,
    required this.isSelected,
    required this.onQuantityChanged,
    required this.onSelected,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final product = cartController.cartItems[index]['product'] as Product;

    return GestureDetector(
      onLongPress: onSelected,
      child: Card(
        color: isSelected ? Colors.grey.shade300 : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    product.images.first,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Row(
                          children: List.generate(4, (index) {
                            return const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14.0,
                            );
                          })
                            ..add(const Icon(
                              Icons.star_border,
                              color: Colors.orange,
                              size: 14.0,
                            )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.price.toInt()} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (quantity > 1) {
                              Get.find<CartController>()
                                  .update(); // Forcer la mise à jour de l'interface utilisateur
                              onQuantityChanged(quantity - 1);
                            }
                          },
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Get.find<CartController>()
                                .update(); // Forcer la mise à jour de l'interface utilisateur
                            onQuantityChanged(quantity + 1);
                          },
                          child: const Icon(
                            Icons.add_circle_outline,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
