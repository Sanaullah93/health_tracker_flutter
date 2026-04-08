import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';

// ========== CONSTANT ICONS DEFINITION ==========
// Sab IconData ko constants mein define karein
const IconData waterDropIcon = Icons.water_drop;
const IconData directionsWalkIcon = Icons.directions_walk;
const IconData appleIcon = Icons.apple;
const IconData bedtimeIcon = Icons.bedtime;
const IconData selfImprovementIcon = Icons.self_improvement;
const IconData ecoIcon = Icons.eco;
const IconData phoneAndroidIcon = Icons.phone_android;
const IconData fitnessCenterIcon = Icons.fitness_center;
const IconData psychologyIcon = Icons.psychology;
const IconData localDrinkIcon = Icons.local_drink;
const IconData monitorWeightIcon = Icons.monitor_weight;
const IconData directionsRunIcon = Icons.directions_run;
const IconData waterIcon = Icons.water;
const IconData localDiningIcon = Icons.local_dining;
const IconData healthSafetyIcon = Icons.health_and_safety;
const IconData favoriteIcon = Icons.favorite;
const IconData bookmarkIcon = Icons.bookmark;
const IconData arrowForwardIcon = Icons.arrow_forward_ios;
const IconData refreshIcon = Icons.refresh;
const IconData autoAwesomeIcon = Icons.auto_awesome;
const IconData checkCircleIcon = Icons.check_circle;
const IconData timerIcon = Icons.timer;
const IconData differenceIcon = Icons.difference_outlined;
const IconData repeatIcon = Icons.repeat;
const IconData categoryIcon = Icons.category;
const IconData tipsUpdatesIcon = Icons.tips_and_updates;
const IconData libraryBooksIcon = Icons.library_books;
const IconData starIcon = Icons.star;
const IconData analyticsIcon = Icons.analytics;
const IconData searchIcon = Icons.search;
const IconData clearIcon = Icons.clear;

// ========== TIP MODEL ==========
class HealthTip {
  final int id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final String difficulty;
  final String time;
  final String frequency;
  bool isFavorite;
  bool isCompleted;
  final bool isPersonalized;
  final DateTime? createdAt;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.time,
    required this.frequency,
    this.isFavorite = false,
    this.isCompleted = false,
    this.isPersonalized = false,
    this.createdAt,
  });

  // FIXED: Direct IconData use karein
  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      icon: _parseIconData(json['icon']),
      color: _parseColor(json['color']),
      difficulty: json['difficulty'],
      time: json['time'],
      frequency: json['frequency'],
      isPersonalized: json['isPersonalized'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': _getIconCode(icon), // Code point get karein
      'color': color.value,
      'difficulty': difficulty,
      'time': time,
      'frequency': frequency,
      'isFavorite': isFavorite,
      'isCompleted': isCompleted,
      'isPersonalized': isPersonalized,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  HealthTip copyWith({bool? isFavorite, bool? isCompleted}) {
    return HealthTip(
      id: id,
      title: title,
      description: description,
      category: category,
      icon: icon,
      color: color,
      difficulty: difficulty,
      time: time,
      frequency: frequency,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      isPersonalized: isPersonalized,
      createdAt: createdAt,
    );
  }

  // FIXED: Constant icons ka use karein
  static IconData _parseIconData(dynamic icon) {
    if (icon is int) {
      return _getIconFromCodePoint(icon);
    }
    return healthSafetyIcon; // Constant use karein
  }

  static int _getIconCode(IconData iconData) {
    return iconData.codePoint;
  }

  static IconData _getIconFromCodePoint(int codePoint) {
    // Code point to icon mapping using constants
    final Map<int, IconData> iconMap = {
      0xf1e8: waterDropIcon,
      0xe5c8: directionsWalkIcon,
      0xe4e4: appleIcon,
      0xef6a: bedtimeIcon,
      0xeb7a: selfImprovementIcon,
      0xe1b4: ecoIcon,
      0xe32c: phoneAndroidIcon,
      0xe3e7: fitnessCenterIcon,
      0xe8dc: psychologyIcon,
      0xe14e: localDrinkIcon,
      0xf3ba: monitorWeightIcon,
      0xe4eb: directionsRunIcon,
      0xe4ec: waterIcon,
      0xe256: localDiningIcon,
      0xe617: healthSafetyIcon,
      0xe87d: favoriteIcon,
    };

    return iconMap[codePoint] ?? healthSafetyIcon;
  }

  static Color _parseColor(dynamic color) {
    if (color is int) {
      return Color(color);
    }
    return Colors.blue;
  }
}

