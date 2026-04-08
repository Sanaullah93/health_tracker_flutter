import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:health_tracker_fyp/screens/authentication/login_screen.dart';
import 'package:health_tracker_fyp/screens/health_tips_screen.dart'; // NEW IMPORT
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final HealthController healthController = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PageController _pageController = PageController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _goalController = TextEditingController(); // NEW
  final TextEditingController _activityController =
      TextEditingController(); // NEW

  String _selectedGender = "Male";
  String _selectedGoal = "fitness"; // NEW
  String _selectedActivityLevel = "moderate"; // NEW
  bool _isLoading = false;
  int _currentPage = 0;

  // NEW: For recommendation settings
  bool _enableSmartTips = true;
  bool _enableNotifications = true;
  bool _enableWeeklyReports = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    _nameController.text = healthController.userName.value;
    _ageController.text = healthController.userAge.value.toString();
    _heightController.text = healthController.userHeight.value;
    _weightController.text = healthController.userWeight.value;
    _selectedGender = healthController.userGender.value;
    _selectedGoal = healthController.userGoal.value.isNotEmpty
        ? healthController.userGoal.value
        : "fitness";
    _selectedActivityLevel = healthController.activityLevel.value;
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showToast("Please enter your name", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileData = {
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'height': _heightController.text,
        'weight': _weightController.text,
        'goal': _selectedGoal, // NEW
        'activityLevel': _selectedActivityLevel, // NEW
        'updatedAt': DateTime.now(),
      };

      await healthController.updateProfile(profileData);

      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text);
      }

      // Generate new recommendations based on updated profile
      healthController.generatePersonalizedRecommendations();

      _showToast("Profile updated successfully", Colors.green);
      Get.back();
    } catch (e) {
      _showToast("Update failed", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // Add this function in _ProfileScreenState class (anywhere before build method):

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                "Logout",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _auth.signOut();
                          Get.offAll(() => const LoginScreen());
                        } catch (e) {
                          _showToast("Logout failed", Colors.red);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Edit Profile Modal with More Fields
  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 50),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildEditField(
                            controller: _nameController,
                            label: "Full Name",
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          _buildEditField(
                            controller: _ageController,
                            label: "Age",
                            icon: Icons.cake_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _buildEditField(
                            controller: _heightController,
                            label: "Height (cm)",
                            icon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _buildEditField(
                            controller: _weightController,
                            label: "Weight (kg)",
                            icon: Icons.monitor_weight_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _buildGenderSelector(),
                          const SizedBox(height: 20),

                          // NEW: Goal Selector
                          _buildDropdownSelector(
                            label: "Primary Goal",
                            icon: Icons.flag_rounded,
                            value: _selectedGoal,
                            items: [
                              "weight_loss",
                              "muscle_gain",
                              "maintenance",
                              "fitness",
                              "endurance",
                            ],
                            displayNames: {
                              "weight_loss": "Weight Loss",
                              "muscle_gain": "Muscle Gain",
                              "maintenance": "Maintenance",
                              "fitness": "General Fitness",
                              "endurance": "Endurance",
                            },
                            onChanged: (value) {
                              setState(() => _selectedGoal = value!);
                            },
                          ),
                          const SizedBox(height: 20),

                          // NEW: Activity Level Selector
                          _buildDropdownSelector(
                            label: "Activity Level",
                            icon: Icons.directions_run_rounded,
                            value: _selectedActivityLevel,
                            items: [
                              "sedentary",
                              "light",
                              "moderate",
                              "active",
                              "very_active",
                            ],
                            displayNames: {
                              "sedentary": "Sedentary (Little exercise)",
                              "light": "Light (1-3 days/week)",
                              "moderate": "Moderate (3-5 days/week)",
                              "active": "Active (6-7 days/week)",
                              "very_active": "Very Active (Athlete)",
                            },
                            onChanged: (value) {
                              setState(() => _selectedActivityLevel = value!);
                            },
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NEW: Dropdown Selector Widget
  Widget _buildDropdownSelector({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Map<String, String> displayNames,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        displayNames[item] ?? item,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.isNotEmpty ? value : "--",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.blue),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderChip("Male", Icons.male_rounded),
            const SizedBox(width: 10),
            _genderChip("Female", Icons.female_rounded),
            const SizedBox(width: 10),
            _genderChip("Other", Icons.transgender_rounded),
          ],
        ),
      ],
    );
  }

  Widget _genderChip(String label, IconData icon) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: BMI Card Widget
  Widget _buildBMICard() {
    final bmi = healthController.bmi;
    final category = healthController.bmiCategory;

    Color getBMIColor() {
      if (bmi == 0.0) return Colors.grey;
      if (bmi < 18.5) return Colors.blue;
      if (bmi < 25) return Colors.green;
      if (bmi < 30) return Colors.orange;
      return Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            getBMIColor().withOpacity(0.1),
            getBMIColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getBMIColor().withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getBMIColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_weight_rounded,
                  color: getBMIColor(),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Body Mass Index",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bmi > 0 ? bmi.toStringAsFixed(1) : "N/A",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: getBMIColor(),
                    ),
                  ),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: getBMIColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Healthy Range:",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    "18.5 - 24.9",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: bmi > 0 ? (bmi / 40).clamp(0.0, 1.0) : 0.0,
            backgroundColor: Colors.grey[200],
            color: getBMIColor(),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Underweight",
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
              Text(
                "Normal",
                style: TextStyle(fontSize: 10, color: Colors.green),
              ),
              Text(
                "Overweight",
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
              Text("Obese", style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Recommendation Settings Widget
  Widget _buildRecommendationSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.recommend_rounded,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "AI Recommendations Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          _buildSettingSwitch(
            title: "Enable Smart Health Tips",
            subtitle: "Get personalized recommendations",
            value: _enableSmartTips,
            icon: Icons.health_and_safety_rounded,
            onChanged: (value) {
              setState(() => _enableSmartTips = value);
            },
          ),

          const SizedBox(height: 12),

          _buildSettingSwitch(
            title: "Daily Notifications",
            subtitle: "Receive daily health tips",
            value: _enableNotifications,
            icon: Icons.notifications_rounded,
            onChanged: (value) {
              setState(() => _enableNotifications = value);
            },
          ),

          const SizedBox(height: 12),

          _buildSettingSwitch(
            title: "Weekly Reports",
            subtitle: "Get weekly progress analysis",
            value: _enableWeeklyReports,
            icon: Icons.analytics_rounded,
            onChanged: (value) {
              setState(() => _enableWeeklyReports = value);
            },
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: () {
              healthController.generatePersonalizedRecommendations();
              _showToast("Recommendations refreshed!", Colors.green);
            },
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text("Refresh Recommendations"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthTipCard() {
    return GestureDetector(
      onTap: () => Get.to(() => HealthTipsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[500],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tips_and_updates,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Tips & Recommendations",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      healthController.personalizedRecommendations.isNotEmpty
                          ? "${healthController.personalizedRecommendations.length} personalized tips"
                          : "Get personalized health advice",
                      style: TextStyle(fontSize: 13, color: Colors.blue[600]),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.blue[500]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Obx(() {
        return Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color.fromARGB(255, 20, 20, 20),
                            size: 24,
                          ),
                        ),
                        Text(
                          "My Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        IconButton(
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    // Profile Info
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: Color(0xFF1976D2),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  healthController.userName.value,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  healthController.userEmail.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 10),

                                // Stats
                                Row(
                                  children: [
                                    _profileStat(
                                      "${healthController.userAge.value}",
                                      "Age",
                                      Icons.cake_rounded,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _profileStat(
                                      healthController.userWeight.value,
                                      "kg",
                                      Icons.monitor_weight_rounded,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    _profileStat(
                                      healthController.userHeight.value,
                                      "cm",
                                      Icons.height_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Page Indicator
            Container(
              height: 60,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageIndicator(0, "Overview"),
                  const SizedBox(width: 20),
                  _buildPageIndicator(1, "Health"),
                  const SizedBox(width: 20),
                  _buildPageIndicator(2, "Settings"),
                ],
              ),
            ),

            // Page View Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // Page 1: Overview
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // Health Tips Card
                        _buildHealthTipCard(),
                        const SizedBox(height: 20),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio: 1.2,
                          children: [
                            _buildStatCard(
                              "Steps Today",
                              healthController.dailySteps.value.toString(),
                              "",
                              Icons.directions_walk_rounded,
                              Colors.blue,
                              "${healthController.stepsGoal.value} goal",
                            ),
                            _buildStatCard(
                              "Calories Burned",
                              healthController.burnedCalories.value
                                  .toStringAsFixed(0),
                              "kcal",
                              Icons.local_fire_department_rounded,
                              Colors.orange,
                              "",
                            ),
                            _buildStatCard(
                              "Water Intake",
                              "${healthController.waterIntake.value}ml",
                              "",
                              Icons.water_drop_rounded,
                              Colors.blue[400]!,
                              "${healthController.waterGoal.value}ml goal",
                            ),
                            _buildStatCard(
                              "Sleep",
                              healthController.sleepHours.value.toStringAsFixed(
                                1,
                              ),
                              "hrs",
                              Icons.bedtime_rounded,
                              Colors.purple,
                              "${healthController.sleepGoal.value}hrs goal",
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Activity Progress
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Progress",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildProgressRow(
                                "Steps",
                                healthController.stepsProgress,
                                Colors.blue,
                              ),
                              const SizedBox(height: 15),
                              _buildProgressRow(
                                "Calories",
                                healthController.caloriesProgress,
                                Colors.orange,
                              ),
                              const SizedBox(height: 15),
                              _buildProgressRow(
                                "Water",
                                healthController.waterProgress,
                                Colors.blue[400]!,
                              ),
                              const SizedBox(height: 15),
                              _buildProgressRow(
                                "Sleep",
                                healthController.sleepProgress,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page 2: Health Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        // BMI Card
                        _buildBMICard(),
                        const SizedBox(height: 20),

                        // Health Metrics
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Health Metrics",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildMetricItem(
                                "Activity Score",
                                "${(healthController.activityScore * 100).toStringAsFixed(0)}%",
                                healthController.activityScore > 0.7
                                    ? Colors.green
                                    : healthController.activityScore > 0.4
                                    ? Colors.orange
                                    : Colors.red,
                                Icons.directions_run_rounded,
                              ),
                              const Divider(height: 20),
                              _buildMetricItem(
                                "Calorie Balance",
                                "${healthController.calorieBalance > 0 ? '+' : ''}${healthController.calorieBalance} cal",
                                healthController.calorieBalance <= 0
                                    ? Colors.green
                                    : Colors.orange,
                                Icons.balance_rounded,
                              ),
                              const Divider(height: 20),
                              _buildMetricItem(
                                "Sleep Quality",
                                "${healthController.sleepHours.value.toStringAsFixed(1)} hrs",
                                healthController.sleepHours.value >= 7
                                    ? Colors.green
                                    : Colors.orange,
                                Icons.bedtime_rounded,
                              ),
                              const Divider(height: 20),
                              _buildMetricItem(
                                "Hydration",
                                "${healthController.waterProgress * 100 ~/ 1}%",
                                healthController.waterProgress > 0.7
                                    ? Colors.green
                                    : Colors.blue,
                                Icons.water_drop_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Personalized Recommendations Preview
                        if (healthController
                            .personalizedRecommendations
                            .isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange[100]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.recommend_rounded,
                                        color: Colors.orange[800],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "AI Recommendations",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                ...healthController.personalizedRecommendations
                                    .take(2)
                                    .map(
                                      (rec) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 16,
                                              color: Colors.orange[600],
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                rec['title'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                const SizedBox(height: 15),
                                TextButton(
                                  onPressed: () =>
                                      Get.to(() => HealthTipsScreen()),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "View All Recommendations",
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Colors.orange[800],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Page 3: Settings
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        // Recommendation Settings
                        _buildRecommendationSettings(),
                        const SizedBox(height: 20),

                        // Account Settings
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Account Settings",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildSettingItem(
                                "Personal Information",
                                Icons.person_rounded,
                                Colors.blue,
                                onTap: _showEditProfileDialog,
                              ),
                              const Divider(height: 0),
                              _buildSettingItem(
                                "Health Goals",
                                Icons.flag_rounded,
                                Colors.green,
                                onTap: () {
                                  // Navigate to goals screen
                                  Get.snackbar(
                                    "Coming Soon",
                                    "Goals management screen",
                                    backgroundColor: Colors.blue,
                                  );
                                },
                              ),
                              const Divider(height: 0),
                              _buildSettingItem(
                                "Privacy & Security",
                                Icons.lock_rounded,
                                Colors.purple,
                                onTap: () {
                                  Get.snackbar(
                                    "Coming Soon",
                                    "Privacy settings screen",
                                    backgroundColor: Colors.blue,
                                  );
                                },
                              ),
                              const Divider(height: 0),
                              _buildSettingItem(
                                "Help & Support",
                                Icons.help_rounded,
                                Colors.orange,
                                onTap: () {
                                  Get.snackbar(
                                    "Coming Soon",
                                    "Help center screen",
                                    backgroundColor: Colors.blue,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Danger Zone
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.warning_rounded,
                                      color: Colors.red[800],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Danger Zone",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton.icon(
                                onPressed: _logout,
                                icon: Icon(Icons.logout_rounded, size: 20),
                                label: Text("Logout"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "You'll need to sign in again to access your account.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, String label) {
    bool isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 30 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              "${(progress * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    Color color, {
    required Function onTap,
  }) {
    return ListTile(
      onTap: () => onTap(),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _activityController.dispose();
    super.dispose();
  }
}
