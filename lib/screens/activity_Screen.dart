import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:health_tracker_fyp/screens/Health_Statistics_Screen.dart';
import 'package:health_tracker_fyp/screens/health_tips_screen.dart'; // NEW
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class Activityscreen extends StatefulWidget {
  const Activityscreen({super.key});

  @override
  State<Activityscreen> createState() => _ActivityscreenState();
}

class _ActivityscreenState extends State<Activityscreen> {
  final HealthController healthController = Get.find();
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  String _status = 'unknown';
  bool _isListening = false;
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  DateTime? _lastUpdateTime;
  int _sessionSteps = 0; // Steps in current session
  Timer? _activityTimer;
  Duration _activeTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPedometer();
    _startActivityTimer();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _activityTimer?.cancel();
    super.dispose();
  }

  void _startActivityTimer() {
    _activityTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_status == 'walking' || _status == 'running') {
        setState(() {
          _activeTime = _activeTime + Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _initPedometer() async {
    setState(() => _isLoading = true);

    final status = await Permission.activityRecognition.request();
    setState(() => _isPermissionGranted = status.isGranted);

    if (_isPermissionGranted) {
      await _startListening();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _startListening() async {
    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );

      setState(() => _isListening = true);
    } catch (e) {
      print("Pedometer error: $e");
      Get.snackbar(
        "Step Counter Error",
        "Using manual mode",
        backgroundColor: Colors.orange,
      );
    }
  }

  void _onStepCount(StepCount event) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final eventDate = DateFormat('yyyy-MM-dd').format(event.timeStamp);

    if (eventDate == today) {
      final previousSteps = healthController.dailySteps.value;
      healthController.updateSteps(event.steps);

      setState(() {
        _lastUpdateTime = DateTime.now();
        _sessionSteps = event.steps - previousSteps;
      });

      if (event.steps > previousSteps) {
        setState(() => _status = 'walking');
      }
    }
  }

  void _onStepCountError(error) {
    print('Step count error: $error');
    setState(() => _status = 'Step Count not available');
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() => _status = event.status);
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
    setState(() => _status = 'Status not available');
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      await _startListening();
      Get.snackbar(
        "Permission Granted",
        "Step counter activated!",
        backgroundColor: Colors.green,
      );
    } else {
      Get.snackbar(
        "Permission Required",
        "Enable activity recognition in settings",
        backgroundColor: Colors.red,
      );
    }

    setState(() {
      _isPermissionGranted = status.isGranted;
      _isLoading = false;
    });
  }

  void _addSteps(int steps) {
    final newSteps = healthController.dailySteps.value + steps;
    healthController.updateSteps(newSteps);

    Get.snackbar(
      "Steps Added",
      "$steps steps added to total",
      backgroundColor: Color(0xFF2196F3),
      colorText: Colors.white,
    );
  }

  void _resetSession() {
    setState(() {
      _sessionSteps = 0;
      _activeTime = Duration.zero;
    });
    Get.snackbar(
      "Session Reset",
      "Current session cleared",
      backgroundColor: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Activity Tracker",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A1A),
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
            icon: Icon(Icons.bar_chart, color: Color(0xFF666666)),
            onPressed: () => Get.to(() => const HealthStatisticsScreen()),
            tooltip: "Statistics",
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading) return _buildLoadingView();
        if (!_isPermissionGranted) return _buildPermissionView();

        final progress = healthController.stepsProgress;
        final steps = healthController.dailySteps.value;
        final goal = healthController.stepsGoal.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ================= STATUS CARD =================
              _buildStatusCard(),
              const SizedBox(height: 10),

              // ================= ACTIVITY RECOMMENDATIONS =================
              _buildActivityRecommendations(),
              const SizedBox(height: 10),

              // ================= PROGRESS CIRCLE =================
              _buildProgressCircle(progress, steps, goal),
              const SizedBox(height: 15),

              // ================= SESSION STATS =================
              _buildSessionStats(),
              const SizedBox(height: 15),

              // ================= QUICK ACTIONS =================
              _buildQuickActions(),
              const SizedBox(height: 15),

              // ================= MANUAL CONTROLS =================
              _buildManualControls(),
              const SizedBox(height: 15),

              // ================= DAILY STATS =================
              _buildDailyStats(),
            ],
          ),
        );
      }),
    );
  }

  // ================= STATUS CARD =================
  Widget _buildStatusCard() {
    Color getStatusColor() {
      switch (_status) {
        case 'walking':
          return Color(0xFF4CAF50);
        case 'running':
          return Color(0xFF2196F3);
        case 'stopped':
          return Color(0xFFF44336);
        default:
          return Color(0xFF9E9E9E);
      }
    }

    IconData getStatusIcon() {
      switch (_status) {
        case 'walking':
          return Icons.directions_walk;
        case 'running':
          return Icons.directions_run;
        case 'stopped':
          return Icons.pause;
        default:
          return Icons.accessibility;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(getStatusIcon(), color: getStatusColor(), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isListening ? "Pedometer Active" : "Manual Mode",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                if (_lastUpdateTime != null)
                  Text(
                    "Updated ${DateFormat('hh:mm a').format(_lastUpdateTime!)}",
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
              ],
            ),
          ),
          Switch(
            value: _isListening,
            onChanged: (value) => _togglePedometer(),
            activeThumbColor: Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVITY RECOMMENDATIONS =================
  Widget _buildActivityRecommendations() {
    final steps = healthController.dailySteps.value;
    final goal = healthController.stepsGoal.value;
    final remaining = goal - steps;
    final progress = healthController.stepsProgress;

    if (remaining <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🎯 Goal Achieved!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    "You've reached your daily step goal. Great job!",
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (progress < 0.3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFF9800).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFFF9800).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_walk,
                color: Color(0xFFFF9800),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🚶 Keep Moving!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  Text(
                    "You need $remaining more steps to reach your goal.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  // ================= PROGRESS CIRCLE =================
  Widget _buildProgressCircle(double progress, int steps, int goal) {
    Color getProgressColor() {
      if (progress >= 1.0) return Color(0xFF4CAF50);
      if (progress >= 0.7) return Color(0xFF2196F3);
      if (progress >= 0.4) return Color(0xFFFF9800);
      return Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  color: getProgressColor(),
                  backgroundColor: Color.fromARGB(255, 199, 251, 255),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$steps",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    "STEPS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    child: Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: getProgressColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    "Goal",
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  Text(
                    "$goal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Remaining",
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  Text(
                    "${goal - steps}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Session",
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  Text(
                    "$_sessionSteps",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () => _showGoalDialog(),
            icon: Icon(Icons.flag, size: 18),
            label: Text("Set Daily Goal"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SESSION STATS =================
  Widget _buildSessionStats() {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    final calories = (_sessionSteps * 0.04).toStringAsFixed(1);
    final distance = (_sessionSteps * 0.000762).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Current Session",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              TextButton.icon(
                onPressed: _resetSession,
                icon: Icon(Icons.refresh, size: 16),
                label: Text("Reset"),
                style: TextButton.styleFrom(foregroundColor: Color(0xFF2196F3)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sessionStatItem(
                Icons.timer,
                "Time",
                formatDuration(_activeTime),
              ),
              Container(width: 1, height: 40, color: Color(0xFFEEEEEE)),
              _sessionStatItem(
                Icons.directions_walk,
                "Steps",
                "$_sessionSteps",
              ),
              Container(width: 1, height: 40, color: Color(0xFFEEEEEE)),
              _sessionStatItem(
                Icons.local_fire_department,
                "Calories",
                "${calories}cal",
              ),
              Container(width: 1, height: 40, color: Color(0xFFEEEEEE)),
              _sessionStatItem(Icons.straighten, "Distance", "${distance}km"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Color(0xFF666666)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
      ],
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction("+100", 100, Icons.add),
      _QuickAction("+500", 500, Icons.double_arrow),
      _QuickAction("+1000", 1000, Icons.run_circle_outlined),
      _QuickAction("Goal", healthController.stepsGoal.value, Icons.flag),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionCard(actions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: () => _addSteps(action.steps),
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
          border: Border.all(color: Color(0xFFF0F0F0)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 20, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MANUAL CONTROLS =================
  Widget _buildManualControls() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manual Controls",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add steps manually if pedometer is inaccurate",
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _manualButton("+100", 100),
              _manualButton("+500", 500),
              _manualButton("+1000", 1000),
              _manualButton("+2000", 2000),
              _manualButton(
                "Reset All",
                -healthController.dailySteps.value,
                isDanger: true,
              ),
              _manualButton(
                "Set to Goal",
                healthController.stepsGoal.value -
                    healthController.dailySteps.value,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manualButton(String label, int steps, {bool isDanger = false}) {
    return OutlinedButton(
      onPressed: () => steps < 0 ? _addSteps(steps) : _addSteps(steps),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDanger ? Color(0xFFF44336) : Color(0xFF2196F3),
        ),
        backgroundColor: isDanger
            ? Color(0xFFF44336).withOpacity(0.05)
            : Colors.transparent,
        foregroundColor: isDanger ? Color(0xFFF44336) : Color(0xFF2196F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ================= DAILY STATS =================
  Widget _buildDailyStats() {
    final calories = healthController.burnedCalories.value;
    final distance = healthController.distanceKm.value;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daily Statistics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dailyStatCard(
                  Icons.local_fire_department,
                  calories.toStringAsFixed(1),
                  "Calories Burned",
                  Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dailyStatCard(
                  Icons.straighten,
                  distance.toStringAsFixed(2),
                  "Distance (km)",
                  Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dailyStatCard(
            Icons.timer,
            (healthController.dailySteps.value * 0.008).toStringAsFixed(0),
            "Active Minutes",
            Color(0xFF009688),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _dailyStatCard(
    IconData icon,
    String value,
    String label,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
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
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER METHODS =================
  void _togglePedometer() {
    if (_isListening) {
      _stepCountSubscription?.cancel();
      _pedestrianStatusSubscription?.cancel();
      setState(() {
        _isListening = false;
        _status = 'stopped';
      });
    } else {
      _startListening();
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          const SizedBox(height: 20),
          Text(
            "Initializing Step Counter...",
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_walk,
                size: 60,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Permission Required",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This app needs activity recognition permission to count your steps accurately using your phone's sensors.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: Icon(Icons.security),
              label: Text("Grant Permission"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Get.snackbar(
                  "Manual Mode",
                  "You can add steps manually",
                  backgroundColor: Colors.orange,
                );
                setState(() => _isPermissionGranted = true);
              },
              child: Text(
                "Continue with Manual Mode",
                style: TextStyle(color: Color(0xFF2196F3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog() {
    final controller = TextEditingController(
      text: healthController.stepsGoal.value.toString(),
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Set Daily Step Goal",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Daily Steps Goal",
                  hintText: "e.g., 10000",
                  prefixIcon: Icon(Icons.flag, color: Color(0xFF2196F3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _presetGoalButton("5k", 5000),
                  const SizedBox(width: 8),
                  _presetGoalButton("8k", 8000),
                  const SizedBox(width: 8),
                  _presetGoalButton("10k", 10000),
                  const SizedBox(width: 8),
                  _presetGoalButton("12k", 12000),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newGoal = int.tryParse(controller.text) ?? 10000;
                        healthController.updateGoals(
                          newGoal,
                          healthController.caloriesGoal.value,
                        );
                        Get.back();
                        Get.snackbar(
                          "Goal Updated",
                          "Daily goal set to $newGoal steps",
                          backgroundColor: Color(0xFF4CAF50),
                          colorText: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Save Goal"),
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

  Widget _presetGoalButton(String label, int goal) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          healthController.updateGoals(
            goal,
            healthController.caloriesGoal.value,
          );
          Get.back();
          Get.snackbar(
            "Goal Set",
            "Daily goal set to $goal steps",
            backgroundColor: Color(0xFF4CAF50),
            colorText: Colors.white,
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final int steps;
  final IconData icon;

  _QuickAction(this.label, this.steps, this.icon);
}
