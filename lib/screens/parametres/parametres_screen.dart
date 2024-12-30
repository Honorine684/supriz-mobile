// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/screens/historique/historique_screen.dart';
import 'package:supriz/screens/notifications/notifications_screen.dart';
import 'package:supriz/screens/profil/profil_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/appbar_custom.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  _ParametresScreenState createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _showingDialog = false;
  bool _isLoading = false;

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _showConfirmationDialog(
      BuildContext context, String message, Function onConfirm,
      {bool isDeleteAccount = false}) {
    setState(() {
      _showingDialog = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'bold', fontSize: 18),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showingDialog = false;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Non',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showingDialog = false;
                        });
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Text(
                        'Oui',
                        style: TextStyle(
                            fontSize: 16,
                            color: isDeleteAccount ? Colors.red : Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _showingDialog = false;
      });
    });
  }

  void _showDisconnectDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Souhaitez-vous vraiment vous déconnecter ?",
          () {
        AuthService().logoutUser(context, setLoading);
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      "Souhaitez-vous vraiment supprimer votre compte ?",
          () {
        AuthService().deleteUser(context, setLoading);
      },
      isDeleteAccount: true,
    );
  }

  Widget _buildLanguageRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: cloudColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          const Text(
            "Langue",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Image.asset(
            france,
            width: 30,
            height: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, dynamic action) {
    return GestureDetector(
      onTap: () {
        if (action is Widget) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => action,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        } else if (action is Function) {
          action();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: cloudColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double spacing = 20.0;


    /*
              onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()),
            );
          },
     */
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Paramètres"),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: spacing),
                _buildLanguageRow(context),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Notifications", NotificationScreen()),
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                    context, "Conditions Générales", CondicUtilisation()),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Politiques de Confidentialité",
                    const PolitiquesScreen()),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Historiques", HistoriquesScreen()),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Modifier mon profil", ProfilScreen()),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Supprimer mon compte",
                        () => _showDeleteAccountDialog(context)),
                SizedBox(height: spacing / 2),
                _buildInfoRow(context, "Déconnecter",
                        () => _showDisconnectDialog(context)),
                SizedBox(height: spacing / 2),
              ],
            ),
          ),
          if (_showingDialog)
            Positioned(
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          if (_isLoading)
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}


class CondicUtilisation extends StatelessWidget {
  const CondicUtilisation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(title: "Conditions Générales"),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Conditions Générales d'utilisation de SUPRIZ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Dernière mise à jour : ..........",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Bienvenue sur Supriz ! En utilisant notre application, vous acceptez les présentes conditions générales d'utilisation. Veuillez les lire attentivement.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Acceptation des Conditions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "En accédant et en utilisant l'application Supriz, vous acceptez d'être lié par les présentes conditions générales. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre application.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Utilisation de l'Application",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Supriz vous permet de :",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "- Parcourir et acheter des produits pour différentes occasions.",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "- Envoyer des souhaits et des messages pour créer des cartes de vœux personnalisées.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Comptes Utilisateurs",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Pour utiliser certaines fonctionnalités de l'application, vous devez créer un compte utilisateur. Vous êtes responsable de la confidentialité de vos informations de compte et de toutes les activités qui se produisent sous votre compte.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Commandes et Paiements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Commandes: En passant une commande sur Supriz, vous acceptez de fournir des informations exactes et complètes.",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "Paiements: Tous les paiements doivent être effectués via les méthodes de paiement disponibles sur l'application. Nous utilisons des prestataires de services tiers pour traiter les paiements.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Livraison",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Nous nous efforçons de livrer les produits dans les délais indiqués. Cependant, des retards peuvent survenir en raison de circonstances indépendantes de notre volonté. Nous ne sommes pas responsables des retards de livraison.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Propriété Intellectuelle",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Tous les contenus présents sur l'application Supriz, y compris les textes, images, logos et graphiques, sont protégés par des droits d'auteur et autres droits de propriété intellectuelle. Vous ne pouvez pas utiliser ces contenus sans notre autorisation préalable.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Limitation de Responsabilité",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Supriz ne sera pas responsable des dommages directs, indirects, accessoires, spéciaux ou consécutifs résultant de l'utilisation ou de l'incapacité à utiliser notre application. Mais nous nous engageons à vous donner quelques instructions pour son utilisation.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Modifications des Conditions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Nous nous réservons le droit de modifier ces conditions générales à tout moment. Les modifications seront effectives dès leur publication sur l'application. Il est de votre responsabilité de consulter régulièrement les conditions générales.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Loi Applicable et Juridiction",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Tout litige pouvant naître de l'exécution ou de l'interprétation du Contrat sera réglé à l'amiable.",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "A défaut d'accord, les tribunaux compétents seront ceux du ressort de la juridiction du siège social de Supriz.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              "Contact",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Si vous avez des questions sur les présentes Conditions Générales d'Utilisation, veuillez nous écrire par e-mail à l'adresse suivante : support@supriz.com",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class PolitiquesScreen extends StatelessWidget {
  const PolitiquesScreen({super.key});

