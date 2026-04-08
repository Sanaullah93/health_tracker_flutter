import 'package:flutter/material.dart';

class MealConstants {
  static const List<String> mealTypes = [
    "breakfast",
    "morning_snack",
    "lunch",
    "afternoon_snack",
    "dinner",
    "evening_snack",
  ];

  static const Map<String, String> mealDisplayNames = {
    "breakfast": "Breakfast 🍳",
    "morning_snack": "Morning Snack ☕",
    "lunch": "Lunch 🍲",
    "afternoon_snack": "Afternoon Snack 🍎",
    "dinner": "Dinner 🍽️",
    "evening_snack": "Evening Snack 🌙",
  };
  static const Map<String, Map<String, dynamic>> mealTypeDetails = {
    'breakfast': {
      'displayName': 'Breakfast',
      'icon': Icons.breakfast_dining,
      'color': Colors.orange,
    },
    'lunch': {
      'displayName': 'Lunch',
      'icon': Icons.lunch_dining,
      'color': Colors.green,
    },
    'dinner': {
      'displayName': 'Dinner',
      'icon': Icons.dinner_dining,
      'color': Colors.blue,
    },
    'snacks': {
      'displayName': 'Snacks',
      'icon': Icons.cookie,
      'color': Colors.purple,
    },
  };

  static const List<Map<String, dynamic>> suggestedFoods = [
    {"name": "Oatmeal", "calories": 150},
    {"name": "Eggs (2)", "calories": 140},
    {"name": "Toast with butter", "calories": 200},
    {"name": "Chicken Rice", "calories": 350},
    {"name": "Vegetable Salad", "calories": 120},
    {"name": "Grilled Chicken", "calories": 230},
    {"name": "Fruit Bowl", "calories": 100},
    {"name": "Yogurt", "calories": 150},
    {"name": "Protein Shake", "calories": 180},
    {"name": "Apple", "calories": 95},
    {"name": "Banana", "calories": 105},
    {"name": "Brown Rice", "calories": 215},
    {"name": "Salmon", "calories": 206},
    {"name": "Avocado", "calories": 160},
    {"name": "Almonds (handful)", "calories": 164},
  ];
}
