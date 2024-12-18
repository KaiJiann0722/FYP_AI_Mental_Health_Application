import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class JournalNotificationPage extends StatefulWidget {
  @override
  _JournalNotificationPageState createState() =>
      _JournalNotificationPageState();
}

class _JournalNotificationPageState extends State<JournalNotificationPage> {
  bool _notificationsEnabled = false;
  int _frequency = 1;
  List<String> _selectedTimes = [];
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _notificationManager.initNotifications();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _frequency = prefs.getInt('notification_frequency') ?? 1;
      _selectedTimes = prefs.getStringList('notification_times') ?? ['18:00'];
    });
  }

  Future<void> _addNotificationTime() async {
    if (_selectedTimes.length >= _frequency) {
      // Show a dialog or snackbar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only add ${_frequency} notification times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.lightBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      final prefs = await SharedPreferences.getInstance();
      final formattedTime = pickedTime.hour.toString().padLeft(2, '0') +
          ':' +
          pickedTime.minute.toString().padLeft(2, '0');

      setState(() {
        if (!_selectedTimes.contains(formattedTime)) {
          _selectedTimes.add(formattedTime);
          prefs.setStringList('notification_times', _selectedTimes);
        }
      });

      await _notificationManager.scheduleNotifications();
    }
  }

  void _removeNotificationTime(String time) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedTimes.remove(time);
      prefs.setStringList('notification_times', _selectedTimes);
    });

    await _notificationManager.scheduleNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatTime(String time24Hour) {
    final parts = time24Hour.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    final time = DateTime(now.year, now.month, now.day, hour, minute);
    return DateFormat.jm().format(time); // "6:30 PM"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notifications Enable Card
              _buildSettingsCard(
                title: 'Enable Notifications',
                child: SwitchListTile(
                  title: Text(
                    'Receive Journal Reminders',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Toggle to turn notifications on or off',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  value: _notificationsEnabled,
                  activeColor: Colors.lightBlue,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (bool value) async {
                    final prefs = await SharedPreferences.getInstance();
                    setState(() {
                      _notificationsEnabled = value;
                      prefs.setBool('notifications_enabled', value);
                    });

                    await _notificationManager.scheduleNotifications();
                  },
                ),
              ),

              SizedBox(height: 16),

              // Frequency Card
              _buildSettingsCard(
                title: 'Notification Frequency',
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reminders',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Choose notification count',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<int>(
                        value: _frequency,
                        dropdownColor: Colors.white,
                        items: List.generate(5, (index) => index + 1)
                            .map((freq) => DropdownMenuItem(
                                  value: freq,
                                  child: Text(
                                    '$freq time${freq > 1 ? 's' : ''} per day',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ))
                            .toList(),
                        onChanged: _notificationsEnabled
                            ? (int? newFrequency) {
                                if (newFrequency != null) {
                                  _saveNotificationFrequency(newFrequency);
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Notification Times Card
              _buildSettingsCard(
                title: 'Notification Times',
                child: Column(
                  children: [
                    ..._selectedTimes
                        .map((time) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(time),
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        _removeNotificationTime(time),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'Add Notification Time',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed:
                            _notificationsEnabled ? _addNotificationTime : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(
            color: Colors.grey[300],
            height: 1,
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _saveNotificationFrequency(int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _frequency = frequency;
      prefs.setInt('notification_frequency', frequency);
    });

    await _notificationManager.scheduleNotifications();
  }
}
