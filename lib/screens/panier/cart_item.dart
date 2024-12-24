// lib/widgets/cart_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_provider.dart';

class CartItem extends StatelessWidget {
  final int index;
  final int quantity;
  final bool isSelected;
  final Function(int) onQuantityChanged;
  final VoidCallback onSelected;
  final VoidCallback onRemove;

  const CartItem({super.key,
    required this.index,
    required this.quantity,
    required this.isSelected,
    required this.onQuantityChanged,
    required this.onSelected,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final product = cartProvider.items[index].product;

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
                      '${product.price} FCFA',
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
