import 'meal.dart';
import 'nutrients.dart';

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
      meals: (json['meals'] as List)
          .map((mealJson) => Meal.fromJson(mealJson))
          .toList(),
      nutrients: Nutrients.fromJson(json['nutrients']),
    );
  }
}
