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
    String? mealType,
    String? cuisine,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'apiKey': _apiKey,
        'number': '10',
        'offset': offset.toString(),
        'addRecipeInformation': 'true',
        'sort': 'random',  // Add randomization
        if (targetCalories != null) 'maxCalories': targetCalories.toString(),
        if (diet != null) 'diet': diet,
        if (exclude != null && exclude.isNotEmpty) 'excludeIngredients': exclude.join(','),
        if (mealType != null && mealType.toLowerCase() != 'dinner') 'type': mealType.toLowerCase(),
        if (cuisine != null) 'cuisine': cuisine.toLowerCase(),
      };

      final uri = Uri.https(_baseUrl, '/recipes/complexSearch', queryParams);
      debugPrint('🌐 Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        debugPrint('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch meals: ${errorBody['message'] ?? 'Unknown error'}');
      }

      final data = json.decode(response.body);
      if (data['results'] == null || (data['results'] as List).isEmpty) {
        // If no meals found with type filter, try without it
        if (mealType != null) {
          return getDailyMealPlan(
            targetCalories: targetCalories,
            diet: diet,
            exclude: exclude,
            mealType: null,  // Remove meal type filter
            cuisine: cuisine,
            offset: offset,
          );
        }
        throw Exception('No meals found for the given criteria');
      }

      return {'meals': data['results']};
    } catch (e) {
      debugPrint('Error in getDailyMealPlan: $e');
      throw Exception('Failed to fetch meals: $e');
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
