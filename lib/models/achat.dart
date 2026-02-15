class Achat {
  final String nom;
  final int prix;
  final double evaluation;
  final int quantite;
  final int sousTotal;
  final String personnalisable;

  Achat({
    required this.nom,
    required this.prix,
    required this.evaluation,
    required this.quantite,
    required this.sousTotal,
    required this.personnalisable,
  });

  factory Achat.fromJson(Map<String, dynamic> json) {
    return Achat(
      nom: json['nom'],
      prix: json['prix'],
      evaluation: json['evaluation'],
      quantite: json['quantite'],
      sousTotal: json['sous_total'],
      personnalisable: json['personnalisable'],
    );
  }
}
