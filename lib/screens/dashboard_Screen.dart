import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:health_tracker_fyp/screens/activity_Screen.dart';
import 'package:health_tracker_fyp/screens/profileScreen.dart';
import 'package:health_tracker_fyp/screens/HistoryScreen.dart';
import 'package:health_tracker_fyp/screens/Health_Statistics_Screen.dart';
import 'package:health_tracker_fyp/screens/meal/meal_log_screen.dart';
import 'package:health_tracker_fyp/screens/goals/goal_setting_screen.dart';
import 'package:health_tracker_fyp/screens/health_tips_screen.dart';

class DashboardScreen extends StatelessWidget {
  final HealthController healthController = Get.find();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Obx(
          () => Row(
            children: [
              Text(
                "Dashboard",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(width: 8),
              if (healthController.newRecommendationsCount.value > 0)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${healthController.newRecommendationsCount.value}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.health_and_safety, color: Color(0xFF2196F3)),
            onPressed: () => Get.to(() => HealthTipsScreen()),
            tooltip: "Health Tips",
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF666666)),
            onPressed: () {
              healthController.loadAllUserData();
              healthController.generatePersonalizedRecommendations();
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Obx(() {
        if (healthController.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF2196F3)),
                SizedBox(height: 16),
                Text(
                  "Loading your health data...",
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // ================= GREETING CARD =================
              _buildGreetingCard(),
              SizedBox(height: 20),

              // ================= HEALTH SNAPSHOT =================
              _buildHealthSnapshot(),
              SizedBox(height: 24),

              // ================= QUICK STATS =================
              _buildQuickStats(),
              SizedBox(height: 24),

              // ================= RECOMMENDATIONS SECTION =================
              _buildRecommendationsSection(),
              SizedBox(height: 24),

              // ================= QUICK ACTIONS =================
              _buildQuickActions(),
            ],
          ),
        );
      }),
    );
  }

  // ================= GREETING CARD =================
  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            healthController.userName.value,
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            healthController.dailyMotivation.value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ================= HEALTH SNAPSHOT =================
  Widget _buildHealthSnapshot() {
    final stepsProgress = healthController.stepsProgress;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Chip(
                label: Text(
                  "${(stepsProgress * 100).toInt()}%",
                  style: TextStyle(
                    color: stepsProgress >= 0.8
                        ? Colors.green
                        : Color(0xFF2196F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: stepsProgress >= 0.8
                    ? Colors.green.withOpacity(0.1)
                    : Color(0xFF2196F3).withOpacity(0.1),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Steps Progress
          Row(
            children: [
              _buildProgressIndicator(stepsProgress, Color(0xFF2196F3)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Steps",
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${healthController.dailySteps.value} / ${healthController.stepsGoal.value}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                Icons.local_fire_department,
                "${healthController.burnedCalories.value.toInt()}",
                "Cal Burned",
                Color(0xFFFF9800),
              ),
              _buildMiniStat(
                Icons.restaurant,
                "${healthController.consumedCalories.value}",
                "Cal Eaten",
                Color(0xFF4CAF50),
              ),
              _buildMiniStat(
                Icons.directions_walk,
                healthController.distanceKm.value.toStringAsFixed(1),
                "km Walked",
                Color(0xFF2196F3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            color: color,
            backgroundColor: color.withOpacity(0.2),
          ),
        ),
        Text(
          "${(progress * 100).toInt()}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
    );
  }

  // ================= QUICK STATS =================
  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health Metrics",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timelapse, size: 14, color: Color(0xFF666666)),
                    SizedBox(width: 4),
                    Text(
                      "Today",
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Health Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  "💧 Water",
                  "${healthController.waterIntake.value}ml",
                  "${(healthController.waterProgress * 100).toInt()}%",
                  healthController.waterProgress,
                  Color(0xFF2196F3),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  "😴 Sleep",
                  "${healthController.sleepHours.value}h",
                  "${(healthController.sleepProgress * 100).toInt()}%",
                  healthController.sleepProgress,
                  Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String title,
    String value,
    String progressText,
    double progress,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  // ================= RECOMMENDATIONS SECTION =================
  Widget _buildRecommendationsSection() {
    final urgent = healthController.urgentRecommendation;
    final recommendations = healthController.personalizedRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgent Recommendation
        if (urgent != null) ...[
          _buildUrgentRecommendation(urgent),
          SizedBox(height: 16),
        ],

        // Recommendations Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recommendations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (recommendations.isNotEmpty)
              TextButton(
                onPressed: () => Get.to(() => HealthTipsScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                ),
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),

        // Recommendations List
        // Recommendations List section mein:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommendations.isEmpty)
              _buildEmptyRecommendations()
            else ...[
              for (int i = 0; i < recommendations.length && i < 2; i++)
                _buildRecommendationItem(recommendations[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentRecommendation(Map<String, dynamic> recommendation) {
    Color getColorByPriority(int priority) {
      switch (priority) {
        case 1:
          return Color(0xFFE53935);
        case 2:
          return Color(0xFFFF9800);
        default:
          return Color(0xFF2196F3);
      }
    }

    final color = getColorByPriority(recommendation['priority'] ?? 3);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(Icons.warning, size: 14, color: Colors.white),
              ),
              SizedBox(width: 10),
              Text(
                "Priority Recommendation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            recommendation['title'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            recommendation['description'],
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          if (recommendation.containsKey('action'))
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () => _handleRecommendationAction(recommendation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Take Action"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final color = _getCategoryColor(recommendation['category'] ?? 'general');

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Get.to(() => HealthTipsScreen()),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(recommendation['category']),
            size: 20,
            color: color,
          ),
        ),
        title: Text(
          recommendation['title'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text(
          recommendation['description'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        minLeadingWidth: 0,
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.health_and_safety, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            "No recommendations yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Complete your profile and log activities to get personalized tips",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  void _handleRecommendationAction(Map<String, dynamic> recommendation) {
    final action = recommendation['action'];
    if (action == 'start_walking') {
      Get.to(() => Activityscreen());
    } else if (action == 'log_water') {
      healthController.updateHealthData(
        water: healthController.waterIntake.value + 250,
      );
      Get.snackbar(
        "Water Added",
        "250ml water logged!",
        backgroundColor: Color(0xFF2196F3),
        colorText: Colors.white,
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'exercise':
        return Color(0xFF4CAF50);
      case 'nutrition':
        return Color(0xFFFF9800);
      case 'hydration':
        return Color(0xFF2196F3);
      case 'sleep':
        return Color(0xFF7B1FA2);
      case 'goal':
        return Color(0xFF009688);
      default:
        return Color(0xFF666666);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'exercise':
        return Icons.directions_run;
      case 'nutrition':
        return Icons.restaurant;
      case 'hydration':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'goal':
        return Icons.flag;
      default:
        return Icons.health_and_safety;
    }
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(
        Icons.directions_walk,
        "Activity",
        Color(0xFF2196F3),
        Activityscreen(),
      ),
      _ActionItem(
        Icons.restaurant,
        "Meals",
        Color(0xFF4CAF50),
        MealLogScreen(),
      ),
      _ActionItem(
        Icons.bar_chart,
        "Stats",
        Color(0xFF9C27B0),
        HealthStatisticsScreen(),
      ),
      _ActionItem(Icons.flag, "Goals", Color(0xFFFF9800), GoalSettingScreen()),
      _ActionItem(Icons.person, "Profile", Color(0xFF009688), ProfileScreen()),
      _ActionItem(Icons.history, "History", Color(0xFF795548), HistoryScreen()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildActionCard(actions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(_ActionItem item) {
    return GestureDetector(
      onTap: () => Get.to(() => item.screen),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 22, color: item.color),
            ),
            SizedBox(height: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;

  _ActionItem(this.icon, this.label, this.color, this.screen);
}
