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


final List<Map<String, dynamic>> categories = [
  {
    'name': 'Homme',
    'subCategories': {
      'T-shirts': [
        Product(
          id: 1,
          title: 'T-shirt 1',
          price: 20.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 1',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Homme',
          subCategory: 'T-shirts',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Pantalons': [
        Product(
          id: 2,
          title: 'Pantalon 1',
          price: 30,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 2',
          evaluation: 5,
          images: ["https://placehold.co/800@2x.png"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Homme',
          subCategory: 'Pantalons',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Vestes': [
        Product(
          id: 3,
          title: 'Veste 1',
          price: 40.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 3',
          evaluation: 3,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Homme',
          subCategory: 'Vestes',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Chaussures': [
        Product(
          id: 4,
          title: 'Chaussure 1',
          price: 50.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 4',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Homme',
          subCategory: 'Chaussures',
        ),
        // Ajoutez d'autres produits ici
      ],
    },
  },
  {
    'name': 'Femme',
    'subCategories': {
      'Robes': [
        Product(
          id: 5,
          title: 'Robe 1',
          price: 60.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 5',
          evaluation: 5,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Femme',
          subCategory: 'Robes',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Jupes': [
        Product(
          id: 6,
          title: 'Jupe 1',
          price: 70.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 6',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Femme',
          subCategory: 'Jupes',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Chemisiers': [
        Product(
          id: 7,
          title: 'Chemisier 1',
          price: 80.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 7',
          evaluation: 3,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Femme',
          subCategory: 'Chemisiers',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Chaussures': [
        Product(
          id: 8,
          title: 'Chaussure 2',
          price: 90.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 8',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Femme',
          subCategory: 'Chaussures',
        ),
        // Ajoutez d'autres produits ici
      ],
    },
  },
  {
    'name': 'Enfants',
    'subCategories': {
      'T-shirts': [
        Product(
          id: 9,
          title: 'T-shirt Enfant 1',
          price: 20.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 9',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Enfants',
          subCategory: 'T-shirts',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Pantalons': [
        Product(
          id: 10,
          title: 'Pantalon Enfant 1',
          price: 30.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 10',
          evaluation: 5,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Enfants',
          subCategory: 'Pantalons',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Robes': [
        Product(
          id: 11,
          title: 'Robe Enfant 1',
          price: 40.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 11',
          evaluation: 3,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'yes',
          statut: 'Disponible',
          category: 'Enfants',
          subCategory: 'Robes',
        ),
        // Ajoutez d'autres produits ici
      ],
      'Chaussures': [
        Product(
          id: 12,
          title: 'Chaussure Enfant 1',
          price: 50.0,
          description: """Mais je sais aussi qu’une fois qu’ils rencontrent du succès, beaucoup de hackers commencent à se sentir invincibles.
Ils deviennent arrogants, relâchent leur vigilance, et finissent par commettre des erreurs.
Et comme toujours, ces erreurs les mènent inévitablement vers l’obscurité de la prison.""",
          entreprise: 'Entreprise 12',
          evaluation: 4,
          images: ["https://ewxd4bbz5hp.exactdn.com/wp-content/uploads/2019/08/07-Bottega-Veneta_ThePeakSingapore-700x900-311x400.jpg"],
          personnalisable: 'Non',
          statut: 'Disponible',
          category: 'Enfants',
          subCategory: 'Chaussures',
        ),
        // Ajoutez d'autres produits ici
      ],
    },
  },
];
