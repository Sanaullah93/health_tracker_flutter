import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthStatisticsScreen extends StatefulWidget {
  const HealthStatisticsScreen({super.key});

  @override
  State<HealthStatisticsScreen> createState() => _HealthStatisticsScreenState();
}

class _HealthStatisticsScreenState extends State<HealthStatisticsScreen> {
  final HealthController healthController = Get.find();

  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  double _maxSteps = 0;
  String _selectedMetric = 'steps';

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);

    try {
      _weeklyData = await _generateWeeklyData();

      if (_weeklyData.isNotEmpty) {
        _maxSteps = _weeklyData
            .map((d) => d['steps'] as int)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
      }
    } catch (e) {
      print("Error loading stats: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _generateWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stepsData')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();

    return query.docs
        .map((doc) {
          final data = doc.data();
          final date = DateTime.parse(doc.id);

          // Safe type casting
          final steps = (data['steps'] ?? 0) is int
              ? (data['steps'] as int)
              : 0;
          final calories = (data['calories'] ?? 0.0) is double
              ? (data['calories'] as double)
              : 0.0;
          final distance = (data['distance'] ?? 0.0) is double
              ? (data['distance'] as double)
              : 0.0;
          final goal = (data['goal'] ?? healthController.stepsGoal.value) is int
              ? (data['goal'] as int)
              : healthController.stepsGoal.value;

          return {
            'date': date,
            'steps': steps,
            'calories': calories,
            'distance': distance,
            'goal': goal,
            'day': DateFormat('E').format(date),
            'dateStr': doc.id,
          };
        })
        .toList()
        .reversed
        .toList();
  }

  Map<String, dynamic> _calculateInsights() {
    if (_weeklyData.isEmpty) return {};

    final steps = _weeklyData.map((d) => d['steps'] as int).toList();
    final calories = _weeklyData.map((d) => d['calories'] as double).toList();
    final distances = _weeklyData.map((d) => d['distance'] as double).toList();

    final avgSteps = steps.reduce((a, b) => a + b) ~/ steps.length;
    final avgCalories = calories.reduce((a, b) => a + b) / calories.length;
    final avgDistance = distances.reduce((a, b) => a + b) / distances.length;

    // Calculate trends
    bool isImproving = false;
    if (steps.length >= 2) {
      final firstHalf = steps
          .sublist(0, steps.length ~/ 2)
          .reduce((a, b) => a + b);
      final secondHalf = steps
          .sublist(steps.length ~/ 2)
          .reduce((a, b) => a + b);
      isImproving = secondHalf > firstHalf;
    }

    // FIXED: Explicit casting for reduce
    final bestDay = _weeklyData.fold<Map<String, dynamic>>(_weeklyData.first, (
      Map<String, dynamic> a,
      Map<String, dynamic> b,
    ) {
      return (a['steps'] as int) > (b['steps'] as int) ? a : b;
    });

    final worstDay = _weeklyData.fold<Map<String, dynamic>>(_weeklyData.first, (
      Map<String, dynamic> a,
      Map<String, dynamic> b,
    ) {
      return (a['steps'] as int) < (b['steps'] as int) ? a : b;
    });

    final consistencyScore = steps.isNotEmpty
        ? (steps
                      .where((s) => s >= healthController.stepsGoal.value * 0.7)
                      .length /
                  steps.length) *
              100
        : 0.0;

    return {
      'avgSteps': avgSteps,
      'avgCalories': avgCalories,
      'avgDistance': avgDistance,
      'isImproving': isImproving,
      'bestDay': bestDay,
      'worstDay': worstDay,
      'consistency': consistencyScore,
    };
  }

  @override
  Widget build(BuildContext context) {
    final insights = _calculateInsights();

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Health Statistics",
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
            icon: Icon(Icons.refresh, color: Color(0xFF666666)),
            onPressed: _loadWeeklyData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _weeklyData.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ================= INSIGHTS CARD =================
                  _buildInsightsCard(insights),
                  const SizedBox(height: 20),

                  // ================= PERIOD SELECTOR =================
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),

                  // ================= METRIC SELECTOR =================
                  _buildMetricSelector(),
                  const SizedBox(height: 20),

                  // ================= SUMMARY CARDS =================
                  _buildSummaryCards(insights),
                  const SizedBox(height: 20),

                  // ================= MAIN CHART =================
                  _buildMainChart(),
                  const SizedBox(height: 20),

                  // ================= WEEKLY DETAILS =================
                  _buildWeeklyDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          const SizedBox(height: 20),
          Text(
            "Loading statistics...",
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 20),
            Text(
              "No Data Available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Start tracking your activities to see detailed statistics",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.directions_walk),
              label: Text("Start Tracking"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INSIGHTS CARD =================
  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    if (insights.isEmpty) return SizedBox();

    final consistency = insights['consistency'] as double;
    final isImproving = insights['isImproving'] as bool;
    final bestDay = insights['bestDay'] as Map<String, dynamic>;
    final worstDay = insights['worstDay'] as Map<String, dynamic>;

    // Safe casting
    final bestDate = bestDay['date'] as DateTime;
    final worstDate = worstDay['date'] as DateTime;
    final bestSteps = bestDay['steps'] as int;
    final worstSteps = worstDay['steps'] as int;

    Color getConsistencyColor() {
      if (consistency >= 80) return Color(0xFF4CAF50);
      if (consistency >= 50) return Color(0xFFFF9800);
      return Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.insights, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Weekly Insights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Consistency Score",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      "${consistency.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    LinearProgressIndicator(
                      value: consistency / 100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: getConsistencyColor(),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Trend",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isImproving ? Icons.trending_up : Icons.trending_down,
                          color: isImproving
                              ? Color(0xFF4CAF50)
                              : Color(0xFFF44336),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isImproving ? "Improving" : "Needs Work",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Best Day",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE').format(bestDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "$bestSteps steps",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Needs Improvement",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE').format(worstDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "$worstSteps steps",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= PERIOD SELECTOR =================
  Widget _buildPeriodSelector() {
    final periods = [
      {'label': 'Week', 'value': 'week'},
      {'label': 'Month', 'value': 'month'},
      {'label': 'Year', 'value': 'year'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = period['value']!);
              _loadWeeklyData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF2196F3) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                period['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= METRIC SELECTOR =================
  Widget _buildMetricSelector() {
    final metrics = [
      {'label': 'Steps', 'value': 'steps', 'color': Color(0xFF2196F3)},
      {'label': 'Calories', 'value': 'calories', 'color': Color(0xFFFF9800)},
      {'label': 'Distance', 'value': 'distance', 'color': Color(0xFF4CAF50)},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: metrics.map((metric) {
          final isSelected = _selectedMetric == metric['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMetric = metric['value']! as String);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (metric['color'] as Color).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? metric['color']! as Color
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: metric['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    metric['label']! as String,
                    style: TextStyle(
                      color: isSelected
                          ? metric['color'] as Color
                          : Color(0xFF666666),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= SUMMARY CARDS =================
  Widget _buildSummaryCards(Map<String, dynamic> insights) {
    if (insights.isEmpty) return SizedBox();

    final totalSteps = _weeklyData.fold<int>(
      0,
      (sum, item) => sum + (item['steps'] as int),
    );
    final totalCalories = _weeklyData.fold<double>(
      0.0,
      (sum, item) => sum + (item['calories'] as double),
    );
    final totalDistance = _weeklyData.fold<double>(
      0.0,
      (sum, item) => sum + (item['distance'] as double),
    );

    final avgDailySteps = _weeklyData.isNotEmpty
        ? totalSteps ~/ _weeklyData.length
        : 0;
    final avgDailyCalories = _weeklyData.isNotEmpty
        ? totalCalories / _weeklyData.length
        : 0.0;
    final avgDailyDistance = _weeklyData.isNotEmpty
        ? totalDistance / _weeklyData.length
        : 0.0;

    final goalAchievement =
        _weeklyData.isNotEmpty && healthController.stepsGoal.value > 0
        ? (totalSteps /
              (_weeklyData.length * healthController.stepsGoal.value) *
              100)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                Icons.directions_walk,
                totalSteps.toString(),
                "Total Steps",
                Color(0xFF2196F3),
                "$avgDailySteps avg/day",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.local_fire_department,
                totalCalories.toStringAsFixed(0),
                "Calories",
                Color(0xFFFF9800),
                "${avgDailyCalories.toStringAsFixed(0)} avg/day",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                Icons.straighten,
                totalDistance.toStringAsFixed(1),
                "Distance (km)",
                Color(0xFF4CAF50),
                "${avgDailyDistance.toStringAsFixed(2)} avg/day",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.flag,
                "${healthController.stepsGoal.value}",
                "Daily Goal",
                Color(0xFF9C27B0),
                "${goalAchievement.toStringAsFixed(1)}% achieved",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    IconData icon,
    String value,
    String label,
    Color color,
    String subtitle,
  ) {
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
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF333333),
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  // ================= MAIN CHART =================
  Widget _buildMainChart() {
    final chartHeight = 200.0;
    final maxValue = _getMaxValueForMetric();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
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
                _getChartTitle(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPeriod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: maxValue / 5,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _weeklyData.length) {
                          return SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _weeklyData[index]['day'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF999999),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Color(0xFFEEEEEE), width: 1),
                ),
                barGroups: _weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = _getValueForMetric(entry.value);
                  final goal = _getGoalForMetric();
                  final progress = goal > 0
                      ? (value / goal).clamp(0.0, 1.0)
                      : 0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        color: _getBarColor(progress.toDouble()),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  double _getMaxValueForMetric() {
    if (_weeklyData.isEmpty) return 100.0;

    switch (_selectedMetric) {
      case 'steps':
        return _weeklyData
            .map((d) => d['steps'] as int)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
      case 'calories':
        return _weeklyData
            .map((d) => d['calories'] as double)
            .reduce((a, b) => a > b ? a : b);
      case 'distance':
        return _weeklyData
            .map((d) => d['distance'] as double)
            .reduce((a, b) => a > b ? a : b);
      default:
        return 10000.0;
    }
  }

  double _getValueForMetric(Map<String, dynamic> data) {
    switch (_selectedMetric) {
      case 'steps':
        return (data['steps'] as int).toDouble();
      case 'calories':
        return data['calories'] as double;
      case 'distance':
        return data['distance'] as double;
      default:
        return 0.0;
    }
  }

  double _getGoalForMetric() {
    switch (_selectedMetric) {
      case 'steps':
        return healthController.stepsGoal.value.toDouble();
      case 'calories':
        return 500.0;
      case 'distance':
        return 5.0;
      default:
        return 1.0;
    }
  }

  String _getChartTitle() {
    switch (_selectedMetric) {
      case 'steps':
        return 'Daily Steps Trend';
      case 'calories':
        return 'Calories Burned';
      case 'distance':
        return 'Distance Walked (km)';
      default:
        return 'Activity Trend';
    }
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Color(0xFF4CAF50), "Excellent"),
        const SizedBox(width: 16),
        _legendItem(Color(0xFF2196F3), "Good"),
        const SizedBox(width: 16),
        _legendItem(Color(0xFFFF9800), "Average"),
        const SizedBox(width: 16),
        _legendItem(Color(0xFFF44336), "Improve"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  Color _getBarColor(double progress) {
    if (progress >= 1.0) return Color(0xFF4CAF50);
    if (progress >= 0.8) return Color(0xFF2196F3);
    if (progress >= 0.5) return Color(0xFFFF9800);
    return Color(0xFFF44336);
  }

  // ================= WEEKLY DETAILS =================
  Widget _buildWeeklyDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
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
                "Daily Breakdown",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Last 7 Days",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._weeklyData.map((day) => _dailyDetailItem(day)),
        ],
      ),
    );
  }

  Widget _dailyDetailItem(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final isToday =
        DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Safe casting
    final steps = day['steps'] as int;
    final calories = day['calories'] as double;
    final distance = day['distance'] as double;

    final progress = steps / healthController.stepsGoal.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Color(0xFF2196F3).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Color(0xFF2196F3).withOpacity(0.2)
              : Color(0xFFF0F0F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getBarColor(progress.toDouble()).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _getBarColor(progress.toDouble()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE').format(date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      "$steps steps",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${calories.toStringAsFixed(0)} cal • ${distance.toStringAsFixed(2)} km",
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: Color(0xFFEEEEEE),
                  color: _getBarColor(progress.toDouble()),
                  minHeight: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
