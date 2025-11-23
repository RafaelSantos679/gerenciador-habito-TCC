// TCC.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HabitApp());
}

class HabitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciamento de Hábitos',
      theme: ThemeData.light(),
      home: HabitHomePage(),
    );
  }
}

class HabitHomePage extends StatefulWidget {
  @override
  _HabitHomePageState createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference().child('habits');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _habitController = TextEditingController();
  List<Map<dynamic, dynamic>> _habitsList = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadHabits();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _loadHabits() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<Map<dynamic, dynamic>> loadedHabits = [];
        data.forEach((key, value) {
          loadedHabits.add({'key': key, 'habit': value['habit']});
        });
        setState(() {
          _habitsList = loadedHabits;
        });
      }
    });
  }

  void _scheduleReminder(String habit) async {
    var androidDetails = const AndroidNotificationDetails(
      'habit_channel',
      'Lembretes de Hábitos',
      channelDescription: 'Lembretes para execução de hábitos',
      importance: Importance.max,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Lembrete de Hábito',
      'Hora de realizar: $habit',
      platformDetails,
    );
  }

  void _addHabit() {
    final String habit = _habitController.text.trim();
    if (habit.isNotEmpty) {
      _dbRef.push().set({'habit': habit});
      _habitController.clear();
      _scheduleReminder(habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gerenciamento de Hábitos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _habitController,
                    decoration: InputDecoration(labelText: 'Novo Hábito'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addHabit,
                  child: Text('Adicionar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _habitsList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_habitsList[index]['habit']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