// ========== TIPS CONTROLLER ==========
class HealthTipsController extends GetxController {
  final HealthController healthController = Get.find();

  final RxString selectedCategory = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxList<HealthTip> allTips = <HealthTip>[].obs;
  final RxList<HealthTip> filteredTips = <HealthTip>[].obs;
  final RxList<int> favoriteTipIds = <int>[].obs;
  final RxList<int> completedTipIds = <int>[].obs;
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  // Categories
  final List<String> categories = [
    'all',
    'nutrition',
    'exercise',
    'hydration',
    'sleep',
    'mental',
    'general',
  ];

  // Static tips database - DIRECT CONSTANT ICONS
  final List<Map<String, dynamic>> staticTips = [
    {
      'id': 1,
      'title': '🚰 Drink Water Regularly',
      'description':
          'Drink at least 8 glasses (2 liters) of water daily to stay hydrated and improve metabolism.',
      'category': 'hydration',
      'icon': waterDropIcon, // DIRECT CONSTANT
      'color': Colors.blue.value,
      'difficulty': 'Easy',
      'time': '5 min',
      'frequency': 'Daily',
    },
    {
      'id': 2,
      'title': '🚶‍♂️ Take Walking Breaks',
      'description':
          'Take a 5-minute walk every hour if you have a desk job. It improves circulation and reduces back pain.',
      'category': 'exercise',
      'icon': directionsWalkIcon, // DIRECT CONSTANT
      'color': Colors.green.value,
      'difficulty': 'Easy',
      'time': '5 min',
      'frequency': 'Every Hour',
    },
    {
      'id': 3,
      'title': '🍎 Eat Fruits Daily',
      'description':
          'Include at least 2 servings of fresh fruits in your daily diet for vitamins and fiber.',
      'category': 'nutrition',
      'icon': appleIcon, // DIRECT CONSTANT
      'color': Colors.red.value,
      'difficulty': 'Easy',
      'time': '10 min',
      'frequency': 'Daily',
    },
    {
      'id': 4,
      'title': '💤 Get Enough Sleep',
      'description':
          'Aim for 7-8 hours of quality sleep every night for better recovery and mental health.',
      'category': 'sleep',
      'icon': bedtimeIcon, // DIRECT CONSTANT
      'color': Colors.purple.value,
      'difficulty': 'Medium',
      'time': '8 hours',
      'frequency': 'Daily',
    },
    {
      'id': 5,
      'title': '🧘 Practice Deep Breathing',
      'description':
          'Practice 5 minutes of deep breathing daily to reduce stress and improve focus.',
      'category': 'mental',
      'icon': selfImprovementIcon, // DIRECT CONSTANT
      'color': Colors.teal.value,
      'difficulty': 'Easy',
      'time': '5 min',
      'frequency': 'Daily',
    },
    {
      'id': 6,
      'title': '🥦 Include Vegetables',
      'description':
          'Make half your plate vegetables at lunch and dinner for balanced nutrition.',
      'category': 'nutrition',
      'icon': ecoIcon, // DIRECT CONSTANT
      'color': Colors.green.value,
      'difficulty': 'Easy',
      'time': '15 min',
      'frequency': 'Daily',
    },
    {
      'id': 7,
      'title': '📱 Limit Screen Time',
      'description':
          'Take a 15-minute break from screens every 2 hours to reduce eye strain.',
      'category': 'general',
      'icon': phoneAndroidIcon, // DIRECT CONSTANT
      'color': Colors.grey.value,
      'difficulty': 'Medium',
      'time': '15 min',
      'frequency': 'Every 2 Hours',
    },
    {
      'id': 8,
      'title': '🏋️ Strength Training',
      'description':
          'Include strength training 2-3 times a week to build muscle and boost metabolism.',
      'category': 'exercise',
      'icon': fitnessCenterIcon, // DIRECT CONSTANT
      'color': Colors.orange.value,
      'difficulty': 'Hard',
      'time': '30 min',
      'frequency': '2-3 times/week',
    },
    {
      'id': 9,
      'title': '🧠 Mindfulness Practice',
      'description':
          'Practice 10 minutes of mindfulness or meditation daily for mental clarity.',
      'category': 'mental',
      'icon': psychologyIcon, // DIRECT CONSTANT
      'color': Colors.indigo.value,
      'difficulty': 'Medium',
      'time': '10 min',
      'frequency': 'Daily',
    },
    {
      'id': 10,
      'title': '🥤 Avoid Sugary Drinks',
      'description':
          'Replace sugary drinks with water or herbal tea to reduce calorie intake.',
      'category': 'nutrition',
      'icon': localDrinkIcon, // DIRECT CONSTANT
      'color': Colors.brown.value,
      'difficulty': 'Medium',
      'time': 'N/A',
      'frequency': 'Always',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadTips();
    setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadTips() async {
    try {
      isLoading(true);

      // Load static tips
      final List<HealthTip> tips = [];

      // Add static tips
      tips.addAll(staticTips.map((tip) => HealthTip.fromJson(tip)));

      // Generate personalized tips based on user data
      final personalizedTips = _generatePersonalizedTips();
      tips.addAll(personalizedTips);

      // Load favorites and completed status
      await _loadUserProgress();

      // Update tips with user progress
      for (final tip in tips) {
        tip.isFavorite = favoriteTipIds.contains(tip.id);
        tip.isCompleted = completedTipIds.contains(tip.id);
      }

      allTips.assignAll(tips);
      filteredTips.assignAll(tips);

      update();
    } catch (e) {
      debugPrint('Error loading tips: $e');
    } finally {
      isLoading(false);
    }
  }

  List<HealthTip> _generatePersonalizedTips() {
    final List<HealthTip> personalizedTips = [];
    final userBMI = healthController.bmi;
    final stepsProgress = healthController.stepsProgress;
    final caloriesProgress = healthController.caloriesProgress;
    final waterProgress = healthController.waterProgress;

    // BMI-based tips
    if (userBMI > 25) {
      personalizedTips.add(
        HealthTip(
          id: 101,
          title: '⚖️ Weight Management Focus',
          description:
              'Your BMI (${userBMI.toStringAsFixed(1)}) suggests focusing on balanced diet and regular exercise for weight management.',
          category: 'nutrition',
          icon: monitorWeightIcon, // CONSTANT
          color: Colors.deepOrange,
          difficulty: 'Medium',
          time: '30 min',
          frequency: 'Daily',
          isPersonalized: true,
        ),
      );
    } else if (userBMI < 18.5) {
      personalizedTips.add(
        HealthTip(
          id: 102,
          title: '💪 Build Healthy Weight',
          description:
              'Your BMI (${userBMI.toStringAsFixed(1)}) suggests incorporating more protein and strength training.',
          category: 'nutrition',
          icon: fitnessCenterIcon, // CONSTANT
          color: Colors.amber,
          difficulty: 'Medium',
          time: '20 min',
          frequency: '3 times/week',
          isPersonalized: true,
        ),
      );
    }

    // Steps-based tips
    if (stepsProgress < 0.5) {
      personalizedTips.add(
        HealthTip(
          id: 103,
          title: '🚶 Increase Daily Steps',
          description:
              'You\'re below 50% of your step goal. Try taking short walks throughout the day.',
          category: 'exercise',
          icon: directionsRunIcon, // CONSTANT
          color: Colors.green,
          difficulty: 'Easy',
          time: '10 min',
          frequency: '3 times/day',
          isPersonalized: true,
        ),
      );
    }

    // Water intake tips
    if (waterProgress < 0.5) {
      personalizedTips.add(
        HealthTip(
          id: 104,
          title: '💧 Hydration Reminder',
          description:
              'You\'ve only consumed ${healthController.waterIntake}ml water today. Aim for regular hydration.',
          category: 'hydration',
          icon: waterIcon, // CONSTANT
          color: Colors.blue,
          difficulty: 'Easy',
          time: '2 min',
          frequency: 'Every hour',
          isPersonalized: true,
        ),
      );
    }

    // Calorie-based tips
    if (caloriesProgress > 1.2) {
      personalizedTips.add(
        HealthTip(
          id: 105,
          title: '🍽️ Calorie Awareness',
          description:
              'You\'ve exceeded your calorie goal. Consider lighter meal options for dinner.',
          category: 'nutrition',
          icon: localDiningIcon, // CONSTANT
          color: Colors.red,
          difficulty: 'Medium',
          time: 'N/A',
          frequency: 'Daily',
          isPersonalized: true,
        ),
      );
    }

    return personalizedTips;
  }

  Future<void> _loadUserProgress() async {
    // TODO: Load from SharedPreferences or Firebase
    // For now, using empty lists
    favoriteTipIds.clear();
    completedTipIds.clear();
  }

  Future<void> _saveUserProgress() async {
    // TODO: Save to SharedPreferences or Firebase
  }

  void setupSearchListener() {
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterTips();
    });
  }

