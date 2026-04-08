import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/screens/activity_Screen.dart';
import 'package:health_tracker_fyp/screens/dashboard_screen.dart';
import 'package:health_tracker_fyp/screens/health_tips_screen.dart';
import 'package:health_tracker_fyp/screens/meal/meal_log_screen.dart';
import 'package:health_tracker_fyp/screens/profileScreen.dart';
import 'package:health_tracker_fyp/screens/Health_Statistics_Screen.dart';
import 'package:health_tracker_fyp/screens/HistoryScreen.dart';
import 'package:health_tracker_fyp/screens/goals/goal_setting_screen.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:health_tracker_fyp/screens/meal/meal_history_screen.dart';
import 'package:health_tracker_fyp/screens/reminders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final HealthController healthController = Get.put(HealthController());

  // List of main screens
  final List<Widget> _screens = [
    DashboardScreen(),
    const Activityscreen(),
    const MealLogScreen(),
    const ProfileScreen(),
  ];

  // Bottom navigation items with improved styling
  static final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(5),
        child: const Icon(Icons.dashboard_outlined, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.dashboard, size: 24, color: Colors.blue),
      ),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.directions_walk_outlined, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_walk, size: 24, color: Colors.green),
      ),
      label: 'Activity',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.restaurant_outlined, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restaurant, size: 24, color: Colors.orange),
      ),
      label: 'Meals',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.person_outline, size: 24),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person, size: 24, color: Colors.purple),
      ),
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Quick actions for floating button with GetX
  void _showQuickActions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Access features quickly",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 25),
              // Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _quickActionButton(
                    Icons.bar_chart,
                    "Statistics",
                    Colors.blue,
                    () => Get.to(() => const HealthStatisticsScreen()),
                  ),
                  _quickActionButton(
                    Icons.history,
                    "History",
                    Colors.green,
                    () => Get.to(() => const MealHistoryScreen()),
                  ),
                  _quickActionButton(
                    Icons.flag,
                    "Goals",
                    Colors.orange,
                    () => Get.to(() => const GoalSettingScreen()),
                  ),
                  _quickActionButton(
                    Icons.notifications,
                    "Reminders",
                    Colors.purple,
                    () => Get.to(() => RemindersScreen()),
                  ),

                  // _quickActionButton(
                  //   Icons.settings,
                  //   "Settings",
                  //   Colors.grey,
                  //   () => Get.to(() => SettingsScreen()),
                  // ),
                  // Quick Actions mein yeh button add karo:
                  _quickActionButton(
                    Icons.tips_and_updates,
                    "Health Tips",
                    Colors.teal,
                    () => Get.to(() => HealthTipsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Today's Summary
              Obx(() {
                final steps = healthController.dailySteps.value;
                final goal = healthController.stepsGoal.value;
                final progress = goal > 0
                    ? (steps / goal).clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_walk, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Steps",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              "$steps / $goal",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              color: Colors.blue,
                              backgroundColor: Colors.blue[100],
                            ),
                            Center(
                              child: Text(
                                "${(progress * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  Widget _quickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderOption(IconData icon, String label, bool enabled) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      trailing: Switch(
        value: enabled,
        onChanged: (value) {},
        activeThumbColor: Colors.blue,
      ),
    );
  }

  void _showHealthTips() {
    Get.defaultDialog(
      title: "💡 Health Tips",
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("• Drink 8 glasses of water daily"),
            SizedBox(height: 8),
            Text("• Take a 5-minute walk every hour"),
            SizedBox(height: 8),
            Text("• Eat fruits and vegetables with every meal"),
            SizedBox(height: 8),
            Text("• Get 7-8 hours of sleep daily"),
            SizedBox(height: 8),
            Text("• Practice deep breathing for stress"),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Close")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Current screen body
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // Bottom Navigation Bar with improved design
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
            showUnselectedLabels: true,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
          ),
        ),
      ),

      // Floating Action Button (Quick Access) with animation
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        shape: const CircleBorder(),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 29),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
