import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPreferences {
  int targetCalories;
  bool vegetarian;
  bool vegan;
  bool glutenFree;
  bool keto;
  bool paleo;
  bool lowCarb;
  bool mediterranean;
  bool halal;
  bool kosher;
  final List<String> allergies;
  final List<String> excludedIngredients;
  final List<String> culturalPreferences;

  UserPreferences({
    this.targetCalories = 2000,
    this.vegetarian = false,
    this.vegan = false,
    this.glutenFree = false,
    this.keto = false,
    this.paleo = false,
    this.lowCarb = false,
    this.mediterranean = false,
    this.halal = false,
    this.kosher = false,
    List<String>? allergies,
    List<String>? excludedIngredients,
    List<String>? culturalPreferences,
  })  : allergies = List<String>.from(allergies ?? []),
        excludedIngredients = List<String>.from(excludedIngredients ?? []),
        culturalPreferences = List<String>.from(culturalPreferences ?? []);

  Map<String, dynamic> toJson() {
    return {
      'targetCalories': targetCalories,
      'vegetarian': vegetarian,
      'vegan': vegan,
      'glutenFree': glutenFree,
      'keto': keto,
      'paleo': paleo,
      'lowCarb': lowCarb,
      'mediterranean': mediterranean,
      'halal': halal,
      'kosher': kosher,
      'allergies': allergies,
      'excludedIngredients': excludedIngredients,
      'culturalPreferences': culturalPreferences,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      targetCalories: json['targetCalories'] as int? ?? 2000,
      vegetarian: json['vegetarian'] as bool? ?? false,
      vegan: json['vegan'] as bool? ?? false,
      glutenFree: json['glutenFree'] as bool? ?? false,
      keto: json['keto'] as bool? ?? false,
      paleo: json['paleo'] as bool? ?? false,
      lowCarb: json['lowCarb'] as bool? ?? false,
      mediterranean: json['mediterranean'] as bool? ?? false,
      halal: json['halal'] as bool? ?? false,
      kosher: json['kosher'] as bool? ?? false,
      allergies: List<String>.from(json['allergies'] ?? []),
      excludedIngredients: List<String>.from(json['excludedIngredients'] ?? []),
      culturalPreferences: List<String>.from(json['culturalPreferences'] ?? []),
    );
  }

  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('user_preferences');
    if (jsonStr == null) {
      return UserPreferences();
    }
    try {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return UserPreferences.fromJson(json);
    } catch (e) {
      print('Error loading preferences: $e');
      return UserPreferences();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_preferences', jsonEncode(toJson()));
  }

  UserPreferences copy() {
    return UserPreferences(
      targetCalories: targetCalories,
      vegetarian: vegetarian,
      vegan: vegan,
      glutenFree: glutenFree,
      keto: keto,
      paleo: paleo,
      lowCarb: lowCarb,
      mediterranean: mediterranean,
      halal: halal,
      kosher: kosher,
      allergies: List<String>.from(allergies),
      excludedIngredients: List<String>.from(excludedIngredients),
      culturalPreferences: List<String>.from(culturalPreferences),
    );
  }
}
