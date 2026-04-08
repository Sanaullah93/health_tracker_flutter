import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:health_tracker_fyp/screens/meal/meal_constants.dart';
import 'package:health_tracker_fyp/screens/meal/meal_history_screen.dart';
import 'package:health_tracker_fyp/screens/meal/meal_validation_mixin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen>
    with MealValidationMixin {
  final _foodController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedMeal = MealConstants.mealTypes.first;
  DateTime _selectedTime = DateTime.now();
  bool _isLoading = false;
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _filteredSuggestions = [];
  XFile? _selectedImage;

  // Get the controller
  final HealthController healthController = Get.find<HealthController>();

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = List.from(MealConstants.suggestedFoods);

    // Listen for search changes
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final query = _searchController.text.toLowerCase();
          if (query.isEmpty) {
            _filteredSuggestions = List.from(MealConstants.suggestedFoods);
          } else {
            _filteredSuggestions = MealConstants.suggestedFoods
                .where((food) => food['name'].toLowerCase().contains(query))
                .toList();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Log Meal"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const MealHistoryScreen()),
            tooltip: "View Meal History",
          ),
        ],
      ),
      body: Obx(() {
        final todayCalories = healthController.consumedCalories.value;
        final goalCalories = healthController.caloriesGoal.value;
        final progress = goalCalories > 0
            ? (todayCalories / goalCalories).clamp(0.0, 1.0)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calories Progress Card
              _buildCaloriesCard(todayCalories, goalCalories, progress),

              const SizedBox(height: 25),

              // Meal Type Selection
              _buildMealTypeSelector(),

              const SizedBox(height: 20),

              // Time Selection
              _buildTimeSelector(),

              // Image Upload
              _buildImageUpload(),

              const SizedBox(height: 25),

              // Recent Foods
              _buildRecentFoods(),

              const SizedBox(height: 25),

              // Quick Suggestions with Search
              _buildQuickSuggestions(),

              const SizedBox(height: 25),

              // Meal Form
              _buildMealForm(),

              const SizedBox(height: 25),

              // Nutrition Facts
              _buildNutritionFacts(),

              const SizedBox(height: 25),

              // Meal Patterns
              _buildMealPatterns(),

              const SizedBox(height: 25),

              // Nutrition Tips
              _buildNutritionTips(),

              // Barcode Scanner
              _buildBarcodeScanner(),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCaloriesCard(
    int todayCalories,
    int goalCalories,
    double progress,
  ) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Calories",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: progress >= 1.0 ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$todayCalories / $goalCalories",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: progress >= 1.0 ? Colors.red : Colors.green,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toStringAsFixed(0)}% of goal",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  progress >= 1.0 ? "Limit Exceeded! ⚠️" : "On Track ✅",
                  style: TextStyle(
                    fontSize: 12,
                    color: progress >= 1.0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Meal Type",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: MealConstants.mealTypes.map((mealType) {
              final details =
                  MealConstants.mealTypeDetails[mealType] ??
                  {
                    'icon': Icons.restaurant,
                    'color': Colors.grey,
                    'displayName': mealType,
                  };
              bool isSelected = _selectedMeal == mealType;

              return GestureDetector(
                onTap: () => setState(() => _selectedMeal = mealType),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              details['color'],
                              details['color'].withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? details['color'] : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: details['color'].withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        details['icon'],
                        color: isSelected ? Colors.white : details['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        details['displayName'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Meal Time",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(_selectedTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _selectTime,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Change"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Food Photo (Optional)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap to add food photo",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Helps track portion sizes",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text("Remove Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFoods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              "Recently Logged",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _recentFoodChip("Apple (95 cal)", Colors.green),
            _recentFoodChip("Chicken Breast (165 cal)", Colors.orange),
            _recentFoodChip("Rice (200 cal)", Colors.amber),
            _recentFoodChip("Salad (150 cal)", Colors.lightGreen),
            _recentFoodChip("Yogurt (150 cal)", Colors.blue),
            _recentFoodChip("Bread (80 cal)", Colors.brown),
          ],
        ),
      ],
    );
  }

  Widget _recentFoodChip(String text, Color color) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.restaurant, size: 14, color: color),
      ),
      label: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      onPressed: () {
        final parts = text.split(' (');
        if (parts.length == 2) {
          _foodController.text = parts[0];
          final calories = parts[1].replaceAll(' cal)', '');
          _caloriesController.text = calories;
          setState(() {});
        }
      },
      backgroundColor: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Quick Suggestions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            if (_filteredSuggestions.length !=
                MealConstants.suggestedFoods.length)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filteredSuggestions = List.from(
                      MealConstants.suggestedFoods,
                    );
                  });
                },
                child: const Text("Clear"),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search foods...",
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 10),
        _filteredSuggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.fastfood, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "No foods found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final food = _filteredSuggestions[index];
                  return _foodSuggestionCard(food);
                },
              ),
      ],
    );
  }

  Widget _foodSuggestionCard(Map<String, dynamic> food) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onSuggestionTap(food),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                food['name'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${food['calories']} cal",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.add_circle, size: 14, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealForm() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Log Your Meal",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: "Food Name",
                hintText: "e.g., Chicken Biryani, Fruit Salad",
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorText: validateFoodName(_foodController.text),
                errorStyle: const TextStyle(fontSize: 12),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Calories",
                hintText: "e.g., 350",
                prefixIcon: const Icon(Icons.local_fire_department),
                suffixText: "calories",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorText: validateCalories(_caloriesController.text),
                errorStyle: const TextStyle(fontSize: 12),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickCalorieButton("+100", 100, Colors.blue),
                _quickCalorieButton("+200", 200, Colors.green),
                _quickCalorieButton("+300", 300, Colors.orange),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ||
                        validateFoodName(_foodController.text) != null ||
                        validateCalories(_caloriesController.text) != null
                    ? null
                    : _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 22),
                label: _isLoading
                    ? const Text("Saving...")
                    : const Text(
                        "Save Meal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCalorieButton(String label, int calories, Color color) {
    return OutlinedButton(
      onPressed: () {
        int current = int.tryParse(_caloriesController.text) ?? 0;
        _caloriesController.text = (current + calories).toString();
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNutritionFacts() {
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = (calories * 0.2 ~/ 4);
    final carbs = (calories * 0.5 ~/ 4);
    final fat = (calories * 0.3 ~/ 9);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Estimated Nutrition Facts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (calories > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _nutritionItem("Protein", "${protein}g", Colors.green),
                  _nutritionItem("Carbs", "${carbs}g", Colors.orange),
                  _nutritionItem("Fat", "${fat}g", Colors.red),
                  _nutritionItem("Calories", "$calories", Colors.blue),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value:
                    (healthController.consumedCalories.value + calories) /
                    (healthController.caloriesGoal.value == 0
                        ? 1
                        : healthController.caloriesGoal.value),
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Total: ${healthController.consumedCalories.value + calories} cal",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    "Goal: ${healthController.caloriesGoal.value} cal",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ] else ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "Enter calories to see nutrition facts",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nutritionItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMealPatterns() {
    return Obx(() {
      final mealTypes = healthController.mealTypes;
      final total = healthController.consumedCalories.value;

      if (total == 0) return const SizedBox();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Meal Distribution",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...mealTypes.entries.map((entry) {
                if (entry.value == 0) return const SizedBox();
                final percentage = total > 0 ? (entry.value / total * 100) : 0;
                final mealDetails =
                    MealConstants.mealTypeDetails[entry.key] ??
                    {'displayName': entry.key, 'color': Colors.grey};

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: mealDetails['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mealDetails['displayName'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        "${entry.value} cal",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: mealDetails['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${percentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: mealDetails['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNutritionTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  "💡 Nutrition Tips",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip(
              "Drink water before meals to reduce calorie intake",
              Icons.water_drop,
              Colors.blue,
            ),
            _buildTip(
              "Include protein in every meal for better satiety",
              Icons.fitness_center,
              Colors.green,
            ),
            _buildTip(
              "Eat slowly to give your brain time to register fullness",
              Icons.timer,
              Colors.orange,
            ),
            _buildTip(
              "Use smaller plates to control portion sizes",
              Icons.dining,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }

  Widget _buildBarcodeScanner() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Quick Scan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Scan food barcode for automatic calorie tracking",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanBarcode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.qr_code, size: 20),
              label: const Text("Scan Barcode"),
            ),
          ],
        ),
      ),
    );
  }

  void _onSuggestionTap(Map<String, dynamic> food) {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _foodController.text = food['name'];
          _caloriesController.text = food['calories'].toString();
        });
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _scanBarcode() async {
    Get.snackbar(
      "Coming Soon!",
      "Barcode scanning feature will be available soon",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _saveMeal() async {
    // Validation using mixin
    final foodError = validateFoodName(_foodController.text);
    final caloriesError = validateCalories(_caloriesController.text);

    if (foodError != null || caloriesError != null) {
      Get.snackbar(
        "Validation Error",
        foodError ?? caloriesError ?? "Please check your inputs",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final calories = int.parse(_caloriesController.text);

    // High calorie warning
    if (calories > 2000) {
      bool confirm =
          await Get.dialog(
            AlertDialog(
              title: const Text("High Calorie Warning"),
              content: Text(
                "You're about to log $calories calories for $_selectedMeal. Is this correct?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Yes, Save"),
                ),
              ],
            ),
            barrierDismissible: false,
          ) ??
          false;

      if (!confirm) return;
    }

    await _confirmSaveMeal(calories);
  }

  Future<void> _confirmSaveMeal(int calories) async {
    setState(() => _isLoading = true);

    try {
      // Log meal with time
      await healthController.addMeal(
        _selectedMeal,
        _foodController.text,
        calories,
        time: _selectedTime,
      );

      // Clear form
      _foodController.clear();
      _caloriesController.clear();
      _searchController.clear();
      _selectedImage = null;
      _filteredSuggestions = List.from(MealConstants.suggestedFoods);

      // Show success message
      Get.snackbar(
        '✅ Success',
        '${MealConstants.mealDisplayNames[_selectedMeal]} logged successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Close screen after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Get.back();
      });
    } catch (e) {
      // Handle specific errors
      String errorMessage = 'Failed to save meal';
      if (e is SocketException) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timeout. Please try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _foodController.dispose();
    _caloriesController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
