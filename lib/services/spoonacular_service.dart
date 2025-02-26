import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpoonacularService {
  static const String _baseUrl = 'api.spoonacular.com';
  static const String _apiKey = 'b9e6952fb6464e07a572b80e4f723767'; // Replace with your actual API key

  String _getImageUrl(int id, String? imageType) {
    final type = imageType ?? 'jpg';
    return 'https://spoonacular.com/recipeImages/$id-636x393.$type';
  }

  // Get meal plan for a day
  Future<Map<String, dynamic>> getDailyMealPlan({
    int? targetCalories,
    String? diet,
    List<String>? exclude,
  }) async {
    try {
      final queryParams = {
        'apiKey': _apiKey,
        'timeFrame': 'day',
        if (targetCalories != null) 'targetCalories': targetCalories.toString(),
        if (diet != null) 'diet': diet,
        if (exclude != null && exclude.isNotEmpty) 'exclude': exclude.join(','),
      };

      final uri = Uri.https(_baseUrl, '/mealplanner/generate', queryParams);
      
      debugPrint('🌐 Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 402) {
        debugPrint('Using mock data due to API limit...');
        return _getMockMealPlan(
          targetCalories: targetCalories,
          diet: diet,
          exclude: exclude,
        );
      }

      if (response.statusCode != 200) {
        debugPrint('Error response: ${response.statusCode} - ${response.body}');
        return _getMockMealPlan(
          targetCalories: targetCalories,
          diet: diet,
          exclude: exclude,
        );
      }

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      debugPrint('Error in getDailyMealPlan: $e');
      return _getMockMealPlan(
        targetCalories: targetCalories,
        diet: diet,
        exclude: exclude,
      );
    }
  }

  Map<String, dynamic> _getMockMealPlan({
    int? targetCalories,
    String? diet,
    List<String>? exclude,
  }) {
    return {
      "meals": [
        {
          "id": 655219,
          "title": "Peanut Butter And Chocolate Oatmeal",
          "readyInMinutes": 45,
          "servings": 1,
          "image": "https://spoonacular.com/recipeImages/655219-636x393.jpg",
          "diets": ["gluten free", "dairy free"],
          "healthScore": 100
        },
        {
          "id": 649931,
          "title": "Lentil Salad With Vegetables",
          "readyInMinutes": 45,
          "servings": 4,
          "image": "https://spoonacular.com/recipeImages/649931-636x393.jpg",
          "diets": ["gluten free", "dairy free", "lacto ovo vegetarian", "vegan"],
          "healthScore": 100
        },
        {
          "id": 632935,
          "title": "Asparagus and Pea Soup: Real Convenience Food",
          "readyInMinutes": 20,
          "servings": 2,
          "image": "https://spoonacular.com/recipeImages/632935-636x393.jpg",
          "diets": ["gluten free", "dairy free", "lacto ovo vegetarian", "vegan"],
          "healthScore": 100
        }
      ],
      "nutrients": {
        "calories": targetCalories ?? 2000,
        "protein": 100,
        "fat": 70,
        "carbohydrates": 250
      }
    };
  }

  // Get detailed nutrient information for a recipe
  Future<Map<String, dynamic>> getRecipeNutrition(int recipeId) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/recipes/$recipeId/nutritionWidget.json',
        {'apiKey': _apiKey},
      );

      debugPrint('🌐 Making nutrition request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Nutrition response status: ${response.statusCode}');
      debugPrint('📥 Nutrition response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Nutrition data: $data');
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to load nutrition info: ${errorBody['message'] ?? response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getRecipeNutrition: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Search recipes with nutrition requirements
  Future<List<dynamic>> searchRecipes({
    required String query,
    int? minCalories,
    int? maxCalories,
    int? minProtein,
    int? maxProtein,
    int? number = 10,
  }) async {
    try {
      final queryParameters = {
        'apiKey': _apiKey,
        'query': query,
        'number': number.toString(),
      };

      if (minCalories != null) queryParameters['minCalories'] = minCalories.toString();
      if (maxCalories != null) queryParameters['maxCalories'] = maxCalories.toString();
      if (minProtein != null) queryParameters['minProtein'] = minProtein.toString();
      if (maxProtein != null) queryParameters['maxProtein'] = maxProtein.toString();

      final uri = Uri.https(_baseUrl, '/recipes/complexSearch', queryParameters);

      debugPrint('🌐 Making search request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Search response status: ${response.statusCode}');
      debugPrint('📥 Search response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Search data: $data');
        if (!data.containsKey('results')) {
          throw Exception('Missing results key in response');
        }
        return data['results'] as List<dynamic>;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to search recipes: ${errorBody['message'] ?? response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in searchRecipes: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