  // Styles réutilisables
  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle normalStyle = TextStyle(
    fontSize: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Politique de Confidentialité"),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle("Politique de Confidentialité de Supriz"),
            SizedBox(height: 8),
            NormalText("Dernière mise à jour : ............"),
            SizedBox(height: 16),
            NormalText(
              "Chez Supriz, nous prenons la confidentialité de nos utilisateurs très au sérieux. Cette politique de confidentialité décrit comment nous collectons, utilisons, et protégeons vos informations personnelles lorsque vous utilisez notre application Supriz.",
            ),
            SizedBox(height: 16),
            Section(
              title: "Collecte des Informations",
              texts: [
                "Nous collectons les informations suivantes lorsque vous utilisez notre application :",
                "- Informations personnelles: Nom, Adresse e-mail, Numéro de téléphone, Adresse de livraison.",
                "- Informations de paiement",
                "- Informations sur les produits que vous consultez, ajoutez à votre panier ou achetez.",
                "- Messages Supriz: les souhaits et messages que vous envoyez pour créer des cartes de vœux.",
              ],
            ),
            Section(
              title: "Utilisation des Informations",
              texts: [
                "Les informations collectées sont utilisées pour :",
                "- Traiter et livrer vos commandes.",
                "- Personnaliser votre expérience sur l'application.",
                "- Créer des cartes de vœux personnalisées.",
                "- Améliorer nos services et produits.",
                "- Communiquer avec vous concernant vos commandes et nos offres.",
              ],
            ),
            Section(
              title: "Partage des Informations",
              texts: [
                "Nous ne partageons vos informations personnelles avec des tiers que dans les cas suivants :",
                "- Avec des prestataires de services tiers pour traiter les paiements et livrer les commandes.",
                "- Si requis par la loi ou pour protéger nos droits légaux.",
              ],
            ),
            Section(
              title: "Sécurité des Informations",
              texts: [
                "Nous mettons en place des mesures de sécurité pour protéger vos informations personnelles contre l'accès non autorisé, la divulgation, l'altération ou la destruction.",
              ],
            ),
            Section(
              title: "Vos Droits",
              texts: [
                "Vous avez le droit de :",
                "- Accéder à vos informations personnelles.",
                "- Demander la correction de vos informations personnelles.",
                "- Demander la suppression de vos informations personnelles.",
              ],
            ),
            Section(
              title: "Modifications de la Politique de Confidentialité",
              texts: [
                "Nous pouvons mettre à jour cette politique de confidentialité de temps en temps. Nous vous informerons de tout changement en publiant la nouvelle politique sur notre application.",
              ],
            ),
            Section(
              title: "Contact",
              texts: [
                "Pour toute question concernant cette politique de confidentialité ou pour exercer vos droits, veuillez contacter notre responsable de la protection des données :",
                "Email: ......................",
                "Téléphone: .............",
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widgets personnalisés pour simplifier le code
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class NormalText extends StatelessWidget {
  final String text;
  const NormalText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: PolitiquesScreen.normalStyle);
  }
}

class Section extends StatelessWidget {
  final String title;
  final List<String> texts;

  const Section({required this.title, required this.texts, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PolitiquesScreen.titleStyle),
        const SizedBox(height: 8),
        ...texts.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: NormalText(text),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
