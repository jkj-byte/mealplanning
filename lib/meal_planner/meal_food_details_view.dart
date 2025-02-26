import 'package:flutter/material.dart';
import '../common/colo_extension.dart';
import 'models/meal_model.dart';

class MealFoodDetailsView extends StatefulWidget {
  final Meal meal;

  const MealFoodDetailsView({
    Key? key,
    required this.meal,
  }) : super(key: key);

  @override
  State<MealFoodDetailsView> createState() => _MealFoodDetailsViewState();
}

class _MealFoodDetailsViewState extends State<MealFoodDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: TColor.white,
            pinned: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: TColor.gray),
            ),
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.meal.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.meal.image!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: TColor.lightGray,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant, size: 64, color: TColor.gray),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: TColor.gray),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: TColor.lightGray,
                      child: Icon(Icons.restaurant, size: 64, color: TColor.gray),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.meal.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TColor.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.timer, color: TColor.gray),
                      SizedBox(width: 8),
                      Text(
                        '${widget.meal.readyInMinutes} minutes',
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 24),
                      Icon(Icons.people, color: TColor.gray),
                      SizedBox(width: 8),
                      Text(
                        '${widget.meal.servings} servings',
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (widget.meal.diets.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Diet Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TColor.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.meal.diets.map((diet) {
                        return Chip(
                          label: Text(
                            diet,
                            style: TextStyle(
                              color: TColor.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: TColor.primaryColor2,
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 16),
                  Text(
                    'Health Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TColor.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.meal.healthScore / 100,
                    backgroundColor: TColor.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.meal.healthScore >= 70
                          ? Colors.green
                          : widget.meal.healthScore >= 40
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.meal.healthScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 14,
                    ),
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