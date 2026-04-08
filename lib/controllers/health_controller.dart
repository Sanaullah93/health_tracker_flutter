import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthController extends GetxController {
  // ========== USER DATA ==========
  RxString userName = "".obs;
  RxString userEmail = "".obs;
  RxInt userAge = 0.obs;
  RxString userGender = "Male".obs;
  RxString userHeight = "".obs;
  RxString userWeight = "".obs;

  // NEW: For recommendations
  RxString userGoal =
      "".obs; // 'weight_loss', 'muscle_gain', 'maintenance', 'fitness'
  RxString activityLevel = "moderate"
      .obs; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  RxInt waterIntake = 0.obs; // in ml
  RxDouble sleepHours = 7.0.obs; // hours

  // ========== ACTIVITY DATA ==========
  RxInt dailySteps = 0.obs;
  RxDouble burnedCalories = 0.0.obs;
  RxDouble distanceKm = 0.0.obs;

  // ========== GOALS DATA ==========
  RxInt stepsGoal = 10000.obs;
  RxInt caloriesGoal = 2000.obs;
  RxInt waterGoal = 2000.obs; // 2 liters default
  RxDouble sleepGoal = 8.0.obs; // 8 hours default

  // ========== MEALS DATA ==========
  RxInt consumedCalories = 0.obs;
  RxList<String> todayMeals = <String>[].obs;

  // NEW: For meal analysis
  RxMap<String, int> mealTypes = <String, int>{
    'breakfast': 0,
    'lunch': 0,
    'dinner': 0,
    'snacks': 0,
  }.obs;

  // ========== RECOMMENDATION DATA ==========
  RxList<Map<String, dynamic>> personalizedRecommendations =
      <Map<String, dynamic>>[].obs;
  RxInt newRecommendationsCount = 0.obs;
  RxList<Map<String, dynamic>> todayHealthTips = <Map<String, dynamic>>[].obs;
  RxString dailyMotivation = "".obs;

  // ========== LOADING STATES ==========
  RxBool isLoading = false.obs;

  // ========== FIREBASE INSTANCES ==========
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== INITIALIZE EVERYTHING ==========
  @override
  void onInit() {
    super.onInit();
    loadAllUserData();
    _initializeRecommendations();
  }

  bool get isReady => _firestore != null && _auth != null;

  // ========== INITIALIZE RECOMMENDATIONS ==========
  void _initializeRecommendations() {
    // Generate daily motivation
    _generateDailyMotivation();

    // Generate recommendations after data loads
    Future.delayed(Duration(seconds: 2), () {
      generatePersonalizedRecommendations();
    });
  }

  // ========== LOAD ALL USER DATA FROM FIRESTORE ==========
  Future<void> loadAllUserData() async {
    try {
      isLoading(true);
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Load Profile Data
      final profileDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        userName.value = data['name'] ?? user.displayName ?? "User";
        userEmail.value = data['email'] ?? user.email ?? "";
        userAge.value = data['age'] ?? 0;
        userGender.value = data['gender'] ?? "Male";
        userHeight.value = data['height']?.toString() ?? "";
        userWeight.value = data['weight']?.toString() ?? "";

        // NEW: Load recommendation-specific data
        userGoal.value = data['goal'] ?? 'fitness';
        activityLevel.value = data['activityLevel'] ?? 'moderate';
        waterIntake.value = data['waterIntake'] ?? 0;
        sleepHours.value = (data['sleepHours'] ?? 7.0).toDouble();
        waterGoal.value = data['waterGoal'] ?? 2000;
        sleepGoal.value = (data['sleepGoal'] ?? 8.0).toDouble();

        // Load goals
        stepsGoal.value = data['stepsGoal'] ?? 10000;
        caloriesGoal.value = data['caloriesGoal'] ?? 2000;
      }

      // 2. Load Today's Activity
      final today = DateTime.now().toIso8601String().split('T')[0];
      final activityDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("stepsData")
          .doc(today)
          .get();

      if (activityDoc.exists) {
        final activityData = activityDoc.data()!;
        dailySteps.value = activityData['steps'] ?? 0;
        burnedCalories.value = activityData['calories'] ?? 0.0;
        distanceKm.value = activityData['distance'] ?? 0.0;
      }

      // 3. Load Today's Meals
      final mealsDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("meals")
          .doc(today)
          .get();

      if (mealsDoc.exists) {
        final mealsData = mealsDoc.data()!;
        consumedCalories.value = 0;
        todayMeals.clear();

        // Reset meal types
        mealTypes.value = {
          'breakfast': 0,
          'lunch': 0,
          'dinner': 0,
          'snacks': 0,
        };

        // Calculate total calories and meal distribution
        ['breakfast', 'lunch', 'dinner', 'snacks'].forEach((mealType) {
          if (mealsData[mealType] != null) {
            final meal = mealsData[mealType];
            final calories = (meal['calories'] ?? 0) as int;
            consumedCalories.value += calories;
            mealTypes[mealType] = calories;
            todayMeals.add("${mealType}: ${meal['food']} ($calories cal)");
          }
        });
      }

      // 4. Load Today's Health Data (water, sleep)
      final healthDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("healthData")
          .doc(today)
          .get();

      if (healthDoc.exists) {
        final healthData = healthDoc.data()!;
        waterIntake.value = healthData['waterIntake'] ?? waterIntake.value;
        sleepHours.value = (healthData['sleepHours'] ?? sleepHours.value)
            .toDouble();
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      isLoading(false);
    }
  }

  // ========== UPDATE PROFILE ==========
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      // Update local values
      userName.value = profileData['name'] ?? userName.value;
      userAge.value = profileData['age'] ?? userAge.value;
      userGender.value = profileData['gender'] ?? userGender.value;
      userHeight.value = profileData['height']?.toString() ?? userHeight.value;
      userWeight.value = profileData['weight']?.toString() ?? userWeight.value;
      userGoal.value = profileData['goal'] ?? userGoal.value;
      activityLevel.value = profileData['activityLevel'] ?? activityLevel.value;

      // Regenerate recommendations
      generatePersonalizedRecommendations();
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  // ========== UPDATE HEALTH DATA (Water, Sleep) ==========
  Future<void> updateHealthData({int? water, double? sleep}) async {
    try {
      if (water != null) waterIntake.value = water;
      if (sleep != null) sleepHours.value = sleep;

      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("healthData")
          .doc(today)
          .set({
            'waterIntake': waterIntake.value,
            'sleepHours': sleepHours.value,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Regenerate recommendations
      generatePersonalizedRecommendations();
    } catch (e) {
      print("Error updating health data: $e");
    }
  }

  // ========== UPDATE STEPS ==========
  Future<void> updateSteps(int newSteps) async {
    try {
      dailySteps.value = newSteps;
      burnedCalories.value = newSteps * 0.04;
      distanceKm.value = (newSteps * 0.762) / 1000;

      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("stepsData")
          .doc(today)
          .set({
            'steps': dailySteps.value,
            'calories': burnedCalories.value,
            'distance': distanceKm.value,
            'goal': stepsGoal.value,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Regenerate recommendations
      generatePersonalizedRecommendations();
    } catch (e) {
      print("Error updating steps: $e");
    }
  }

  // ========== UPDATE GOALS ==========
  Future<void> updateGoals(int newStepsGoal, int newCaloriesGoal) async {
    try {
      stepsGoal.value = newStepsGoal;
      caloriesGoal.value = newCaloriesGoal;

      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection("users").doc(user.uid).set({
        'stepsGoal': newStepsGoal,
        'caloriesGoal': newCaloriesGoal,
      }, SetOptions(merge: true));

      // Regenerate recommendations
      generatePersonalizedRecommendations();
    } catch (e) {
      print("Error updating goals: $e");
    }
  }

  // ========== ADD MEAL ==========
  Future<void> addMeal(
    String mealType,
    String food,
    int calories, {
    required DateTime time,
  }) async {
    try {
      // Update local state first
      consumedCalories.value += calories;
      todayMeals.add("$mealType: $food ($calories cal)");

      // Update meal type distribution
      if (mealTypes.containsKey(mealType)) {
        mealTypes[mealType] = (mealTypes[mealType] ?? 0) + calories;
      }

      // Save to Firestore
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("meals")
          .doc(today)
          .set({
            mealType: {
              'food': food,
              'calories': calories,
              'time': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));

      print("Meal saved successfully to Firestore");

      // Regenerate recommendations
      generatePersonalizedRecommendations();
    } catch (e) {
      print("Error adding meal: $e");
      // Rollback local changes if Firestore fails
      consumedCalories.value -= calories;
      todayMeals.removeLast();
      rethrow; // Propagate the error
    }
  }

  // ========== CALCULATE PROGRESS ==========
  double get stepsProgress {
    if (stepsGoal.value <= 0) return 0.0;
    return (dailySteps.value / stepsGoal.value).clamp(0.0, 1.0);
  }

  double get caloriesProgress {
    if (caloriesGoal.value <= 0) return 0.0;
    return (consumedCalories.value / caloriesGoal.value).clamp(0.0, 1.0);
  }

  double get waterProgress {
    if (waterGoal.value <= 0) return 0.0;
    return (waterIntake.value / waterGoal.value).clamp(0.0, 1.0);
  }

  double get sleepProgress {
    if (sleepGoal.value <= 0) return 0.0;
    return (sleepHours.value / sleepGoal.value).clamp(0.0, 1.0);
  }

  // ========== CALCULATE BMI ==========
  double get bmi {
    if (userWeight.value.isEmpty || userHeight.value.isEmpty) return 0.0;
    try {
      final weight = double.tryParse(userWeight.value) ?? 0;
      final height = double.tryParse(userHeight.value) ?? 0;
      if (height == 0) return 0.0;

      // Convert height from cm to meters
      final heightInMeters = height / 100;
      return weight / (heightInMeters * heightInMeters);
    } catch (e) {
      return 0.0;
    }
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == 0.0) return "Not Calculated";
    if (bmiValue < 18.5) return "Underweight";
    if (bmiValue < 25) return "Normal";
    if (bmiValue < 30) return "Overweight";
    return "Obese";
  }

  // ========== GENERATE PERSONALIZED RECOMMENDATIONS ==========
  void generatePersonalizedRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // 1. Step-based recommendations
    if (dailySteps.value < 5000) {
      recommendations.add({
        'id': 'step_low',
        'title': '🚶 Increase Daily Steps',
        'description':
            'You\'re below 5000 steps. Try taking a 15-minute walk now.',
        'category': 'exercise',
        'priority': 1, // High priority
        'icon': '🚶',
        'action': 'start_walking',
      });
    } else if (dailySteps.value < stepsGoal.value) {
      recommendations.add({
        'id': 'step_goal',
        'title': '🏃 Almost There!',
        'description':
            'You\'re ${stepsGoal.value - dailySteps.value} steps away from your goal.',
        'category': 'exercise',
        'priority': 2,
        'icon': '🏃',
      });
    }

    // 2. Calorie-based recommendations
    if (consumedCalories.value > caloriesGoal.value) {
      recommendations.add({
        'id': 'calorie_high',
        'title': '🍽️ High Calorie Intake',
        'description':
            'You\'ve exceeded your calorie goal by ${consumedCalories.value - caloriesGoal.value} calories.',
        'category': 'nutrition',
        'priority': 1,
        'icon': '🍎',
        'suggestion': 'Consider lighter dinner',
      });
    }

    // 3. Water intake recommendations
    if (waterIntake.value < waterGoal.value * 0.5) {
      recommendations.add({
        'id': 'water_low',
        'title': '💧 Drink More Water',
        'description':
            'You\'ve only had ${waterIntake.value}ml. Aim for ${waterGoal.value}ml daily.',
        'category': 'hydration',
        'priority': 1,
        'icon': '💧',
      });
    }

    // 4. Sleep recommendations
    if (sleepHours.value < 6) {
      recommendations.add({
        'id': 'sleep_low',
        'title': '😴 Need More Sleep',
        'description':
            'Only ${sleepHours.value} hours sleep. Aim for 7-8 hours for better health.',
        'category': 'sleep',
        'priority': 1,
        'icon': '😴',
      });
    }

    // 5. Goal-specific recommendations
    if (userGoal.value == 'weight_loss' && bmi > 25) {
      recommendations.add({
        'id': 'weight_loss',
        'title': '⚖️ Weight Loss Tip',
        'description':
            'For weight loss, try adding 30 minutes of cardio daily.',
        'category': 'goal',
        'priority': 2,
        'icon': '⚖️',
      });
    }

    if (userGoal.value == 'muscle_gain') {
      recommendations.add({
        'id': 'muscle_gain',
        'title': '💪 Protein Intake',
        'description':
            'For muscle gain, ensure adequate protein in every meal.',
        'category': 'nutrition',
        'priority': 2,
        'icon': '💪',
      });
    }

    // 6. Meal pattern recommendations
    final totalCalories = consumedCalories.value;
    if (totalCalories > 0) {
      final breakfastPercent =
          (mealTypes['breakfast'] ?? 0) / totalCalories * 100;
      if (breakfastPercent < 20) {
        recommendations.add({
          'id': 'breakfast_low',
          'title': '🍳 Breakfast Matters',
          'description':
              'Breakfast is only ${breakfastPercent.toStringAsFixed(1)}% of your calories. Aim for 25-30%.',
          'category': 'nutrition',
          'priority': 2,
          'icon': '🍳',
        });
      }
    }

    // Sort by priority (lower number = higher priority)
    recommendations.sort(
      (a, b) => (a['priority'] ?? 3).compareTo(b['priority'] ?? 3),
    );

    // Update observable
    personalizedRecommendations.value = recommendations;
    newRecommendationsCount.value = recommendations.length;

    // Generate health tips
    _generateHealthTips();
  }

  // ========== GET URGENT RECOMMENDATION ==========
  Map<String, dynamic>? get urgentRecommendation {
    if (personalizedRecommendations.isEmpty) return null;
    return personalizedRecommendations.first;
  }

  // ========== GET RECOMMENDATIONS BY CATEGORY ==========
  List<Map<String, dynamic>> getRecommendationsByCategory(String category) {
    if (category == 'all') return personalizedRecommendations;
    return personalizedRecommendations
        .where((rec) => rec['category'] == category)
        .toList();
  }

  // ========== GET HEALTH TIPS (Backward Compatibility) ==========
  List<String> get healthTips {
    return todayHealthTips.map((tip) => tip['title'] as String).toList();
  }

  // ========== GENERATE HEALTH TIPS ==========
  void _generateHealthTips() {
    final tips = <Map<String, dynamic>>[];

    // Add personalized recommendations as tips
    for (final rec in personalizedRecommendations.take(3)) {
      tips.add({
        'title': rec['title'],
        'description': rec['description'],
        'category': rec['category'],
      });
    }

    // Add general tips if we have less than 3
    if (tips.length < 3) {
      final generalTips = [
        {
          'title': '🌟 Stay Consistent',
          'description': 'Consistency is key to achieving health goals.',
          'category': 'general',
        },
        {
          'title': '📱 Track Daily',
          'description':
              'Log your meals and activities daily for best results.',
          'category': 'general',
        },
        {
          'title': '🎯 Set Realistic Goals',
          'description': 'Small, achievable goals lead to long-term success.',
          'category': 'general',
        },
      ];

      for (int i = tips.length; i < 3; i++) {
        if (i < generalTips.length) {
          tips.add(generalTips[i]);
        }
      }
    }

    todayHealthTips.value = tips;
  }

  // ========== GENERATE DAILY MOTIVATION ==========
  void _generateDailyMotivation() {
    final motivators = [
      "💪 Small steps every day lead to big changes!",
      "🌅 Start your day with positivity and purpose!",
      "🍎 Your body thanks you for healthy choices!",
      "🚶‍♂️ Every step counts towards your goal!",
      "🌟 You're stronger than you think!",
      "🌿 Nourish your body, empower your mind!",
      "🏃‍♀️ Progress, not perfection!",
      "💧 Hydration is happiness for your cells!",
      "😴 Good sleep = Better tomorrow!",
      "🎯 Focus on consistency, not intensity!",
    ];

    // Use day of month to select motivation (changes daily)
    final day = DateTime.now().day;
    dailyMotivation.value = motivators[day % motivators.length];
  }

  // ========== GET CALORIE DEFICIT/SURPLUS ==========
  int get calorieBalance {
    return consumedCalories.value -
        (burnedCalories.value.toInt() + caloriesGoal.value);
  }

  // ========== GET ACTIVITY LEVEL SCORE ==========
  double get activityScore {
    final stepScore = (dailySteps.value / 10000).clamp(0.0, 1.0);
    final calorieBurnScore = (burnedCalories.value / 500).clamp(0.0, 1.0);
    return (stepScore * 0.7 + calorieBurnScore * 0.3);
  }

  // ========== RESET DAILY DATA ==========
  void resetDailyData() {
    // Note: This is for local reset. Firebase data persists.
    dailySteps.value = 0;
    burnedCalories.value = 0.0;
    distanceKm.value = 0.0;
    consumedCalories.value = 0;
    todayMeals.clear();
    waterIntake.value = 0;
    sleepHours.value = 7.0;
    mealTypes.value = {'breakfast': 0, 'lunch': 0, 'dinner': 0, 'snacks': 0};

    // Regenerate recommendations
    generatePersonalizedRecommendations();
  }
}
