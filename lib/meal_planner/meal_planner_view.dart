import 'package:flutter/material.dart';
import 'package:foody/meal_planner/meal_schedule_view.dart';
import '../common/colo_extension.dart';
import 'models/meal.dart';
import 'models/meal_plan.dart';
import 'models/nutrients.dart';
import 'models/user_preferences.dart';
import 'widgets/preferences_dialog.dart';
import 'services/meal_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({Key? key}) : super(key: key);

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  final MealService _mealService = MealService();
  MealPlan? _mealPlan;
  bool _isLoading = false;
  String? _error;
  Set<int> _favoriteMeals = {};
  late UserPreferences _userPreferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _userPreferences = await UserPreferences.load();
    _loadMealPlan();
    _loadFavorites();
  }

  Future<void> _showPreferencesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PreferencesDialog(
        preferences: _userPreferences,
        onSave: (preferences) async {
          setState(() {
            _userPreferences = preferences;
            _isLoading = true;
          });
          await preferences.save();
          await _loadMealPlan(true); // Force refresh meals with new preferences
        },
      ),
    );
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_meals');
    if (favorites != null) {
      setState(() {
        _favoriteMeals = favorites.map((s) => int.parse(s)).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(int mealId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteMeals.contains(mealId)) {
        _favoriteMeals.remove(mealId);
      } else {
        _favoriteMeals.add(mealId);
      }
    });
    await prefs.setStringList(
      'favorite_meals',
      _favoriteMeals.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _loadMealPlan([bool forceRefresh = false]) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mealPlan = await _mealService.getDailyMealPlan(DateTime.now(), forceRefresh);
      if (mounted) {
        setState(() {
          _mealPlan = mealPlan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load meal plan. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNutritionCard() {
    if (_mealPlan == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.primaryColor2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Nutrition',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TColor.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientInfo('Calories', '${_mealPlan!.nutrients.calories.round()} kcal'),
              _buildNutrientInfo('Protein', '${_mealPlan!.nutrients.protein.round()}g'),
              _buildNutrientInfo('Carbs', '${_mealPlan!.nutrients.carbohydrates.round()}g'),
              _buildNutrientInfo('Fat', '${_mealPlan!.nutrients.fat.round()}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TColor.primaryColor2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: TColor.gray,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    final isFavorite = _favoriteMeals.contains(meal.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: TColor.primaryColor2.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Image.network(
                meal.image ?? "",
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.restaurant,
                  color: TColor.gray,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "${meal.readyInMinutes} mins • ${meal.servings} servings",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleFavorite(meal.id),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? TColor.primaryColor2 : TColor.gray,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    if (_mealPlan == null) return SizedBox.shrink();

    final mealTypes = ['breakfast', 'lunch', 'dinner'];
    final sortedMeals = mealTypes
        .map((type) => _mealPlan!.meals.firstWhere(
              (meal) => meal.type?.toLowerCase() == type,
              orElse: () => Meal(
                id: 0,
                title: 'No $type meal available',
                readyInMinutes: 0,
                servings: 0,
                type: type,
                diets: [],
                healthScore: 0,
                image: null,
              ),
            ))
        .toList();

    return Column(
      children: sortedMeals.map((meal) => _buildMealCard(meal)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: TColor.gray),
        ),
        title: Text(
          'Meal Planner',
          style: TextStyle(
            color: TColor.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: TColor.primaryColor2),
            onPressed: _showPreferencesDialog,
          ),
          IconButton(
            onPressed: () => _loadMealPlan(true),
            icon: Icon(
              Icons.refresh,
              color: TColor.primaryColor2,
            ),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading meal plan',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMealPlan,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _mealPlan == null
                  ? Center(child: Text('No meal plan available'))
                  : RefreshIndicator(
                      onRefresh: _loadMealPlan,
                      child: ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          _buildNutritionCard(),
                          SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MealScheduleView(mealPlan: _mealPlan!),
                                  ),
                                );
                              },
                              icon: Icon(Icons.calendar_today, size: 28),
                              label: Text(
                                'Daily Schedule',
                                style: TextStyle(fontSize: 20),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.primaryColor2,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Today\'s Meals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildMealsList(),
                        ],
                      ),
                    ),
    );
  }
}