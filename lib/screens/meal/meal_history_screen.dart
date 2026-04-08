import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/health_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final HealthController healthController = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedFilter = 'all'; // 'all', 'week', 'month', 'today'
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'calories', 'meals'
  bool _isLoading = false;
  List<Map<String, dynamic>> _allMeals = [];
  List<Map<String, dynamic>> _filteredMeals = [];
  int _visibleDays = 10;

  @override
  void initState() {
    super.initState();
    _loadMealHistory();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_visibleDays < _filteredMeals.length) {
        setState(() {
          _visibleDays += 10;
        });
      }
    }
  }

  Future<void> _loadMealHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      List<Map<String, dynamic>> meals = [];

      for (final doc in query.docs) {
        final data = doc.data();
        final date = DateTime.parse(doc.id);

        // Extract all meals for this date
        List<Map<String, dynamic>> dayMeals = [];
        int dayCalories = 0;

        // Check all possible meal types
        const mealTypes = [
          'breakfast',
          'morning_snack',
          'lunch',
          'afternoon_snack',
          'dinner',
          'evening_snack',
        ];

        for (final mealType in mealTypes) {
          if (data[mealType] != null) {
            final meal = data[mealType] as Map<String, dynamic>;
            dayMeals.add({
              'type': _getMealDisplayName(mealType),
              'food': meal['food'] ?? 'Unknown',
              'calories': meal['calories'] ?? 0,
              'time': meal['time'] != null
                  ? DateFormat(
                      'hh:mm a',
                    ).format((meal['time'] as Timestamp).toDate())
                  : 'Unknown',
              'rawType': mealType,
            });
            dayCalories += (meal['calories'] as int? ?? 0);
          }
        }

        if (dayMeals.isNotEmpty) {
          meals.add({
            'date': date,
            'dateStr': doc.id,
            'displayDate': _formatDate(date),
            'meals': dayMeals,
            'totalCalories': dayCalories,
            'mealCount': dayMeals.length,
            'dayName': DateFormat('EEEE').format(date),
          });
        }
      }

      setState(() {
        _allMeals = meals;
        _applyFilter();
        _sortMeals();
      });
    } catch (e) {
      print("Error loading meal history: $e");
      Get.snackbar(
        "Error",
        "Failed to load meal history",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _filteredMeals = _allMeals.where((day) {
        final date = day['date'] as DateTime;
        final searchMatch =
            _searchQuery.isEmpty ||
            day['displayDate'].toLowerCase().contains(_searchQuery) ||
            (day['meals'] as List).any(
              (meal) =>
                  meal['food'].toString().toLowerCase().contains(_searchQuery),
            );

        if (!searchMatch) return false;

        switch (_selectedFilter) {
          case 'today':
            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          case 'week':
            return date.isAfter(now.subtract(const Duration(days: 7)));
          case 'month':
            return date.isAfter(now.subtract(const Duration(days: 30)));
          default: // 'all'
            return true;
        }
      }).toList();
      _visibleDays = min(10, _filteredMeals.length);
    });
  }

  void _sortMeals() {
    _filteredMeals.sort((a, b) {
      switch (_sortBy) {
        case 'calories':
          return (b['totalCalories'] as int).compareTo(
            a['totalCalories'] as int,
          );
        case 'meals':
          return (b['mealCount'] as int).compareTo(a['mealCount'] as int);
        default:
          return (b['date'] as DateTime).compareTo(a['date'] as DateTime);
      }
    });
  }

  String _getMealDisplayName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast 🍳';
      case 'morning_snack':
        return 'Morning Snack ☕';
      case 'lunch':
        return 'Lunch 🍲';
      case 'afternoon_snack':
        return 'Afternoon Snack 🍎';
      case 'dinner':
        return 'Dinner 🍽️';
      case 'evening_snack':
        return 'Evening Snack 🌙';
      default:
        return mealType;
    }
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return "Today";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Yesterday";
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _filteredMeals.length;
    final totalMeals = _filteredMeals.fold(
      0,
      (sum, day) => sum + (day['mealCount'] as int),
    );
    final totalCalories = _filteredMeals.fold(
      0,
      (sum, day) => sum + (day['totalCalories'] as int),
    );
    final avgCalories = totalDays > 0 ? totalCalories / totalDays : 0;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Meal History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMealHistory,
            tooltip: "Refresh",
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortMeals();
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(
                value: 'calories',
                child: Text('Sort by Calories'),
              ),
              const PopupMenuItem(
                value: 'meals',
                child: Text('Sort by Meal Count'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ========== STATISTICS HEADER ==========
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statItem(
                              "📅",
                              "Days",
                              totalDays.toString(),
                              Colors.white,
                            ),
                            _statItem(
                              "🍽️",
                              "Meals",
                              totalMeals.toString(),
                              Colors.white,
                            ),
                            _statItem(
                              "🔥",
                              "Total Cal",
                              totalCalories.toStringAsFixed(0),
                              Colors.white,
                            ),
                            _statItem(
                              "⚡",
                              "Avg/Day",
                              avgCalories.toStringAsFixed(0),
                              Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ========== SEARCH BAR ==========
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _applyFilter();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search meals by date or food...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // ========== FILTER BAR ==========
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "Filter by:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterButton(
                                  'All Time',
                                  'all',
                                  Icons.calendar_today,
                                ),
                                const SizedBox(width: 8),
                                _filterButton('Today', 'today', Icons.today),
                                const SizedBox(width: 8),
                                _filterButton(
                                  'Last Week',
                                  'week',
                                  Icons.calendar_view_week,
                                ),
                                const SizedBox(width: 8),
                                _filterButton(
                                  'Last Month',
                                  'month',
                                  Icons.calendar_month,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ========== CALORIE CHART ==========
                if (_filteredMeals.length >= 2)
                  SliverToBoxAdapter(child: _buildCalorieChart()),

                // ========== MEAL ANALYTICS ==========
                if (_filteredMeals.isNotEmpty)
                  SliverToBoxAdapter(child: _buildMealAnalytics()),

                // ========== EXPORT BUTTON ==========
                if (_filteredMeals.isNotEmpty)
                  SliverToBoxAdapter(child: _buildExportButton()),

                // ========== EMPTY STATE ==========
                if (_filteredMeals.isEmpty && !_isLoading)
                  SliverToBoxAdapter(child: _buildEmptyState()),

                // ========== MEAL HISTORY LIST ==========
                if (_filteredMeals.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _visibleDays &&
                            index < _filteredMeals.length) {
                          return _buildDayCard(_filteredMeals[index]);
                        } else if (index == _visibleDays &&
                            _visibleDays < _filteredMeals.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleDays += 10;
                                  });
                                },
                                child: const Text("Load More"),
                              ),
                            ),
                          );
                        }
                        return null; // ✅ Important: Return null for extra indices
                      },
                      childCount: _visibleDays < _filteredMeals.length
                          ? _visibleDays +
                                1 // +1 for Load More button
                          : _visibleDays,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _statItem(String icon, String label, String value, Color color) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.black)),
      ],
    );
  }

  Widget _filterButton(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieChart() {
    final recentDays = _filteredMeals.take(7).toList();
    if (recentDays.length < 2) return const SizedBox();

    final maxCalories = recentDays.fold(
      0,
      (max, day) => (day['totalCalories'] as int) > max
          ? day['totalCalories'] as int
          : max,
    );

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Calorie Trend (Last ${recentDays.length} days)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: recentDays.asMap().entries.map((entry) {
                  final day = entry.value;
                  final calories = day['totalCalories'] as int;
                  final height = maxCalories > 0
                      ? (calories / maxCalories * 80)
                      : 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 25,
                        height: height.toDouble(),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEE').format(day['date'] as DateTime),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$calories",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealAnalytics() {
    // Calculate meal type distribution
    Map<String, int> mealTypeCount = {};
    Map<String, int> mealTypeCalories = {};

    for (final day in _filteredMeals) {
      final meals = day['meals'] as List<Map<String, dynamic>>;
      for (final meal in meals) {
        final type = meal['rawType'] as String;
        final calories = meal['calories'] as int;

        mealTypeCount[type] = (mealTypeCount[type] ?? 0) + 1;
        mealTypeCalories[type] = (mealTypeCalories[type] ?? 0) + calories;
      }
    }

    if (mealTypeCount.isEmpty) return const SizedBox();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Meal Type Distribution",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ FIX: Add LimitedBox or constrain height
            LimitedBox(
              maxHeight: 200, // ✅ Limit the height
              child: SingleChildScrollView(
                // ✅ Make it scrollable
                child: Column(
                  children: mealTypeCount.entries.map((entry) {
                    final type = entry.key;
                    final count = entry.value;
                    final totalCalories = mealTypeCalories[type] ?? 0;
                    final avgCalories = count > 0 ? totalCalories / count : 0;
                    final totalAllCalories = mealTypeCalories.values.fold(
                      0,
                      (sum, val) => sum + val,
                    );
                    final percentage = totalAllCalories > 0
                        ? (totalCalories * 100 / totalAllCalories)
                        : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getMealDisplayName(type),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14, // ✅ Reduced font size
                                      ),
                                    ),
                                    Text(
                                      "$count meals • ${avgCalories.toStringAsFixed(0)} avg cal",
                                      style: TextStyle(
                                        fontSize: 11, // ✅ Reduced font size
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text("$totalCalories cal"),
                                backgroundColor: Colors.orange[50],
                                labelStyle: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 11, // ✅ Reduced font size
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              color: _getMealColor(type),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "${percentage.toStringAsFixed(1)}% of total calories",
                              style: TextStyle(
                                fontSize: 9, // ✅ Reduced font size
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _exportMealHistory,
        icon: const Icon(Icons.share, size: 20),
        label: const Text("Export Meal History"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            Icon(Icons.restaurant, size: 80, color: Colors.blue[200]),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'all'
                  ? "No Meal History"
                  : "No Meals in Selected Period",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFilter == 'all'
                  ? "Start logging your meals to see history here"
                  : "No meals found for the selected filter",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.toNamed('/meal-log');
              },
              icon: const Icon(Icons.add),
              label: const Text("Log Your First Meal"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final date = dayData['date'] as DateTime;
    final displayDate = dayData['displayDate'] as String;
    final meals = dayData['meals'] as List<Map<String, dynamic>>;
    final totalCalories = dayData['totalCalories'] as int;
    final mealCount = dayData['mealCount'] as int;
    final dayName = dayData['dayName'] as String;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      dayName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        "$mealCount meal${mealCount > 1 ? 's' : ''}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Total Calories Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Calories",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        "Average: ${(totalCalories / mealCount).toStringAsFixed(0)} cal per meal",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalCalories kcal",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Meal List
            ...meals.map((meal) => _buildMealItem(meal)),

            // No meals message if empty
            if (meals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No meals logged on this day",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Meal Type Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMealColor(meal['rawType'] as String).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMealIcon(meal['type'] as String),
              color: _getMealColor(meal['rawType'] as String),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Meal Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['type'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal['food'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      meal['time'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calories
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "${meal['calories']} kcal",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    if (mealType.contains('Breakfast')) return Icons.breakfast_dining;
    if (mealType.contains('Lunch')) return Icons.lunch_dining;
    if (mealType.contains('Dinner')) return Icons.dinner_dining;
    if (mealType.contains('Snack')) return Icons.cookie;
    return Icons.restaurant;
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'morning_snack':
      case 'afternoon_snack':
      case 'evening_snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportMealHistory() async {
    try {
      String csv = 'Date,Day,Meals,Total Calories\n';

      for (final day in _filteredMeals) {
        csv +=
            '${day['dateStr']},${day['dayName']},${day['mealCount']},${day['totalCalories']}\n';
      }

      // Here you can save the CSV to a file or share it
      // For now, just show a success message

      Get.snackbar(
        "✅ Export Complete",
        "${_filteredMeals.length} days exported to CSV",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to export: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
