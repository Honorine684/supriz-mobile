// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supriz/consts/consts.dart';
import 'package:supriz/screens/historique/historique_screen.dart';
import 'package:supriz/screens/notifications/notifications_screen.dart';
import 'package:supriz/screens/profil/profil_screen.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/toast_notification.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  _ParametresScreenState createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _showingDialog = false;
  bool _isLoading = false;
  String _cacheSize = 'Calcul...';

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheService.getCacheSize();
    if (mounted) {
      setState(() => _cacheSize = size);
    }
  }

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

  void _showCacheDialog(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final details = await CacheService.getCacheDetails();

    if (!mounted) return;

    showModalBottomSheet(
      context: this.context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: greyColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Gestion du cache',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Libérez de l\'espace en vidant le cache de l\'application.',
                  style: TextStyle(color: greyColor, fontSize: 14),
                ),
                SizedBox(height: 24),

                // Détails du cache
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cloudColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildCacheDetailRow('Images en cache', details['cache'] ?? '0 B'),
                      Divider(height: 20),
                      _buildCacheDetailRow('Fichiers temporaires', details['temp'] ?? '0 B'),
                      Divider(height: 20),
                      _buildCacheDetailRow('Total', details['total'] ?? '0 B', isTotal: true),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Bouton vider le cache
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final success = await CacheService.clearAllCache();

                      if (mounted) {
                        setState(() => _isLoading = false);
                        await _loadCacheSize();

                        if (success) {
                          ToastNotification.success(context, 'Cache vidé avec succès');
                        } else {
                          ToastNotification.error(context, 'Impossible de vider le cache. Veuillez réessayer.');
                        }
                      }
                    },
                    icon: Icon(Icons.delete_sweep, color: whiteColor),
                    label: Text('Vider tout le cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: whiteColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Bouton vider uniquement les images
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final success = await CacheService.clearImageCache();

                      if (mounted) {
                        setState(() => _isLoading = false);
                        await _loadCacheSize();

                        if (success) {
                          ToastNotification.success(context, 'Cache images vidé');
                        } else {
                          ToastNotification.error(context, 'Impossible de vider le cache images. Veuillez réessayer.');
                        }
                      }
                    },
                    icon: Icon(Icons.image_outlined, color: blueColor),
                    label: Text('Vider le cache images uniquement'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blueColor,
                      side: BorderSide(color: blueColor),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCacheDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: blackColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? blueColor : greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheRow(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCacheDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: cloudColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Text(
              "Gérer le cache",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              _cacheSize,
              style: TextStyle(color: greyColor, fontSize: 14),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: greyColor, size: 20),
          ],
        ),
      ),
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
                _buildCacheRow(context),
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
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
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
                "Conditions Générales d'Utilisation – Supriz",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Dernière mise à jour : 28 février 2026",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 1. Acceptation
            Text(
              "1. Acceptation de l'utilisateur",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "En utilisant l'application Supriz, vous acceptez pleinement et sans réserve les présentes Conditions Générales d'Utilisation. Si vous n'êtes pas d'accord avec l'une de ces dispositions, vous devez cesser immédiatement d'utiliser l'application.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),

            // 2. Utilisation
            Text(
              "2. Utilisation de l'application",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Supriz est une application destinée à :",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text("• Envoyer et partager des messages émotionnels.", style: TextStyle(fontSize: 14)),
            Text("• Créer des liens de partage avec une durée de validité ajustable (24h, 48h ou 72h).", style: TextStyle(fontSize: 14)),
            Text("• Ajouter des images et choisir des arrière-plans variés.", style: TextStyle(fontSize: 14)),
            Text("• Ajouter de la musique à vos messages.", style: TextStyle(fontSize: 14)),
            Text("• Permettre aux destinataires de réagir avec des emojis.", style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text(
              "L'utilisateur s'engage à utiliser Supriz de manière respectueuse et à ne pas diffuser de contenus illégaux, offensants ou contraires aux bonnes mœurs.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),

            // 3. Compte utilisateur
            Text(
              "3. Compte utilisateur",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("• La création d'un compte nécessite une adresse email et un numéro de téléphone.", style: TextStyle(fontSize: 14)),
            Text("• Ces informations sont utilisées uniquement pour l'accès aux fonctionnalités et restent confidentielles.", style: TextStyle(fontSize: 14)),
            Text("• L'utilisateur est responsable de la confidentialité de ses identifiants et de l'exactitude des informations fournies.", style: TextStyle(fontSize: 14)),
            Text("• Supriz se réserve le droit de suspendre ou supprimer un compte en cas d'utilisation abusive ou frauduleuse.", style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),

            // 4. Propriété intellectuelle
            Text(
              "4. Propriété intellectuelle",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("• Le nom, le logo, le design et les éléments graphiques de Supriz sont protégés par les lois sur la propriété intellectuelle.", style: TextStyle(fontSize: 14)),
            Text("• L'utilisateur conserve la propriété de ses messages et images, mais accorde à Supriz une licence limitée pour leur utilisation dans le cadre du fonctionnement de l'application.", style: TextStyle(fontSize: 14)),
            Text("• Toute reproduction ou utilisation non autorisée des éléments de Supriz est interdite.", style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),

            // 5. Modification
            Text(
              "5. Modification des conditions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Supriz se réserve le droit de modifier les présentes Conditions Générales d'Utilisation à tout moment. Les utilisateurs seront informés des changements et devront accepter les nouvelles conditions pour continuer à utiliser l'application.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),

            // 6. Loi applicable
            Text(
              "6. Loi applicable et juridiction",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Les présentes conditions sont régies par la législation en vigueur au Bénin. En cas de litige, les tribunaux compétents du Bénin seront seuls habilités à en connaître.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),

            // 7. Contact
            Text(
              "7. Contact",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Pour toute question ou demande relative aux présentes conditions, vous pouvez nous contacter :",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text("• Email : contact@suprizs.com", style: TextStyle(fontSize: 14)),
            Text("• Téléphone : +229 01 61 55 66 80", style: TextStyle(fontSize: 14)),
            Text("• WhatsApp : +229 61 55 66 80", style: TextStyle(fontSize: 14)),
            SizedBox(height: 30),
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
            NormalText("Dernière mise à jour : 28 février 2026"),
            SizedBox(height: 16),
            NormalText(
              "Chez Supriz, nous croyons que les émotions méritent d'être partagées en toute simplicité et en toute confidentialité. Cette politique de confidentialité a pour but de vous expliquer comment nous traitons les données liées à votre utilisation de notre service.",
            ),
            SizedBox(height: 16),
            Section(
              title: "Collecte des Informations",
              texts: [
                "Nous collectons les informations suivantes lorsque vous utilisez notre application :",
                "- Informations de compte : Nom, Adresse e-mail, Numéro de téléphone.",
                "- Messages Supriz : les messages que vous créez et partagez.",
                "- Données techniques : informations sur votre appareil pour assurer le bon fonctionnement de l'application.",
              ],
            ),
            Section(
              title: "Utilisation des Informations",
              texts: [
                "Les informations collectées sont utilisées pour :",
                "- Permettre la création et le partage de vos messages Supriz.",
                "- Personnaliser votre expérience sur l'application.",
                "- Assurer la stabilité, la sécurité et la performance du service.",
                "- Vous envoyer des notifications importantes concernant votre compte.",
              ],
            ),
            Section(
              title: "Partage des Informations",
              texts: [
                "Nous ne vendons, ne louons, ni ne partageons vos données avec des tiers. Vos informations personnelles ne sont partagées que dans les cas suivants :",
                "- Si requis par la loi ou pour protéger nos droits légaux.",
              ],
            ),
            Section(
              title: "Sécurité des Informations",
              texts: [
                "Nous mettons en œuvre des mesures de sécurité pour protéger vos informations :",
                "- Connexion sécurisée via HTTPS.",
                "- Stockage sécurisé des données.",
                "- Accès restreint aux serveurs.",
              ],
            ),
            Section(
              title: "Vos Droits",
              texts: [
                "Vous avez le droit de :",
                "- Accéder à vos informations personnelles.",
                "- Demander la correction de vos informations personnelles.",
                "- Demander la suppression de votre compte et de vos données.",
              ],
            ),
            Section(
              title: "Modifications de la Politique",
              texts: [
                "Nous pouvons mettre à jour cette politique de confidentialité de temps en temps. Nous vous informerons de tout changement en publiant la nouvelle politique sur notre application.",
              ],
            ),
            Section(
              title: "Contact",
              texts: [
                "Pour toute question concernant cette politique de confidentialité ou pour exercer vos droits, veuillez contacter notre responsable de la protection des données :",
                "Email : contact@suprizs.com",
                "Téléphone : +229 01 61 55 66 80",
                "WhatsApp : +229 61 55 66 80",
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
