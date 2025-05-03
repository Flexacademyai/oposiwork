import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    tz.initializeTimeZones();
  }

  Future<void> _scheduleNotification(DateTime scheduledTime) async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Estudio',
      'Es hora de estudiar el tema de hoy',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_channel',
          'Recordatorios de Estudio',
          channelDescription: 'Recordatorios para tu calendario de estudio',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de estudio')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final date = DateTime.now().add(const Duration(seconds: 10));
            _scheduleNotification(date);
          },
          child: const Text('Programar recordatorio'),
        ),
      ),
    );
  }
}
