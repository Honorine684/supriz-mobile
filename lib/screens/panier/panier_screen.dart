import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/widgets/appbar_custom.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../consts/consts.dart';
import 'package:supriz/models/product.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/panier_service.dart';
import '../../widgets/our_button.dart';
import '../home/bottom_navigation.dart';
import 'cart_controller.dart';

class PaymentPopupWebView extends StatelessWidget {
  final String url;
  final String code;

  PaymentPopupWebView({required this.url, required this.code});

  void _showPaymentSuccessDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Désactive le bouton retour
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            check, // Assurez-vous que l'image existe
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Paiement effectué",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text("Code : $code"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: vertpan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Terminer'),
                  ).box.width(double.infinity).make(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        chat,
                        height: 80,
                        width: 80,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Merci d'avoir choisi Supriz pour vos achats !",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "L'équipe Supriz vous contactera pour discuter des détails de la livraison.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Gardez bien le code de livraison pour confirmer la réception.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Merci pour votre confiance !",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const BottomNavigation()), // Page d'accueil après confirmation
                        (Route<dynamic> route) => false,
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: vertpan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Compris'),
                ).box.width(double.infinity).make(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contrôleur WebView
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            if (url.contains("$domaineapi/paiement/success")) {
              // Remplacez par l'URL de succès
              Navigator.of(context).pop(); // Fermez le popup
              _showPaymentSuccessDialog(
                  context, code); // Montrez le message de succès
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('Error: ${error.description}');
            // Affichage d'un message à l'utilisateur en cas d'erreur
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erreur lors du chargement de la page. Veuillez réessayer.')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [blueColor, Colors.indigo],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le popup
                    },
                  ),
                  Text(
                    'Paiement sécurisé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 48), // Espace pour équilibrer la mise en page
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

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
          sum +
          ((item['product'].prixLivraison as num).round() * item['quantity'])
              .toInt(),
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
                      // Ajouter le titre "Livraison" en gras
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

                      // Ajouter le texte de zone de livraison
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


class PaymentPage extends StatelessWidget {
  final String selectedMethod;
  const PaymentPage({super.key, required this.selectedMethod});

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<http.Response> _makeRequest(Uri uri, Map<String, String> headers, String body) async {
    http.Response response = await http.post(uri, headers: headers, body: body);

    // Vérifiez si la réponse est une redirection
    if (response.statusCode == 302) {
      String location = response.headers['location']!;
      return await _makeRequest(Uri.parse(location), headers, body);
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final deliveryFee = cartController.cartItems.fold<int>(
      0,
          (sum, item) =>
      sum +
          ((item['product'].prixLivraison as num).round() * item['quantity'])
              .toInt(),
    );
    final double totalAmount = cartController.totalAmount + deliveryFee;
    final TextEditingController paiementNumberController =
    TextEditingController();

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Paiement"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPaymentOption(mtn, 'Mobile Money'),
                  _buildPaymentOption(moov, 'Moov Money'),
                  _buildPaymentOption(celtis, 'Celtis Cash'),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Prix d'achat",
                      style: TextStyle(
                          fontSize: 16,
                          color: blueColor,
                          fontWeight: FontWeight.bold)),
                  Text('${cartController.totalAmount} FCFA',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Frais de livraison",
                      style: TextStyle(
                          fontSize: 16,
                          color: blueColor,
                          fontWeight: FontWeight.bold)),
                  Text("$deliveryFee FCFA",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant total',
                    style: TextStyle(
                      fontSize: 16,
                      color: blueColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalAmount FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: paiementNumberController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  hintText: 'Entrer le numéro de paiement',
                ),
              ),
              const SizedBox(height: 15),
              // Bouton pour lancer le décaissement et afficher la WebView dans un Dialog
              ElevatedButton(
                onPressed: () async {
                  if (paiementNumberController.text.isEmpty ||
                      paiementNumberController.text.length != 8) {
                    _showErrorDialog(context,
                        'Veuillez entrer un numéro de paiement valide.');
                    return;
                  }

                  final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  final token = prefs.getString('token');
                  final firstname = prefs.getString('name');
                  final email = prefs.getString('email');

                  final response = await _makeRequest(
                    Uri.parse('$domaineapi/create-transaction'),
                    {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    jsonEncode({
                      'amount': totalAmount.toInt(),
                      'currency': 'XOF',
                      'name': firstname,
                      'email': email,
                      'phone_number': '+229${paiementNumberController.text}',
                      'phone_number_country': 'bj',
                    }),
                  );

                  if (response.statusCode == 200) {
                    final responseData = jsonDecode(response.body);
                    final transactionUrl =
                    responseData['transaction_url']['url'];
                    final code = responseData['code'];
                    print('Transaction URL: $transactionUrl');

                    // Afficher la WebView dans un Dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PaymentPopupWebView(
                            url: transactionUrl, code: code);
                      },
                    );
                  } else {
                    _showErrorDialog(context,
                        'Erreur lors du décaissement. Veuillez réessayer.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lancer le décaissement'),
              ).box.width(double.infinity).make(),

              const SizedBox(height: 24),
              const Text(
                '1. Assurez-vous que votre numéro est correct et suffisamment approvisionné avec le montant total.',
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Lancer le décaissement en appuyant sur le bouton.',
              ),
              const SizedBox(height: 8),
              const Text(
                '3. Lorsque vous y êtes invité, confirmez le dépôt en entrant votre PIN.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, String title) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: selectedMethod == method ? vertpan : Colors.grey.shade300,
              width: 3.0,
            ),
          ),
          padding: const EdgeInsets.all(5.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              method,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}