  void filterTips() {
    final query = searchQuery.value.toLowerCase();
    final category = selectedCategory.value;

    List<HealthTip> filtered = allTips;

    // Filter by category
    if (category != 'all') {
      filtered = filtered.where((tip) => tip.category == category).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((tip) {
        return tip.title.toLowerCase().contains(query) ||
            tip.description.toLowerCase().contains(query) ||
            tip.category.toLowerCase().contains(query);
      }).toList();
    }

    // Sort: Personalized first, then favorites, then by difficulty
    filtered.sort((a, b) {
      if (a.isPersonalized && !b.isPersonalized) return -1;
      if (!a.isPersonalized && b.isPersonalized) return 1;
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return _getDifficultyValue(
        a.difficulty,
      ).compareTo(_getDifficultyValue(b.difficulty));
    });

    filteredTips.assignAll(filtered);
  }

  int _getDifficultyValue(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 0;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    filterTips();
  }

  void toggleFavorite(int tipId) {
    final tipIndex = allTips.indexWhere((tip) => tip.id == tipId);
    if (tipIndex != -1) {
      final tip = allTips[tipIndex];
      final updatedTip = tip.copyWith(isFavorite: !tip.isFavorite);
      allTips[tipIndex] = updatedTip;

      if (updatedTip.isFavorite) {
        favoriteTipIds.add(tipId);
      } else {
        favoriteTipIds.remove(tipId);
      }

      filterTips();
      _saveUserProgress();
      update();
    }
  }

