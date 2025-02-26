import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../models/user_preferences.dart';

class PreferencesDialog extends StatefulWidget {
  final UserPreferences preferences;
  final Function(UserPreferences) onSave;

  const PreferencesDialog({
    Key? key,
    required this.preferences,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  late UserPreferences _preferences;
  final _caloriesController = TextEditingController();
  final _allergyController = TextEditingController();
  final _excludeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences.copy();
    _caloriesController.text = _preferences.targetCalories.toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _allergyController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  void _addAllergy(String allergy) {
    if (!_preferences.allergies.contains(allergy)) {
      setState(() {
        _preferences.allergies.add(allergy);
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _preferences.allergies.remove(allergy);
    });
  }

  void _addExclusion(String item) {
    if (!_preferences.excludedIngredients.contains(item)) {
      setState(() {
        _preferences.excludedIngredients.add(item);
      });
    }
  }

  void _removeExclusion(String item) {
    setState(() {
      _preferences.excludedIngredients.remove(item);
    });
  }

  Widget _buildChips(List<String> items, List<String> selectedItems, Function(String) onAdd, Function(String) onRemove) {
    return Wrap(
      spacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) {
              onAdd(item);
            } else {
              onRemove(item);
            }
          },
          backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dietary Preferences',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Daily Calories',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _preferences.targetCalories = int.tryParse(value) ?? 2000;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Diet Type',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Vegetarian'),
                  selected: _preferences.vegetarian,
                  onSelected: (bool selected) {
                    setState(() {
                      _preferences.vegetarian = selected;
                      if (selected) _preferences.vegan = false;
                    });
                  },
                  backgroundColor: _preferences.vegetarian ? Colors.blue : Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _preferences.vegetarian ? Colors.white : Colors.black87,
                  ),
                ),
                FilterChip(
                  label: const Text('Vegan'),
                  selected: _preferences.vegan,
                  onSelected: (bool selected) {
                    setState(() {
                      _preferences.vegan = selected;
                      if (selected) _preferences.vegetarian = false;
                    });
                  },
                  backgroundColor: _preferences.vegan ? Colors.blue : Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _preferences.vegan ? Colors.white : Colors.black87,
                  ),
                ),
                FilterChip(
                  label: const Text('Gluten Free'),
                  selected: _preferences.glutenFree,
                  onSelected: (bool selected) {
                    setState(() => _preferences.glutenFree = selected);
                  },
                  backgroundColor: _preferences.glutenFree ? Colors.blue : Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _preferences.glutenFree ? Colors.white : Colors.black87,
                  ),
                ),
                FilterChip(
                  label: const Text('Keto'),
                  selected: _preferences.keto,
                  onSelected: (bool selected) {
                    setState(() => _preferences.keto = selected);
                  },
                  backgroundColor: _preferences.keto ? Colors.blue : Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _preferences.keto ? Colors.white : Colors.black87,
                  ),
                ),
                FilterChip(
                  label: const Text('Paleo'),
                  selected: _preferences.paleo,
                  onSelected: (bool selected) {
                    setState(() => _preferences.paleo = selected);
                  },
                  backgroundColor: _preferences.paleo ? Colors.blue : Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: _preferences.paleo ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Cuisine Types',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildChips(
              [
                'Indian',
                'Italian',
                'Chinese',
                'Japanese',
                'Mexican',
                'Thai',
                'Mediterranean',
                'French',
                'Korean',
                'Middle Eastern',
                'Vietnamese',
                'Greek',
              ],
              _preferences.culturalPreferences,
              (cuisine) => setState(() => _preferences.culturalPreferences.add(cuisine)),
              (cuisine) => setState(() => _preferences.culturalPreferences.remove(cuisine)),
            ),
            const SizedBox(height: 20),
            Text(
              'Allergies',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildChips(
              ['Peanuts', 'Tree Nuts', 'Milk', 'Egg', 'Wheat', 'Soy', 'Fish', 'Shellfish'],
              _preferences.allergies,
              _addAllergy,
              _removeAllergy,
            ),
            const SizedBox(height: 20),
            Text(
              'Exclude Ingredients',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildChips(
              ['Mushrooms', 'Onions', 'Garlic', 'Bell Peppers', 'Cilantro', 'Olives', 'Eggplant', 'Tomatoes'],
              _preferences.excludedIngredients,
              _addExclusion,
              _removeExclusion,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await widget.onSave(_preferences);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
