import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = false;
  bool _notificationsInitialized = false;

  final List<Map<String, dynamic>> _reminderTypes = [
    {
      'id': 'water',
      'title': '💧 Drink Water',
      'description': 'Time to hydrate! Drink a glass of water',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'defaultTime': '08:00',
      'interval': 2,
      'recurring': true,
    },
    {
      'id': 'walk',
      'title': '🚶‍♂️ Take a Walk',
      'description': 'Get up and walk for 5 minutes',
      'icon': Icons.directions_walk,
      'color': Colors.green,
      'defaultTime': '10:00',
      'interval': 1,
      'recurring': true,
    },
    {
      'id': 'meal',
      'title': '🍽️ Meal Time',
      'description': 'Time for your healthy meal',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'defaultTime': '13:00',
      'interval': 4,
      'recurring': true,
    },
    {
      'id': 'medicine',
      'title': '💊 Medicine',
      'description': 'Take your medicine as prescribed',
      'icon': Icons.medication,
      'color': Colors.red,
      'defaultTime': '09:00',
      'interval': 24,
      'recurring': true,
    },
    {
      'id': 'sleep',
      'title': '💤 Sleep Time',
      'description': 'Time to sleep for 8 hours',
      'icon': Icons.bedtime,
      'color': Colors.purple,
      'defaultTime': '22:00',
      'interval': 24,
      'recurring': true,
    },
    {
      'id': 'exercise',
      'title': '🏋️ Exercise',
      'description': 'Time for your daily workout',
      'icon': Icons.fitness_center,
      'color': Colors.teal,
      'defaultTime': '18:00',
      'interval': 24,
      'recurring': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTimeZones();
    _initializeNotifications();
    _loadReminders();
    _checkRealTime();
  }

  void _initTimeZones() {
    tz.initializeTimeZones();
    final location = tz.getLocation('Asia/Karachi');
    tz.setLocalLocation(location);
    print("✅ Timezone set to: ${tz.local}");
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      await _createNotificationChannel();

      setState(() {
        _notificationsInitialized = true;
      });

      print("✅ Notifications initialized successfully");
    } catch (e) {
      print("❌ Error initializing notifications: $e");
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      // Channel 1: For immediate/test notifications
      const AndroidNotificationChannel immediateChannel =
          AndroidNotificationChannel(
            'health_reminders',
            'Health Reminders',
            description: 'Immediate health notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          );

      // Channel 2: For scheduled notifications
      final AndroidNotificationChannel scheduledChannel =
          AndroidNotificationChannel(
            'health_reminders_scheduled',
            'Health Reminders Scheduled',
            description: 'Scheduled health activity reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000]),
            ledColor: Colors.blue,
            showBadge: true,
            enableLights: true,
          );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(immediateChannel);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(scheduledChannel);

      print("✅ Both notification channels created");
    } catch (e) {
      print("❌ Error creating notification channels: $e");
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['description'] ?? 'Time for your activity'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder'), backgroundColor: Colors.blue),
        );
      }
    }
  }

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReminders = prefs.getString('health_reminders');

      if (savedReminders != null && savedReminders.isNotEmpty) {
        final List<dynamic> savedList = jsonDecode(savedReminders);

        setState(() {
          _reminders = _reminderTypes.map((defaultType) {
            final saved = savedList.firstWhere(
              (r) => r['id'] == defaultType['id'],
              orElse: () => null,
            );

            return {
              ...defaultType,
              'enabled': saved?['enabled'] ?? false,
              'time': saved?['time'] ?? defaultType['defaultTime'],
              'days': saved?['days'] is List
                  ? List<int>.from(saved['days'])
                  : [1, 2, 3, 4, 5],
            };
          }).toList();
        });
      } else {
        setState(() {
          _reminders = _reminderTypes.map((type) {
            return {
              ...type,
              'enabled': false,
              'time': type['defaultTime'],
              'days': [1, 2, 3, 4, 5],
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading reminders: $e");
      setState(() {
        _reminders = _reminderTypes.map((type) {
          return {
            ...type,
            'enabled': false,
            'time': type['defaultTime'],
            'days': [1, 2, 3, 4, 5],
          };
        }).toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersToSave = _reminders
          .map(
            (r) => {
              'id': r['id'],
              'enabled': r['enabled'],
              'time': r['time'],
              'days': r['days'],
            },
          )
          .toList();

      await prefs.setString('health_reminders', jsonEncode(remindersToSave));
    } catch (e) {
      print("Error saving reminders: $e");
    }
  }

  Future<int> _scheduleAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();

      int scheduledCount = 0;

      for (final reminder in _reminders) {
        if (reminder['enabled'] == true) {
          await _scheduleReminder(reminder);
          scheduledCount++;
        }
      }

      await _saveReminders();

      return scheduledCount;
    } catch (e) {
      print("Error scheduling notifications: $e");
      rethrow;
    }
  }

  Future<void> _scheduleReminder(Map<String, dynamic> reminder) async {
    try {
      final timeStr = reminder['time'] ?? reminder['defaultTime'];
      final timeParts = timeStr.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 8;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'health_reminders_scheduled',
            'Health Reminders Scheduled',
            channelDescription: 'Scheduled health activity reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000]),
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
            color: Colors.blue,
            styleInformation: DefaultStyleInformation(true, true),
            priority: Priority.high,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      // ✅ SINGLE NOTIFICATION FOR ALL DAYS
      int notificationId = reminder['id'].hashCode.abs() % 100000;

      // Get first selected day (or Monday as default)
      int firstSelectedDay = reminder['days'].isNotEmpty
          ? reminder['days'].first
          : 1;

      final scheduledDate = _calculateNextOccurrence(
        hour: hour,
        minute: minute,
        dayOfWeek: firstSelectedDay,
      );

      // ✅ SCHEDULE DAILY NOTIFICATION
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder['title'],
        reminder['description'],
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // DAILY REPEAT
        payload: jsonEncode({
          'type': reminder['id'],
          'title': reminder['title'],
          'description': reminder['description'],
          'time': reminder['time'],
        }),
      );

      print("✅ Scheduled DAILY ${reminder['title']} at $hour:$minute");
    } catch (e) {
      print("❌ Error scheduling reminder ${reminder['title']}: $e");
      rethrow;
    }
  }

  void _checkRealTime() {
    DateTime phoneTime = DateTime.now();
    tz.TZDateTime appTime = tz.TZDateTime.now(tz.local);

    print("📱 PHONE TIME (DateTime.now()): $phoneTime");
    print("📱 PHONE HOUR: ${phoneTime.hour}:${phoneTime.minute}");
    print("📱 APP TIME (tz.now): $appTime");
    print("📱 APP HOUR: ${appTime.hour}:${appTime.minute}");
    print("📱 TIMEZONE: ${tz.local}");

    Duration difference = appTime.difference(phoneTime);
    print("📱 TIME DIFFERENCE: $difference");
  }

  String _getDayName(int dayOfWeek) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  tz.TZDateTime _calculateNextOccurrence({
    required int hour,
    required int minute,
    required int dayOfWeek,
  }) {
    // Use ONLY phone time
    DateTime phoneNow = DateTime.now();

    print("📱 USING ONLY PHONE TIME: ${phoneNow.hour}:${phoneNow.minute}");

    // Schedule using phone time
    var scheduled = tz.TZDateTime(
      tz.local,
      phoneNow.year,
      phoneNow.month,
      phoneNow.day,
      hour,
      minute,
    );

    print("  Scheduled for: $hour:$minute");

    // Adjust day of week
    int currentDayOfWeek = phoneNow.weekday;
    int daysToAdd = (dayOfWeek - currentDayOfWeek) % 7;
    scheduled = scheduled.add(Duration(days: daysToAdd));

    // Simple comparison with phone time
    DateTime scheduledAsDateTime = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
      scheduled.hour,
      scheduled.minute,
    );

    if (scheduledAsDateTime.isBefore(phoneNow)) {
      print("  ⚠️ Time has passed! Adding 1 day...");
      scheduled = scheduled.add(Duration(days: 1));
    }

    print("  ✅ Final: ${scheduled.hour}:${scheduled.minute}");
    return scheduled;
  }

  void _showTimePicker(int index) async {
    final timeStr = _reminders[index]['time'];
    final timeParts = timeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 8,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminders[index]['time'] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });

      _saveReminders();
    }
  }

  void _showDaysSelector(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<int> selectedDays = List.from(_reminders[index]['days']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Days',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: days.length,
                      itemBuilder: (context, dayIndex) {
                        final dayNumber = dayIndex + 1;
                        final isSelected = selectedDays.contains(dayNumber);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedDays.remove(dayNumber);
                              } else {
                                selectedDays.add(dayNumber);
                              }
                              selectedDays.sort();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _reminders[index]['color']
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _reminders[index]['color']
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                days[dayIndex],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[800],
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _reminders[index]['days'] = selectedDays;
                            });
                            _saveReminders();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _reminders[index]['color'],
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _testScheduled10Seconds() async {
    print("⏰ Testing scheduled notification in 10 seconds...");

    final scheduledDate = DateTime.now().add(Duration(seconds: 10));

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      888888,
      'Test in 10s 🔊',
      'This should play sound in 10 seconds',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test scheduled for 10 seconds later'),
        backgroundColor: Colors.blue,
      ),
    );

    print("✅ Test scheduled for 10 seconds later");
  }

  Future<void> _testNotification() async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Notifications for health activities',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(const [0, 500, 250, 500]),
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999999,
      'Test Notification',
      'Reminders are working properly with sound!',
      notificationDetails,
      payload: 'test_notification',
    );

    print("✅ Test notification sent with sound");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Health Reminders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.blue,
                            size: 30,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Stay Healthy",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Set reminders for daily health activities",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Active Reminders",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "${_reminders.where((r) => r['enabled'] == true).length} of ${_reminders.length}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.timer, color: Colors.blue, size: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return _reminderCard(reminder, index);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final enabledCount = _reminders
                                  .where((r) => r['enabled'] == true)
                                  .length;

                              if (enabledCount == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Please enable at least one reminder",
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              try {
                                final scheduledCount =
                                    await _scheduleAllNotifications();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "✅ Scheduled $scheduledCount Reminder",
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                await Future.delayed(
                                  const Duration(milliseconds: 1500),
                                );

                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                print("Error: $e");

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "❌ Failed to schedule reminders",
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt, size: 20),
                      label: _isLoading
                          ? const Text("Scheduling...")
                          : const Text("SAVE & SCHEDULE REMINDERS"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _reminderCard(Map<String, dynamic> reminder, int index) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: reminder['enabled']
              ? reminder['color'].withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: reminder['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reminder['icon'],
                    color: reminder['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder['description'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (reminder['enabled'] && reminder['days'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Daily at ${reminder['time']}", // Changed from "Every X days"
                            style: TextStyle(
                              fontSize: 12,
                              color: reminder['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: reminder['enabled'],
                    onChanged: (value) {
                      setState(() {
                        _reminders[index]['enabled'] = value;
                      });
                      _saveReminders();
                    },
                    activeTrackColor: reminder['color'].withOpacity(0.5),
                    inactiveTrackColor: Colors.grey.shade300,
                    activeThumbColor: reminder['color'],
                  ),
                ),
              ],
            ),
            if (reminder['enabled']) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showTimePicker(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reminder['time'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.blue.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDaysSelector(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${reminder['days'].length} days",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.blue.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (reminder['days'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Selected: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: days.asMap().entries.map((entry) {
                        final dayIndex = entry.key + 1;
                        final isSelected = reminder['days'].contains(dayIndex);

                        return Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? reminder['color']
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? reminder['color']
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