  void markAsCompleted(int tipId) {
    final tipIndex = allTips.indexWhere((tip) => tip.id == tipId);
    if (tipIndex != -1) {
      final tip = allTips[tipIndex];
      final updatedTip = tip.copyWith(isCompleted: !tip.isCompleted);
      allTips[tipIndex] = updatedTip;

      if (updatedTip.isCompleted) {
        completedTipIds.add(tipId);
        Get.snackbar(
          '🎉 Tip Completed!',
          'Great job! Keep up the good work.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        completedTipIds.remove(tipId);
      }

      filterTips();
      _saveUserProgress();
      update();
    }
  }

  void clearFilters() {
    searchController.clear();
    selectedCategory.value = 'all';
    filterTips();
  }

  int get totalTipsCount => allTips.length;
  int get personalizedTipsCount =>
      allTips.where((tip) => tip.isPersonalized).length;
  int get completedTipsCount => completedTipIds.length;
  int get favoriteTipsCount => favoriteTipIds.length;

  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'nutrition':
        return 'Nutrition 🍎';
      case 'exercise':
        return 'Exercise 🏃‍♂️';
      case 'hydration':
        return 'Hydration 🚰';
      case 'sleep':
        return 'Sleep 💤';
      case 'mental':
        return 'Mental Health 🧠';
      case 'general':
        return 'General 🌟';
      default:
        return 'All Tips';
    }
  }

  Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ========== HEALTH TIPS SCREEN ==========
