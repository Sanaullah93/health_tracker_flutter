mixin MealValidationMixin {
  String? validateFoodName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter food name";
    }
    if (value.length > 100) {
      return "Food name is too long (max 100 characters)";
    }
    if (value.length < 2) {
      return "Food name is too short";
    }
    return null;
  }

  String? validateCalories(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter calories";
    }

    final calories = int.tryParse(value);
    if (calories == null) {
      return "Please enter a valid number";
    }

    if (calories <= 0) {
      return "Calories must be positive";
    }

    if (calories > 5000) {
      return "Calories too high (max 5000)";
    }

    return null;
  }

  String? validateMealType(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select a meal type";
    }
    return null;
  }
}
