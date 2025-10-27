import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health_tracker_fyp/main.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Health_Statistics_Screen.dart';

class Activityscreen extends StatefulWidget {
  const Activityscreen({super.key});

  @override
  State<Activityscreen> createState() => _ActivityscreenState();
}

class _ActivityscreenState extends State<Activityscreen> {
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  Timer? _stepTimer;
  Timer? _sessionTimer;

  String _status = "stopped";
  int _steps = 0;
  bool _isWalking = false;
  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _isLoading = false;

  final math.Random _random = math.Random();
  double _calories = 0;
  double _distance = 0;
  int _dailyGoal = 1000;
  List<Map<String, dynamic>> _weeklyData = [];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _pedestrianSubscription?.cancel();
    _stepTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => _isLoading = true);
    await Permission.notification.request();

    final status = await Permission.activityRecognition.request();
    setState(() => _isPermissionGranted = status == PermissionStatus.granted);
    if (_isPermissionGranted) {
      await _initializeApp();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _initializeApp() async {
    await _loadStepsFromFirestore();
    await _setupMovementDetection();
    await _loadWeeklyData();
    setState(() => _isInitialized = true);
  }

  Future<void> _setupMovementDetection() async {
    try {
      _pedestrianSubscription = Pedometer.pedestrianStatusStream.listen((
        event,
      ) {
        _handleMovementChange(event.status);
      });
    } catch (e) {
      print("Error setting up movement detection: $e");
    }
  }

  void _handleMovementChange(String status) {
    setState(() => _status = status);
    if (status == "walking" && !_isWalking) {
      _startWalkingSession();
    } else if (status == "stopped" && _isWalking) {
      _stopWalkingSession();
    }
  }

  void _startWalkingSession() {
    _isWalking = true;
    _startStepCounting();
  }

  void _stopWalkingSession() {
    _isWalking = false;
    _stepTimer?.cancel();
    _sessionTimer?.cancel();
    _stepTimer = null;
    _sessionTimer = null;
  }

  void _startStepCounting() {
    _stepTimer?.cancel();
    int baseInterval = (600 / (0.8 + _random.nextDouble() * 0.4)).round();

    _stepTimer = Timer.periodic(Duration(milliseconds: baseInterval), (timer) {
      if (!_isWalking) {
        timer.cancel();
        return;
      }

      if (_random.nextDouble() < 0.9) {
        setState(() {
          _steps++;
          _calculateMetrics();
          if (_steps >= _dailyGoal) {
            _showGoalAchievedNotification();
          }
        });
        if (_steps % 50 == 0) {
          _saveStepsToFirestore();
        }
      }
    });
  }

  void _calculateMetrics() {
    _calories = _steps * 0.04;
    _distance = (_steps * 0.762) / 1000;
  }

  String _getDateKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _saveStepsToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = _getDateKey();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stepsData')
          .doc(dateKey)
          .set({
            'steps': _steps,
            'calories': _calories,
            'distance': _distance,
            'goal': _dailyGoal,
            'timestamp': DateTime.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving steps: $e");
    }
  }

  Future<void> _loadStepsFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = _getDateKey();
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stepsData')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _steps = data['steps'] ?? 0;
          _calories = data['calories'] ?? 0.0;
          _distance = data['distance'] ?? 0.0;
          _dailyGoal = data['goal'] ?? 1000;
        });
      }
    } catch (e) {
      print("Error loading steps: $e");
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stepsData')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      final weekData = query.docs.map((doc) {
        final data = doc.data();
        final date = DateTime.parse(doc.id);
        return {
          'date': date,
          'steps': data['steps'] ?? 0,
          'day': DateFormat('E').format(date),
        };
      }).toList();

      setState(() => _weeklyData = weekData.reversed.toList());
    } catch (e) {
      print("Error loading weekly data: $e");
    }
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _dailyGoal.toString());
        return AlertDialog(
          title: const Text("Set Daily Goal"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Daily Steps Goal"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = int.tryParse(controller.text) ?? 1000;
                setState(() => _dailyGoal = newGoal);
                await _saveStepsToFirestore();
                Navigator.pop(context);
              },
              child: const Text("Set Goal"),
            ),
          ],
        );
      },
    );
  }

  void _showGoalAchievedNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'goal_channel',
          'Goal Notifications',
          channelDescription: 'Notifies when user achieves their step goal',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '🎉 Goal Achieved!',
      'You have reached your daily step goal!',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal > 0 ? _steps / _dailyGoal : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Step Counter"),
        centerTitle: true,
        actions: _isPermissionGranted
            ? [
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthStatisticsScreen(),
                      ),
                    );
                  },
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isPermissionGranted
          ? _buildPermissionView()
          : _buildMainView(progress),
    );
  }

  Widget _buildPermissionView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_walk, size: 100, color: Colors.blue[300]),
        const SizedBox(height: 20),
        Text(
          "Permission Required",
          style: TextStyle(
            fontSize: 24,
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _checkPermission,
          child: const Text("Grant Permission"),
        ),
      ],
    ),
  );

  Widget _buildMainView(double progress) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      color: Colors.white,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _status == "walking"
                            ? Icons.directions_walk
                            : Icons.accessibility_new,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$_steps",
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "of $_dailyGoal Steps",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showGoalDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Set Goal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _status == "walking" ? "Walking" : "Stopped",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              value: _calories.toStringAsFixed(1),
              unit: 'cal',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.straighten,
              value: _distance.toStringAsFixed(2),
              unit: 'Km',
              color: Colors.purple,
            ),
            _buildStatCard(
              icon: Icons.timer,
              value: (_steps * 0.008).toStringAsFixed(0),
              unit: 'min',
              color: Colors.teal,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildWeeklyChart(),
      ],
    ),
  );

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(15),
    width: MediaQuery.of(context).size.width * 0.25,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    ),
  );

  Widget _buildWeeklyChart() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.white,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Weekly Activity",
          style: TextStyle(
            fontSize: 18,
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _weeklyData.map((data) {
            final height = (data['steps'] / _dailyGoal * 100).clamp(
              10.0,
              100.0,
            );
            final isToday =
                DateFormat('yyyy-MM-dd').format(data['date']) == _getDateKey();
            return Column(
              children: [
                Container(
                  width: 35,
                  height: height.toDouble(),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          )
                        : null,
                    color: !isToday ? Colors.grey[300] : null,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data['day'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}
