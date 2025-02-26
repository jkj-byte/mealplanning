import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/colo_extension.dart';
import '../common_widget/meal_food_schedule_row.dart';
import '../common_widget/nutritions_row.dart';
import 'models/meal.dart';
import 'models/meal_plan.dart';
import 'models/nutrients.dart';
import 'models/user_preferences.dart';
import 'services/meal_service.dart';
import 'widgets/preferences_dialog.dart';
import 'meal_type_view.dart';
import 'dart:convert';

class MealScheduleView extends StatefulWidget {
  final MealPlan? mealPlan;
  const MealScheduleView({super.key, this.mealPlan});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  CalendarAgendaController _calendarAgendaControllerAppBar =
      CalendarAgendaController();

  late DateTime _selectedDateAppBBar;

  final MealService _mealService = MealService();
  MealPlan? _currentMealPlan;
  bool _isLoading = false;
  double _calories = 0;
  double _protein = 0;
  double _fat = 0;
  double _carbs = 0;

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
    _currentMealPlan = widget.mealPlan;
    if (_currentMealPlan == null) {
      _loadMealPlan(_selectedDateAppBBar);
    } else {
      _updateNutritionValues();
    }
  }

  void _updateNutritionValues() {
    if (_currentMealPlan != null) {
      setState(() {
        _calories = _currentMealPlan!.nutrients.calories;
        _protein = _currentMealPlan!.nutrients.protein;
        _fat = _currentMealPlan!.nutrients.fat;
        _carbs = _currentMealPlan!.nutrients.carbohydrates;
      });
    }
  }

  Future<void> _loadMealPlan(DateTime date, {bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final mealPlan = await _mealService.getDailyMealPlan(date, forceRefresh);
      if (mounted) {
        setState(() {
          _currentMealPlan = mealPlan;
          _updateNutritionValues();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading meal plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load meal plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAndSaveMealPlan(Meal selectedMeal, String mealType) async {
    if (_currentMealPlan != null) {
      final meals = [..._currentMealPlan!.meals];
      
      // Remove any existing meal of the same type
      meals.removeWhere((m) => m.type?.toLowerCase() == mealType.toLowerCase());
      
      // Add the new meal with the correct type
      final mealWithType = selectedMeal.copyWith(type: mealType.toLowerCase());
      meals.add(mealWithType);

      final updatedMealPlan = MealPlan(
        meals: meals,
        nutrients: _currentMealPlan!.nutrients,
      );

      try {
        await _mealService.saveMealPlan(updatedMealPlan, _selectedDateAppBBar);
        if (mounted) {
          setState(() {
            _currentMealPlan = updatedMealPlan;
            _updateNutritionValues();
          });
        }
      } catch (e) {
        print('Error saving updated meal plan: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save meal plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showMealTypeView(String mealType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealTypeView(
          mealType: mealType,
          onMealSelected: (meal) async {
            await _updateAndSaveMealPlan(meal, mealType);
            Navigator.pop(context, true);
          },
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getMealTime(Meal meal) {
    // Simple logic to assign times based on meal order
    final index = _currentMealPlan!.meals.indexOf(meal);
    switch (index) {
      case 0:
        return '8:00 AM';
      case 1:
        return '1:00 PM';
      case 2:
        return '7:00 PM';
      default:
        return '${index + 8}:00';
    }
  }

  void _showPreferencesDialog() async {
    final userPrefs = await UserPreferences.load();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PreferencesDialog(
        preferences: userPrefs,
        onSave: (prefs) async {
          await prefs.save();
          await _mealService.clearSavedMealPlan();
        },
      ),
    );

    if (result == true && mounted) {
      await _loadMealPlan(_selectedDateAppBBar, forceRefresh: true);
    }
  }

  Widget _buildMealTypeCard(String title, VoidCallback onTap) {
    final mealType = title.toLowerCase();
    final meal = _currentMealPlan?.meals.firstWhere(
      (m) => m.type?.toLowerCase() == mealType,
      orElse: () => Meal(
        id: 0,
        title: "",
        readyInMinutes: 0,
        servings: 0,
        diets: [],
        healthScore: 0,
      ),
    );

    IconData iconData;
    switch (mealType) {
      case 'breakfast':
        iconData = Icons.free_breakfast;
        break;
      case 'lunch':
        iconData = Icons.lunch_dining;
        break;
      case 'dinner':
        iconData = Icons.dinner_dining;
        break;
      default:
        iconData = Icons.restaurant;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              iconData,
              size: 40,
              color: TColor.primaryColor2,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (meal?.title.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                meal!.title,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Meal Schedule",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _showPreferencesDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                Icons.settings,
                size: 20,
                color: TColor.primaryColor2,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              try {
                await _loadMealPlan(_selectedDateAppBBar);
              } catch (e) {
                print('Error refreshing meals: $e');
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor2),
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: TColor.primaryColor2,
                  ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: TColor.white,
              boxShadow: [
                BoxShadow(
                  color: TColor.gray.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CalendarAgenda(
              controller: _calendarAgendaControllerAppBar,
              appbar: false,
              selectedDayPosition: SelectedDayPosition.center,
              leading: IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/img/ArrowLeft.png",
                  width: 15,
                  height: 15,
                ),
              ),
              training: IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/img/ArrowRight.png",
                  width: 15,
                  height: 15,
                ),
              ),
              weekDay: WeekDay.short,
              dayNameFontSize: 12,
              dayNumberFontSize: 16,
              dayBGColor: TColor.lightGray,
              titleSpaceBetween: 15,
              backgroundColor: Colors.transparent,
              fullCalendarScroll: FullCalendarScroll.horizontal,
              fullCalendarDay: WeekDay.short,
              selectedDateColor: Colors.white,
              dateColor: TColor.black,
              locale: 'en',
              initialDate: DateTime.now(),
              calendarEventColor: TColor.primaryColor2,
              firstDate: DateTime.now().subtract(const Duration(days: 140)),
              lastDate: DateTime.now().add(const Duration(days: 60)),
              onDateSelected: (date) async {
                setState(() {
                  _selectedDateAppBBar = date;
                  _isLoading = true;
                });
                
                try {
                  // Force refresh when selecting a new date to ensure we get different meals
                  await _loadMealPlan(date, forceRefresh: true);
                } catch (e) {
                  print('Error loading meal plan for date: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to load meal plan: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              selectedDayLogo: Container(
                width: double.maxFinite,
                height: double.maxFinite,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: TColor.primaryG,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TColor.primaryColor2,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColor.primaryColor2.withOpacity(0.3),
                                TColor.primaryColor1.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Daily Nutrition",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: TColor.black,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TColor.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 14,
                                          color: TColor.primaryColor2,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Today",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: TColor.primaryColor2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_currentMealPlan != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildNutrientInfo(
                                      "Calories",
                                      _currentMealPlan!.nutrients.calories.toStringAsFixed(0),
                                      "kCal"
                                    ),
                                    _buildNutrientInfo(
                                      "Protein",
                                      _currentMealPlan!.nutrients.protein.toStringAsFixed(1),
                                      "g"
                                    ),
                                    _buildNutrientInfo(
                                      "Fat",
                                      _currentMealPlan!.nutrients.fat.toStringAsFixed(1),
                                      "g"
                                    ),
                                    _buildNutrientInfo(
                                      "Carbs",
                                      _currentMealPlan!.nutrients.carbohydrates.toStringAsFixed(1),
                                      "g"
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Meal Types",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: TColor.gray.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMealTypeCard(
                                "Breakfast",
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MealTypeView(
                                        mealType: "Breakfast",
                                        onMealSelected: (meal) async {
                                          await _updateAndSaveMealPlan(meal, "breakfast");
                                          Navigator.pop(context);
                                          _loadMealPlan(_selectedDateAppBBar);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildMealTypeCard(
                                "Lunch",
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MealTypeView(
                                        mealType: "Lunch",
                                        onMealSelected: (meal) async {
                                          await _updateAndSaveMealPlan(meal, "lunch");
                                          Navigator.pop(context);
                                          _loadMealPlan(_selectedDateAppBBar);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildMealTypeCard(
                                "Dinner",
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MealTypeView(
                                        mealType: "Dinner",
                                        onMealSelected: (meal) async {
                                          await _updateAndSaveMealPlan(meal, "dinner");
                                          Navigator.pop(context);
                                          _loadMealPlan(_selectedDateAppBBar);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_currentMealPlan != null && _currentMealPlan!.meals.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Breakfast",
                                    style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: TColor.gray.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MealFoodScheduleRow(
                                meal: _currentMealPlan!.meals[0],
                              ),
                              if (_currentMealPlan!.meals.length > 1) 
                                Column(
                                  children: [
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        Text(
                                          "Lunch",
                                          style: TextStyle(
                                            color: TColor.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: TColor.gray.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    MealFoodScheduleRow(
                                      meal: _currentMealPlan!.meals[1],
                                    ),
                                  ],
                                ),
                              if (_currentMealPlan!.meals.length > 2) 
                                Column(
                                  children: [
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        Text(
                                          "Dinner",
                                          style: TextStyle(
                                            color: TColor.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: TColor.gray.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    MealFoodScheduleRow(
                                      meal: _currentMealPlan!.meals[2],
                                    ),
                                  ],
                                ),
                            ],
                          )
                        else
                          const Center(
                            child: Text('No meals planned for today'),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}