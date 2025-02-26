import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/nutrients.dart';
import '../models/user_preferences.dart';
import 'spoonacular_service.dart';

class MealService {
  static const String _mealPlanKeyPrefix = 'meal_plan_';
  final SpoonacularService _spoonacularService = SpoonacularService();

  String getMealPlanKey(DateTime date) {
    return _mealPlanKeyPrefix + date.toIso8601String().split('T')[0];
  }

  Future<MealPlan> getDailyMealPlan([DateTime? date, bool forceRefresh = false]) async {
    final targetDate = date ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final mealPlanKey = getMealPlanKey(targetDate);
    final userPrefs = await UserPreferences.load();
    
    if (!forceRefresh) {
      final savedMealPlan = prefs.getString(mealPlanKey);
      if (savedMealPlan != null) {
        try {
          final mealPlanMap = json.decode(savedMealPlan);
          final savedPrefsJson = prefs.getString('${mealPlanKey}_prefs');
          if (savedPrefsJson != null) {
            final savedPrefs = UserPreferences.fromJson(json.decode(savedPrefsJson));
            if (_preferencesMatch(savedPrefs, userPrefs)) {
              return MealPlan.fromJson(mealPlanMap);
            }
          }
        } catch (e) {
          print('Error loading saved meal plan: $e');
        }
      }
    }

    try {
      String? diet = _getDietFromPreferences(userPrefs);
      List<String>? exclude = _getExclusionsFromPreferences(userPrefs);
      String? cuisine = _getCuisineFromPreferences(userPrefs);
      final meals = <Meal>[];
      final usedMealIds = <int>{};  // Track used meal IDs to prevent duplicates
      
      // Add date to seed to get different meals for different days
      final random = DateTime.now().millisecondsSinceEpoch ^ targetDate.millisecondsSinceEpoch;
      
      // Fetch meals for each type separately to ensure variety
      final mealTypes = ['breakfast', 'lunch', 'dinner'];
      for (var type in mealTypes) {
        int attempts = 0;
        List<Meal> typeMeals = [];
        
        while (typeMeals.isEmpty && attempts < 3) {
          final typeData = await _spoonacularService.getDailyMealPlan(
            targetCalories: userPrefs.targetCalories,
            diet: diet,
            exclude: exclude,
            mealType: type,
            cuisine: cuisine,
            offset: random % 100, // Use the random seed to get different results
          );
          
          if (typeData['meals'] != null) {
            final mealsList = typeData['meals'] as List;
            for (var mealData in mealsList) {
              final mealId = mealData['id'] as int;
              if (!usedMealIds.contains(mealId)) {
                usedMealIds.add(mealId);
                final meal = Meal(
                  id: mealId,
                  title: mealData['title'],
                  readyInMinutes: mealData['readyInMinutes'] ?? 30,
                  servings: mealData['servings'] ?? 1,
                  image: mealData['image'],
                  diets: List<String>.from(mealData['diets'] ?? []),
                  healthScore: mealData['healthScore']?.toDouble() ?? 80,
                  type: type,
                );
                typeMeals.add(meal);
                break;  // We only need one unique meal per type
              }
            }
          }
          attempts++;
        }
        
        meals.addAll(typeMeals);
      }

      final mealPlan = MealPlan(
        meals: meals,
        nutrients: Nutrients(
          calories: userPrefs.targetCalories.toDouble(),
          protein: userPrefs.targetCalories * 0.2,
          fat: userPrefs.targetCalories * 0.3,
          carbohydrates: userPrefs.targetCalories * 0.5,
        ),
      );

      // Save both meal plan and preferences
      await saveMealPlan(mealPlan, targetDate);
      await prefs.setString('${mealPlanKey}_prefs', json.encode(userPrefs.toJson()));
      
      return mealPlan;
    } catch (e) {
      print('Error fetching meal plan from Spoonacular: $e');
      throw Exception('Failed to fetch meal plan');
    }
  }

