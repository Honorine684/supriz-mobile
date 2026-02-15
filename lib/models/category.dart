class Category {
  final int id;
  final String nameIdCategories;
  final String libelleHommeCategories;

  Category({
    required this.id,
    required this.nameIdCategories,
    required this.libelleHommeCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameIdCategories: json['name_id_categories'],
      libelleHommeCategories: json['libelle_homme_categories'],
    );
  }
}
