class Meal {
  final int id;
  final String title;
  final int readyInMinutes;
  final int servings;
  final String? image;
  final List<String> diets;
  final double healthScore;
  final String? type;

  Meal({
    required this.id,
    required this.title,
    required this.readyInMinutes,
    required this.servings,
    this.image,
    required this.diets,
    required this.healthScore,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'image': image,
      'diets': diets,
      'healthScore': healthScore,
      'type': type,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      title: json['title'],
      readyInMinutes: json['readyInMinutes'] ?? 30,
      servings: json['servings'] ?? 1,
      image: json['image'],
      diets: List<String>.from(json['diets'] ?? []),
      healthScore: json['healthScore']?.toDouble() ?? 80,
      type: json['type'],
    );
  }

  Meal copyWith({
    int? id,
    String? title,
    int? readyInMinutes,
    int? servings,
    String? image,
    List<String>? diets,
    double? healthScore,
    String? type,
  }) {
    return Meal(
      id: id ?? this.id,
      title: title ?? this.title,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      image: image ?? this.image,
      diets: diets ?? this.diets,
      healthScore: healthScore ?? this.healthScore,
      type: type ?? this.type,
    );
  }
}
