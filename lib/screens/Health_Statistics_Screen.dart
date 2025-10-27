import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthStatisticsScreen extends StatefulWidget {
  const HealthStatisticsScreen({super.key});

  @override
  State<HealthStatisticsScreen> createState() => _HealthStatisticsScreenState();
}

class _HealthStatisticsScreenState extends State<HealthStatisticsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
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
          'calories': data['calories'] ?? 0.0,
          'distance': data['distance'] ?? 0.0,
          'goal': data['goal'] ?? 1000,
          'day': DateFormat('E').format(date),
        };
      }).toList();

      setState(() {
        _weeklyData = weekData.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading weekly stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Weekly Health Stats"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _weeklyData.isEmpty
          ? const Center(child: Text("No data available yet!"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 30),
                  _buildBarChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSteps = _weeklyData.fold<int>(
      0,
      (sum, item) => sum + (item['steps'] ?? 0) as int,
    );
    final totalCalories = _weeklyData.fold<double>(
      0.0,
      (sum, item) => sum + (item['calories'] ?? 0.0),
    );
    final totalDistance = _weeklyData.fold<double>(
      0.0,
      (sum, item) => sum + (item['distance'] ?? 0.0),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoCard(
          "Steps",
          totalSteps.toString(),
          Icons.directions_walk,
          Colors.blue,
        ),
        _buildInfoCard(
          "Calories",
          totalCalories.toStringAsFixed(1),
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildInfoCard(
          "Distance",
          "${totalDistance.toStringAsFixed(2)} km",
          Icons.straighten,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxSteps = _weeklyData
        .map((d) => d['steps'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Last 7 Days Activity",
            style: TextStyle(
              fontSize: 18,
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _weeklyData.length) {
                          return const SizedBox();
                        }
                        return Text(
                          _weeklyData[index]['day'],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: _weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final steps = entry.value['steps'] ?? 0;
                  final goal = entry.value['goal'] ?? 1000;
                  final progress = (steps / goal).clamp(0.0, 1.0);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: steps.toDouble(),
                        color: progress >= 1 ? Colors.green : Colors.blue[400],
                        width: 18,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
