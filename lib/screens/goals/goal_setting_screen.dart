import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:intl/intl.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final HealthController healthController = Get.find();

  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _weightGoalController = TextEditingController();

  bool _isLoading = false;
  String _selectedGoalType = 'fitness'; // 'fitness', 'weight', 'nutrition'
  DateTime? _goalDeadline;

  // Goal Templates
  final List<Map<String, dynamic>> _goalTemplates = [
    {
      'name': 'Weight Loss',
      'icon': Icons.trending_down,
      'color': Colors.green,
      'steps': 12000,
      'calories': 1600,
      'water': 2500,
      'description': 'Gradual weight loss with balanced activity',
    },
    {
      'name': 'Muscle Gain',
      'icon': Icons.fitness_center,
      'color': Colors.orange,
      'steps': 8000,
      'calories': 2500,
      'water': 3000,
      'description': 'Focus on strength training and protein',
    },
    {
      'name': 'Maintenance',
      'icon': Icons.balance,
      'color': Colors.blue,
      'steps': 10000,
      'calories': 2200,
      'water': 2000,
      'description': 'Maintain current weight and fitness',
    },
    {
      'name': 'Athlete',
      'icon': Icons.directions_run,
      'color': Colors.purple,
      'steps': 15000,
      'calories': 2800,
      'water': 3500,
      'description': 'High intensity training program',
    },
  ];

  // Preset goals
  final Map<String, List<Map<String, dynamic>>> _presetGoals = {
    'fitness': [
      {'name': 'Beginner', 'steps': 5000, 'label': '5k Steps'},
      {'name': 'Active', 'steps': 10000, 'label': '10k Steps'},
      {'name': 'Athlete', 'steps': 15000, 'label': '15k Steps'},
    ],
    'weight': [
      {'name': 'Mild Loss', 'calories': 1800, 'label': '1kg/month'},
      {'name': 'Moderate Loss', 'calories': 1600, 'label': '2kg/month'},
      {'name': 'Aggressive Loss', 'calories': 1400, 'label': '4kg/month'},
      {'name': 'Maintain', 'calories': 2200, 'label': 'Maintain'},
    ],
    'nutrition': [
      {'name': 'Balanced', 'water': 2000, 'label': '2L Water'},
      {'name': 'Active', 'water': 2500, 'label': '2.5L Water'},
      {'name': 'Athlete', 'water': 3000, 'label': '3L Water'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  void _loadCurrentGoals() {
    // Load current goals from controller
    _stepsController.text = healthController.stepsGoal.value.toString();
    _caloriesController.text = healthController.caloriesGoal.value.toString();
    // Water goal (default)
    _waterController.text = "2000";
    // Weight goal (placeholder)
    _weightGoalController.text = "";

    // Set deadline to 30 days from now
    _goalDeadline = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _saveGoals() async {
    if (!_validateSMARTGoals()) return;

    setState(() => _isLoading = true);

    try {
      // Save to controller
      await healthController.updateGoals(
        int.parse(_stepsController.text),
        int.parse(_caloriesController.text),
      );

      // Show success message
      Get.snackbar(
        "🎯 Goals Updated!",
        "Your goals have been saved successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate back after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Get.back();
        }
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save goals: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateSMARTGoals() {
    // Check empty fields
    if (_stepsController.text.isEmpty ||
        _caloriesController.text.isEmpty ||
        _waterController.text.isEmpty) {
      Get.snackbar(
        "Missing Fields",
        "Please fill all required fields",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    final steps = int.tryParse(_stepsController.text);
    final calories = int.tryParse(_caloriesController.text);
    final water = int.tryParse(_waterController.text);

    // Specific & Measurable
    if (steps == null || steps <= 0 || steps > 30000) {
      Get.snackbar(
        "Invalid Steps",
        "Please enter valid steps (1-30,000)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (calories == null || calories <= 0 || calories > 5000) {
      Get.snackbar(
        "Invalid Calories",
        "Please enter valid calories (1-5,000)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (water == null || water <= 0 || water > 10000) {
      Get.snackbar(
        "Invalid Water",
        "Please enter valid water amount (1-10,000 ml)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Achievable - Weight goal validation
    final weightGoal = double.tryParse(_weightGoalController.text);
    if (weightGoal != null && weightGoal > 0) {
      final currentWeight =
          double.tryParse(healthController.userWeight.value) ?? 70;
      if ((weightGoal - currentWeight).abs() < 0.5) {
        Get.snackbar(
          "Not Measurable",
          "Set at least 0.5kg difference for meaningful progress",
          backgroundColor: Colors.orange,
        );
        return false;
      }
    }

    // Time-bound
    if (_goalDeadline == null) {
      Get.snackbar(
        "Missing Deadline",
        "Please set a target date for your goals",
        backgroundColor: Colors.orange,
      );
      return false;
    }

    return true;
  }

  void _applyPresetGoal(Map<String, dynamic> preset) {
    switch (_selectedGoalType) {
      case 'fitness':
        _stepsController.text = preset['steps'].toString();
        break;
      case 'weight':
        _caloriesController.text = preset['calories'].toString();
        break;
      case 'nutrition':
        _waterController.text = preset['water'].toString();
        break;
    }
    setState(() {});
  }

  void _applyTemplateGoal(Map<String, dynamic> template) {
    setState(() {
      _stepsController.text = template['steps'].toString();
      _caloriesController.text = template['calories'].toString();
      _waterController.text = template['water'].toString();
      _selectedGoalType = 'fitness';
    });
  }

  void _selectDeadline() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _goalDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() => _goalDeadline = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Set Your Goals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTips,
            tooltip: "Goal Setting Tips",
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGoals,
            tooltip: "Save Goals",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== GOAL TEMPLATES ==========
            _buildGoalTemplates(),

            const SizedBox(height: 25),

            // ========== GOAL TYPE SELECTOR ==========
            Text(
              "Goal Type",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _goalTypeButton(Icons.directions_walk, "Fitness", 'fitness'),
                const SizedBox(width: 10),
                _goalTypeButton(Icons.monitor_weight, "Weight", 'weight'),
                const SizedBox(width: 10),
                _goalTypeButton(Icons.water_drop, "Nutrition", 'nutrition'),
              ],
            ),

            const SizedBox(height: 25),

            // ========== QUICK PRESETS ==========
            Text(
              "Quick Presets",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetGoals[_selectedGoalType]!.map((preset) {
                return ActionChip(
                  label: Text("${preset['name']} (${preset['label']})"),
                  onPressed: () => _applyPresetGoal(preset),
                  backgroundColor: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            // ========== GOAL CALCULATOR ==========
            _buildGoalCalculator(),

            // ========== TIMELINE ==========
            _buildTimeline(),

            // ========== WEEKLY BREAKDOWN ==========
            _buildWeeklyBreakdown(),

            // ========== CUSTOM GOALS FORM ==========
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Custom Goals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Steps Goal with Slider
                    _buildStepSlider(),

                    const SizedBox(height: 25),

                    // Calories Goal
                    TextField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Daily Calories Goal",
                        hintText: "e.g., 2000",
                        prefixIcon: const Icon(Icons.local_fire_department),
                        suffixText: "calories",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Water Goal
                    TextField(
                      controller: _waterController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Daily Water Intake",
                        hintText: "e.g., 2000",
                        prefixIcon: const Icon(Icons.water_drop),
                        suffixText: "ml",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Weight Goal (Optional)
                    TextField(
                      controller: _weightGoalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Weight Goal (Optional)",
                        hintText: "e.g., 70",
                        prefixIcon: const Icon(Icons.monitor_weight),
                        suffixText: "kg",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Goal Deadline
                    GestureDetector(
                      onTap: _selectDeadline,
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Goal Deadline",
                            hintText: "Select target date",
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          controller: TextEditingController(
                            text: _goalDeadline != null
                                ? DateFormat(
                                    'MMM d, yyyy',
                                  ).format(_goalDeadline!)
                                : "Not set",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ========== CURRENT PROGRESS ==========
            Obx(() {
              final stepsProgress = healthController.stepsGoal.value > 0
                  ? (healthController.dailySteps.value /
                            healthController.stepsGoal.value)
                        .clamp(0.0, 1.0)
                  : 0.0;

              final caloriesProgress = healthController.caloriesGoal.value > 0
                  ? (healthController.consumedCalories.value /
                            healthController.caloriesGoal.value)
                        .clamp(0.0, 1.0)
                  : 0.0;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📊 Current Progress",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _progressItem(
                        "Steps",
                        healthController.dailySteps.value,
                        healthController.stepsGoal.value,
                        stepsProgress,
                        Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      _progressItem(
                        "Calories",
                        healthController.consumedCalories.value,
                        healthController.caloriesGoal.value,
                        caloriesProgress,
                        Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      _progressItem(
                        "Water",
                        healthController.waterIntake.value,
                        healthController.waterGoal.value,
                        healthController.waterProgress,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            // ========== SAVE BUTTON ==========
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveGoals,
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
                    : const Icon(Icons.flag, size: 22),
                label: _isLoading
                    ? const Text("Saving...")
                    : const Text(
                        "Save All Goals",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🏆 Goal Templates",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _goalTemplates.length,
            itemBuilder: (context, index) {
              final template = _goalTemplates[index];
              return GestureDetector(
                onTap: () => _applyTemplateGoal(template),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: template['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: template['color'].withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: template['color'].withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                template['icon'],
                                color: template['color'],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              template['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: template['color'],
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template['description'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  size: 12,
                                  color: template['color'],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${template['steps']}",
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to apply",
                              style: TextStyle(
                                fontSize: 9,
                                color: template['color'],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCalculator() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "🎯 Goal Calculator",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final bmi = healthController.bmi;
              final currentWeight =
                  double.tryParse(healthController.userWeight.value) ?? 70;
              final weightGoal =
                  double.tryParse(_weightGoalController.text) ?? currentWeight;
              final weightDiff = (weightGoal - currentWeight).abs();
              final weeksNeeded = weightDiff > 0
                  ? weightDiff / 0.5
                  : 0; // 0.5kg per week

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _calculatorItem(
                          "Current BMI",
                          bmi.toStringAsFixed(1),
                          _getBMIColor(bmi),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _calculatorItem(
                          "BMI Status",
                          _getBMICategory(bmi),
                          _getBMIColor(bmi),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (weightGoal != currentWeight && weightGoal > 0)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value:
                              ((currentWeight - weightGoal).abs() / weightDiff)
                                  .clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          color: weightGoal > currentWeight
                              ? Colors.green
                              : Colors.blue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${weightDiff.toStringAsFixed(1)}kg ${weightGoal > currentWeight ? 'gain' : 'loss'} in ${weeksNeeded.ceil()} weeks",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_goalDeadline == null) return const SizedBox();

    final daysLeft = _goalDeadline!.difference(DateTime.now()).inDays;
    final totalDays = _goalDeadline!
        .difference(DateTime.now().subtract(const Duration(days: 30)))
        .inDays;
    final progress = max(0, 30 - daysLeft) / 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "⏰ Timeline",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: daysLeft <= 7
                        ? Colors.red.shade50
                        : daysLeft <= 14
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$daysLeft days left",
                    style: TextStyle(
                      color: daysLeft <= 7
                          ? Colors.red
                          : daysLeft <= 14
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: daysLeft <= 7
                  ? Colors.red
                  : daysLeft <= 14
                  ? Colors.orange
                  : Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Start",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      DateFormat('MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Target",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      DateFormat('MMM d').format(_goalDeadline!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBreakdown() {
    final steps = int.tryParse(_stepsController.text) ?? 10000;
    final calories = int.tryParse(_caloriesController.text) ?? 2000;
    final water = int.tryParse(_waterController.text) ?? 2000;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "📅 Weekly Breakdown",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _breakdownItem("Steps/week", "${(steps * 7).toString()}"),
                _breakdownItem("Calories/week", "${(calories * 7).toString()}"),
                _breakdownItem("Water/week", "${(water * 7 ~/ 1000)}L"),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Weekly totals help you see the bigger picture and stay consistent",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Daily Steps Goal",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              "${_stepsController.text} steps",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          value: int.parse(
            _stepsController.text.isEmpty ? "5000" : _stepsController.text,
          ).toDouble(),
          min: 1000,
          max: 20000,
          divisions: 19,
          label: "${_stepsController.text} steps",
          onChanged: (value) {
            setState(() {
              _stepsController.text = value.round().toString();
            });
          },
          activeColor: Colors.blue,
          inactiveColor: Colors.blue.shade100,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("1k", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              "10k",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              "20k",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _goalTypeButton(IconData icon, String label, String type) {
    final isSelected = _selectedGoalType == type;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() => _selectedGoalType = type);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _progressItem(
    String label,
    int current,
    int goal,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              "$current / $goal",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 3),
        Text(
          "${(progress * 100).toStringAsFixed(1)}% of goal",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _calculatorItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _breakdownItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  void _showTips() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "🎯 Goal Setting Tips",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tipItem(
                        Icons.flag,
                        "Be Specific",
                        "Set clear, measurable goals (e.g., 10,000 steps, not 'exercise more')",
                      ),
                      _tipItem(
                        Icons.timeline,
                        "Track Progress",
                        "Review your progress weekly and adjust goals as needed",
                      ),
                      _tipItem(
                        Icons.emoji_events,
                        "Celebrate Milestones",
                        "Reward yourself when you achieve small milestones",
                      ),
                      _tipItem(
                        Icons.water_drop,
                        "Stay Hydrated",
                        "Aim for 2-3 liters of water daily for optimal health",
                      ),
                      _tipItem(
                        Icons.fitness_center,
                        "Balance Activity",
                        "Mix cardio, strength training, and rest days",
                      ),
                      _tipItem(
                        Icons.restaurant,
                        "Nutrition Matters",
                        "Focus on balanced meals with protein, carbs, and healthy fats",
                      ),
                      _tipItem(
                        Icons.schedule,
                        "Consistency is Key",
                        "Small daily improvements lead to big long-term results",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text("Got it!"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    _weightGoalController.dispose();
    super.dispose();
  }
}
