import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final StopWatchTimer _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);

const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  "stopwatch_foreground",
  "Stopwatch Foreground",
  description: "This channel is used for stopwatch notifications",
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();
  runApp(const MyApp());
}

Future<void> initService() async {
  var service = FlutterBackgroundService();

  // Initialize local notifications
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(iOS: DarwinInitializationSettings()),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);

  // Configure the background service
  await service.configure(
    iosConfiguration: IosConfiguration(
      onBackground: iosBackground,
      onForeground: onStart,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: notificationChannel.id,
      initialNotificationTitle: "Stopwatch Service",
      initialNotificationContent: "Counting time...",
      foregroundServiceNotificationId: 100,
    ),
  );

  service.startService(); // Ensure the service starts
}

@pragma("vm:entry-point")
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  _stopWatchTimer.onStartTimer();

  Timer.periodic(const Duration(seconds: 1), (timer) {
    // if (service.) {
    //   _stopWatchTimer.onStopTimer();
    //   timer.cancel();
    // } else {
      final currentTime = _stopWatchTimer.rawTime.value;
      final displayTime = StopWatchTimer.getDisplayTime(currentTime, hours: true, milliSecond: false);

      flutterLocalNotificationsPlugin.show(
        100,
        "Stopwatch Running",
        displayTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannel.id,
            notificationChannel.name,
            ongoing: true,
            importance: Importance.high,
            icon: "app_icon",
          ),
        ),
      );
    // }
  });
}

@pragma("vm:entry-point")
Future<bool> iosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch Background Service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StopwatchScreen(),
    );
  }
}

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  @override
  void initState() {
    super.initState();
    _stopWatchTimer.rawTime.listen((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch with Background Service'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<int>(
              stream: _stopWatchTimer.rawTime,
              initialData: _stopWatchTimer.rawTime.value,
              builder: (context, snapshot) {
                final value = snapshot.data!;
                final displayTime = StopWatchTimer.getDisplayTime(value, hours: true, milliSecond: false);
                return Text(
                  displayTime,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _stopWatchTimer.onStartTimer();
              },
              child: const Text('Start Stopwatch'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _stopWatchTimer.onStopTimer();
              },
              child: const Text('Stop Stopwatch'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    super.dispose();
  }
}