class HealthTipsScreen extends StatelessWidget {
  HealthTipsScreen({super.key});

  final HealthTipsController controller = Get.put(HealthTipsController());
  final HealthController healthController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Tips & Recommendations"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(refreshIcon), // CONSTANT
            onPressed: controller.loadTips,
            tooltip: 'Refresh Tips',
          ),
          IconButton(
            icon: Icon(bookmarkIcon), // CONSTANT
            onPressed: () => _showFavorites(context),
            tooltip: 'View Favorites',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with stats
              _buildHeader(),

              // Search Bar
              _buildSearchBar(),

              // Category Filter
              _buildCategoryFilter(),

              // Statistics Card
              _buildStatistics(),

              // Tips List - FIXED: No Expanded
              _buildTipsList(),

              // Add some bottom padding
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRandomTip(context),
        icon: Icon(autoAwesomeIcon), // CONSTANT
        label: const Text("Quick Tip"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personalized Health Tips",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            return Text(
              _getPersonalizedMessage(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final stepsProgress = healthController.stepsProgress;
            final caloriesProgress = healthController.caloriesProgress;
            final waterProgress = healthController.waterProgress;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _miniProgress("Steps", stepsProgress)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniProgress("Calories", caloriesProgress),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _miniProgress("Water", waterProgress)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on your daily progress',
                  style: TextStyle(
                    fontSize: 11,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _miniProgress(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.2),
          color: Colors.white,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 2),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search health tips...',
          prefixIcon: Icon(searchIcon), // CONSTANT
          suffixIcon: Obx(() {
            if (controller.searchQuery.isNotEmpty) {
              return IconButton(
                icon: Icon(clearIcon), // CONSTANT
                onPressed: () {
                  controller.searchController.clear();
                  controller.filterTips();
                },
              );
            }
            return const SizedBox(width: 0, height: 0);
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];

          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(controller.getCategoryDisplayName(category)),
                selected: isSelected,
                onSelected: (_) => controller.selectCategory(category),
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100, width: 1),
        ),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(analyticsIcon, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  "Your Progress Overview",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  title: 'Total Tips',
                  value: controller.totalTipsCount.toString(),
                  color: Colors.blue,
                  iconWidget: Icon(
                    libraryBooksIcon,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                _buildStatCard(
                  title: 'Personalized',
                  value: controller.personalizedTipsCount.toString(),
                  color: Colors.amber,
                  iconWidget: Icon(
                    starIcon,
                    size: 20,
                    color: Colors.amber.shade700,
                  ),
                ),
                _buildStatCard(
                  title: 'Completed',
                  value: controller.completedTipsCount.toString(),
                  color: Colors.green,
                  iconWidget: Icon(
                    checkCircleIcon,
                    size: 20,
                    color: Colors.green,
                  ),
                ),
                Obx(
                  () => _buildStatCard(
                    title: 'Favorites',
                    value: controller.favoriteTipsCount.toString(),
                    color: Colors.red,
                    iconWidget: Icon(
                      controller.favoriteTipsCount > 0
                          ? favoriteIcon
                          : Icons.favorite_border,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            // Progress Bar (if any completed)
            Obx(() {
              if (controller.completedTipsCount > 0) {
                final progress =
                    controller.completedTipsCount / controller.totalTipsCount;
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Completion Progress",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    "${(progress * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: Colors.blue.shade100,
                                  color: Colors.blue,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Widget iconWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.filteredTips.isEmpty) {
        return _buildEmptyState();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Available Tips (${controller.filteredTips.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...controller.filteredTips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _tipCard(tip),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  Widget _tipCard(HealthTip tip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showTipDetail(tip),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tip.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tip.icon, color: tip.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tip.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                tip.isFavorite
                                    ? favoriteIcon
                                    : Icons.favorite_border,
                                color: tip.isFavorite
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () =>
                                  controller.toggleFavorite(tip.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        if (tip.isPersonalized) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: const Text(
                              'Personalized',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(tip.difficulty),
                    backgroundColor: controller.getDifficultyColor(
                      tip.difficulty,
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(tip.time),
                    backgroundColor: Colors.grey[200],
                    labelStyle: const TextStyle(fontSize: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(width: 8),
                  if (tip.isCompleted)
                    Chip(
                      label: const Text('COMPLETED'),
                      backgroundColor: Colors.green.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      tip.isCompleted
                          ? checkCircleIcon
                          : Icons.check_circle_outline,
                      color: tip.isCompleted ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => controller.markAsCompleted(tip.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(tipsUpdatesIcon, size: 80, color: Colors.blue[200]),
            const SizedBox(height: 20),
            const Text(
              "No Tips Found",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Try changing filters or search terms",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.clearFilters,
              child: const Text("Clear Filters"),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipDetail(HealthTip tip) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Draggable Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tip.isPersonalized) const SizedBox(height: 4),
                              if (tip.isPersonalized)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: const Text(
                                    'Personalized Recommendation',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Details Grid
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _detailCard(timerIcon, 'Time Required', tip.time),
                        _detailCard(
                          differenceIcon,
                          'Difficulty',
                          tip.difficulty,
                          color: controller.getDifficultyColor(tip.difficulty),
                        ),
                        _detailCard(repeatIcon, 'Frequency', tip.frequency),
                        _detailCard(
                          categoryIcon,
                          'Category',
                          controller.getCategoryDisplayName(tip.category),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              controller.toggleFavorite(tip.id);
                              Get.back();
                              Get.snackbar(
                                tip.isFavorite
                                    ? 'Removed from Favorites'
                                    : 'Added to Favorites',
                                tip.isFavorite
                                    ? 'Tip removed from favorites'
                                    : 'Tip added to favorites',
                                backgroundColor: tip.isFavorite
                                    ? Colors.grey
                                    : Colors.blue,
                                colorText: Colors.white,
                              );
                            },
                            icon: Icon(
                              tip.isFavorite
                                  ? favoriteIcon
                                  : Icons.favorite_border,
                              color: tip.isFavorite ? Colors.red : Colors.blue,
                            ),
                            label: Text(
                              tip.isFavorite
                                  ? 'Remove Favorite'
                                  : 'Add to Favorites',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              controller.markAsCompleted(tip.id);
                              Get.back();
                            },
                            icon: Icon(checkCircleIcon, color: Colors.white),
                            label: const Text(
                              'Mark Complete',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tip.isCompleted
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color ?? Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "      $value",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showRandomTip(BuildContext context) {
    if (controller.allTips.isEmpty) return;

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % controller.allTips.length;
    final randomTip = controller.allTips[randomIndex];

    _showTipDetail(randomTip);
  }

  void _showFavorites(BuildContext context) {
    final favoriteTips = controller.allTips
        .where((tip) => tip.isFavorite)
        .toList();

    if (favoriteTips.isEmpty) {
      Get.snackbar(
        'No Favorites',
        'You haven\'t added any tips to favorites yet.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    Get.to(
      () => Scaffold(
        appBar: AppBar(title: const Text('Favorite Tips')),
        body: favoriteTips.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No favorite tips yet',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteTips.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _tipCard(favoriteTips[index]),
                  );
                },
              ),
      ),
    );
  }

  String _getPersonalizedMessage() {
    final stepsProgress = healthController.stepsProgress;
    final caloriesProgress = healthController.caloriesProgress;
    final bmi = healthController.bmi;

    if (stepsProgress < 0.3) {
      return "You're below your step goal. Try our walking tips!";
    } else if (caloriesProgress > 1.0) {
      return "You've exceeded calorie goal. Check nutrition tips!";
    } else if (bmi > 25) {
      return "Focus on balanced diet and exercise for healthy weight.";
    } else if (stepsProgress > 0.8) {
      return "Great activity level! Keep up the good work.";
    } else {
      return "Here are personalized tips to improve your health.";
    }
  }
}
