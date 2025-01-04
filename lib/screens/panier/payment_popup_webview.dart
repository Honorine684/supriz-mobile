import 'package:velocity_x/velocity_x.dart';
import '../../consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../home/bottom_navigation.dart';

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
              const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10),
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