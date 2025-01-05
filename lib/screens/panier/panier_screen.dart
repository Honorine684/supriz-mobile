import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supriz/screens/panier/payment_screen.dart';
import 'package:supriz/widgets/appbar_custom.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../consts/consts.dart';
import 'package:supriz/models/product.dart';
import 'package:flutter/material.dart';
import '../../services/panier_service.dart';
import '../../widgets/our_button.dart';
import 'cart_controller.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  @override
  void initState() {
    super.initState();
    cartController.initialize();
  }

  final CartController cartController = Get.find<CartController>();

  String _selectedPaymentMethod = '';

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PaymentPage(selectedMethod: _selectedPaymentMethod),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption(String method, String title) {
    return GestureDetector(
      onTap: () {
        _selectPaymentMethod(method);
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              method,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Panier"),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return const Center(
            child: Text('Votre panier est vide'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cartController.selectAllItems();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: roscColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Obx(() => Text(
                          cartController.allItemsSelected
                              ? 'Tout désélectionner'
                              : 'Tout sélectionner',
                        )),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 30,
                    onPressed: cartController.deleteSelectedItems,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cartController.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartController.cartItems[index];
                  final product = cartItem['product'] as Product;
                  final quantity = cartItem['quantity'] as int;
                  final achat_id = cartItem['achat_id'] as int;

                  return CartItem(
                    index: index,
                    quantity: quantity,
                    isSelected: cartItem['isSelected'] ?? false,
                    onQuantityChanged: (newQuantity) {
                      cartController.updateQuantity(
                          product, newQuantity, achat_id);
                    },
                    onSelected: () {
                      cartController.toggleItemSelected(index);
                    },
                    onRemove: () {
                      cartController.removeFromCart(product);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 40, top: 10),
        color: whiteColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre de produits',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Prix Total',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 6,
              child: Divider(
                color: blueColor,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Center(
                    child: Obx(() {
                      int totalQuantity = cartController.cartItems.fold(
                          0, (sum, item) => sum + (item['quantity'] as int));
                      return Text(
                        totalQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // pour s'assurer que le texte ne dépasse pas
                      );
                    }),
                  ),
                ),
                Obx(() {
                  return Text(
                    '${cartController.formattedTotalAmount} FCFA',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // pour couper le texte si trop long
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (cartController.cartItems.isEmpty) {
                return ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: vertpan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Commander'),
                      SizedBox(width: 8.0),
                      Icon(Icons.credit_card),
                    ],
                  ),
                );
              } else {
                return ElevatedButton(
                  onPressed: () {
                    showOrderDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: vertpan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Commander'),
                      SizedBox(width: 8.0),
                      Icon(Icons.credit_card),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  void showOrderDialog(BuildContext context) {
    final fraisLivraison = cartController.cartItems.fold<int>(
      0,
      (sum, item) =>
          sum + ((item['product'].prixLivraison as num).round()).toInt(),
    );

    String selectedOption = 'Moi même';
    final TextEditingController myNumberController = TextEditingController();
    final TextEditingController beneficiaryNumberController =
        TextEditingController();

    String? errorMessage; // Variable pour stocker les messages d'erreur

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 2.0,
            ),
          ),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Padding(
                  padding: const EdgeInsets.all(26.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Livraison",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Moi même'),
                          Radio<String>(
                            value: 'Moi même',
                            groupValue: selectedOption,
                            activeColor: blueColor,
                            onChanged: (value) {
                              setState(() {
                                selectedOption = value!;
                                errorMessage =
                                    null; // Réinitialiser le message d'erreur
                              });
                            },
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Image.asset(
                                benin,
                                width: 24,
                                height: 24,
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: myNumberController,
                                  enabled: selectedOption == 'Moi même',
                                  keyboardType: TextInputType.number,
                                  maxLength: 8,
                                  decoration: InputDecoration(
                                    prefixText: '+229 ',
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bénéficiaire'),
                          Radio<String>(
                            value: 'Bénéficiaire',
                            groupValue: selectedOption,
                            activeColor: blueColor,
                            onChanged: (value) {
                              setState(() {
                                selectedOption = value!;
                                errorMessage =
                                    null; // Réinitialiser le message d'erreur
                              });
                            },
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Image.asset(
                                benin,
                                width: 24,
                                height: 24,
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: beneficiaryNumberController,
                                  enabled: selectedOption == 'Bénéficiaire',
                                  keyboardType: TextInputType.number,
                                  maxLength: 8,
                                  decoration: InputDecoration(
                                    prefixText: '+229 ',
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Frais de livraison',
                            style: TextStyle(color: blueColor),
                          ),
                          Text('$fraisLivraison FCFA'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ourButton(
                        onPressed: () async {
                          setState(() {
                            if (selectedOption == 'Moi même' &&
                                myNumberController.text.isEmpty) {
                              errorMessage = 'Veuillez entrer votre numéro.';
                            } else if (selectedOption == 'Bénéficiaire' &&
                                beneficiaryNumberController.text.isEmpty) {
                              errorMessage =
                                  'Veuillez entrer le numéro du bénéficiaire.';
                            } else {
                              errorMessage = null;
                            }
                          });

                          if (errorMessage == null) {
                            final panierService = PanierService();

                            final numeroBeneficier =
                                selectedOption == 'Bénéficiaire'
                                    ? beneficiaryNumberController.text
                                    : myNumberController.text;

                            final success =
                                await panierService.updateBeneficiaryNumber(
                                    numeroBeneficier, selectedOption);

                            if (success) {
                              showPaymentDialog(context);
                            } else {
                              setState(() {
                                errorMessage =
                                    'Erreur lors de la mise à jour du numéro du bénéficiaire.';
                              });
                            }
                          }
                        },
                        backgroundColor: vertpan,
                        textColor: whiteColor,
                        text: "Valider",
                      ).box.width(double.infinity).make(),
                      const SizedBox(height: 16),
                      const Text(
                        "Livraison valable pour les zones de : (Cotonou,Akpakpa,Calavi,Hevié)",
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentOption(mtn, 'Mobile Money'),
                    _buildPaymentOption(moov, 'Moov Money'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentOption(celtis, 'Celtis Cash'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre moyen de paiement',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
