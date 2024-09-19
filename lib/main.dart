import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  "coding_is_life_foreground", // চ্যানেলের ইউনিক আইডি
  "Coding is Life Foreground", // ব্যবহারকারীর জন্য বন্ধুত্বপূর্ণ নাম
  description: "This channel is used for foreground service notifications",
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();
  runApp(const MyApp());
}

Future<void> initService() async {
  var service = FlutterBackgroundService();

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(iOS: DarwinInitializationSettings()),
    );
  }

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);

  await service.configure(
    iosConfiguration: IosConfiguration(onBackground: iosBackground, onForeground: onStart),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: notificationChannel.id,
      initialNotificationTitle: "Coding Life Service",
      initialNotificationContent: "Awesome content",
      foregroundServiceNotificationId: 90,
    ),
  );
}

/// সার্ভিস শুরু করার জন্য পদ্ধতি
@pragma("vm:entry-point")
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  Timer.periodic(const Duration(seconds: 2), (timer) {
    flutterLocalNotificationsPlugin.show(
      90,
      "Cool Service",
      "Awesome ${DateTime.now()}",
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannel.id,
          notificationChannel.name,
          // description: "notificationChannel.description",
          ongoing: true,
          importance: Importance.high,
          icon: "app_icon"
        ),
      ),
    );
  });
}

/// iOS ব্যাকগ্রাউন্ড টাস্ক হ্যান্ডলার
@pragma("vm:entry-point")
Future<bool> iosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Background Service',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Background Service Example'),
        ),
        body: Center(
          child: Text('Background service is running!'),
        ),
      ),
    );
  }
}