  Future<MealPlan> getMealsByType(String type, UserPreferences prefs) async {
    try {
      final mealPlanData = await _spoonacularService.getDailyMealPlan(
        targetCalories: prefs.targetCalories,
        diet: _getDietFromPreferences(prefs),
        exclude: _getExclusionsFromPreferences(prefs),
        mealType: type,
        cuisine: _getCuisineFromPreferences(prefs),
      );

      final meals = <Meal>[];
      if (mealPlanData['meals'] != null) {
        final mealsList = mealPlanData['meals'] as List;
        for (var mealData in mealsList) {
          meals.add(Meal(
            id: mealData['id'],
            title: mealData['title'],
            readyInMinutes: mealData['readyInMinutes'] ?? 30,
            servings: mealData['servings'] ?? 1,
            image: mealData['image'],
            diets: List<String>.from(mealData['diets'] ?? []),
            healthScore: mealData['healthScore']?.toDouble() ?? 80,
            type: type,
          ));
        }
      }

      return MealPlan(
        meals: meals,
        nutrients: Nutrients(
          calories: prefs.targetCalories.toDouble(),
          protein: prefs.targetCalories * 0.2,
          fat: prefs.targetCalories * 0.3,
          carbohydrates: prefs.targetCalories * 0.5,
        ),
      );
    } catch (e) {
      print('Error fetching meals by type: $e');
      throw Exception('Failed to fetch meals by type');
    }
  }

  String? _getDietFromPreferences(UserPreferences prefs) {
    if (prefs.vegetarian) return 'vegetarian';
    if (prefs.vegan) return 'vegan';
    if (prefs.glutenFree) return 'gluten free';
    if (prefs.keto) return 'ketogenic';
    if (prefs.paleo) return 'paleo';
    if (prefs.lowCarb) return 'low carb';
    if (prefs.mediterranean) return 'mediterranean';
    return null;
  }

  List<String>? _getExclusionsFromPreferences(UserPreferences prefs) {
    final exclusions = [...prefs.excludedIngredients, ...prefs.allergies];
    return exclusions.isNotEmpty ? exclusions : null;
  }

  String? _getCuisineFromPreferences(UserPreferences prefs) {
    if (prefs.culturalPreferences.isEmpty) return null;
    // Map common cultural preferences to Spoonacular cuisine types
    final cuisineMap = {
      'indian': 'indian',
      'chinese': 'chinese',
      'mexican': 'mexican',
      'italian': 'italian',
      'japanese': 'japanese',
      'thai': 'thai',
      'mediterranean': 'mediterranean',
      'middle eastern': 'middle eastern',
      'korean': 'korean',
      'vietnamese': 'vietnamese',
    };
    
    // Return the first matching cuisine preference
    for (var pref in prefs.culturalPreferences) {
      final cuisine = cuisineMap[pref.toLowerCase()];
      if (cuisine != null) return cuisine;
    }
    return null;
  }

  Future<void> saveMealPlan(MealPlan mealPlan, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealPlanKey = getMealPlanKey(date);
      await prefs.setString(mealPlanKey, json.encode(mealPlan.toJson()));
    } catch (e) {
      print('Error saving meal plan: $e');
      throw Exception('Failed to save meal plan');
    }
  }

  bool _preferencesMatch(UserPreferences saved, UserPreferences current) {
    return saved.targetCalories == current.targetCalories &&
           saved.vegetarian == current.vegetarian &&
           saved.vegan == current.vegan &&
           saved.glutenFree == current.glutenFree &&
           saved.keto == current.keto &&
           saved.paleo == current.paleo &&
           saved.lowCarb == current.lowCarb &&
           saved.mediterranean == current.mediterranean &&
           saved.halal == current.halal &&
           saved.kosher == current.kosher &&
           _listEquals(saved.allergies, current.allergies) &&
           _listEquals(saved.excludedIngredients, current.excludedIngredients) &&
           _listEquals(saved.culturalPreferences, current.culturalPreferences);
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    return true;
  }

  Future<void> clearSavedMealPlan([DateTime? date]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (date != null) {
        await prefs.remove(getMealPlanKey(date));
      } else {
        final keys = prefs.getKeys();
        for (var key in keys) {
          if (key.startsWith(_mealPlanKeyPrefix)) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error clearing meal plan: $e');
    }
  }
}
