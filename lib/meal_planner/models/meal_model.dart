class MealPlan {
  final List<Meal> meals;
  final Nutrients nutrients;

  MealPlan({
    required this.meals,
    required this.nutrients,
  });

  Map<String, dynamic> toJson() {
    return {
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'nutrients': nutrients.toJson(),
    };
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      meals: (json['meals'] as List<dynamic>)
          .map((mealJson) => Meal.fromJson(mealJson as Map<String, dynamic>))
          .toList(),
      nutrients: Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
    );
  }
}

class Meal {
  final int id;
  final String title;
  final int readyInMinutes;
  final int servings;
  final String image;
  final List<String> diets;
  final int healthScore;

  Meal({
    required this.id,
    required this.title,
    required this.readyInMinutes,
    required this.servings,
    required this.image,
    required this.diets,
    required this.healthScore,
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
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as int,
      title: json['title'] as String,
      readyInMinutes: json['readyInMinutes'] as int,
      servings: json['servings'] as int,
      image: json['image'] as String,
      diets: (json['diets'] as List<dynamic>).cast<String>(),
      healthScore: json['healthScore'] as int,
    );
  }
}

class Nutrients {
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;

  Nutrients({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrates,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbohydrates': carbohydrates,
    };
  }

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
    );
  }
}
