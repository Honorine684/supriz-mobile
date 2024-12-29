import 'package:supriz/consts/consts.dart';

class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String entreprise;
  final int evaluation;
  final int? prixPromo;
  final int? prixLivraison;
  final String? info;
  final List<String> images;
  final String personnalisable;
  final String statut;
  final String category; // Ajout du champ category
  final String subCategory; // Ajout du champ subCategory


  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.entreprise,
    required this.evaluation,
    this.prixPromo,
    this.prixLivraison,
    this.info,
    required this.images,
    required this.personnalisable,
    required this.statut,
    required this.category, // Ajout du champ category
    required this.subCategory, // Ajout du champ subCategory
  });

  // Fonction pour obtenir l'URL complète de l'image
  static String _getFullImageUrl(String path) {
    const String baseUrl = '$domaineapiImage/';  // Remplacez par votre domaine de base
    return baseUrl + path;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    print(json);
    return Product(
      id: json['id'],
      title: json['title'],
      price: (json['prix_promo'] != null && json['prix_promo'] != 0)
          ? json['prix_promo'].toDouble()
          : (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      entreprise: json['entreprise'],
      evaluation: json['evaluation'],
      prixPromo: (json['prix_promo'] != null && json['prix_promo'] != 0)
          ? json['price']
          : 0,
      prixLivraison: json['prix_livraison'],
      info: json['info'],
      images: [json['photo_main'], json['photo_secondary']]
          .where((image) => image != null)
          .map((image) => _getFullImageUrl(image as String))  // Utilise la fonction pour compléter l'URL
          .toList(),
      personnalisable: json['personnalisable'],
      statut: json['statut'],
      category: json['category'], // Ajout du champ category
      subCategory: json['subCategory'], // Ajout du champ subCategory
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'entreprise': entreprise,
      'evaluation': evaluation,
      'prixPromo': prixPromo,
      'prixLivraison': prixLivraison,
      'info': info,
      'images': images,
      'personnalisable': personnalisable,
      'statut': statut,
      'category': category,
      'subCategory': subCategory,
    };
  }
}