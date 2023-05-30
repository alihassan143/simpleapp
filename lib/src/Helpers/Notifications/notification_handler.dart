import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskapp/src/Constants/app_constant.dart';
import 'package:taskapp/src/Navigation/navigation.dart';
import 'package:taskapp/src/Ui/map_ui.dart';
import 'package:taskapp/src/core/Model/location_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.setupFlutterNotifications();
  NotificationService.showFlutterNotification(message);

  print('Handling a background message ${message.messageId}');
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  Map<String, dynamic> payloadData = jsonDecode(notificationResponse.payload!);
  String userid = payloadData[AppConstants.userIdKey];
  String username = payloadData[AppConstants.userName];
  Map<String, dynamic> locationData =
      jsonDecode(payloadData[AppConstants.location]);
  LocationModel initialLocation = LocationModel.fromJson(locationData);
  NavigationService.navigateToScreen(MapUi(
    userId: userid,
    initialLocation: initialLocation,
    userName: username,
  ));
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static Future<void> initNotifications() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await setupFlutterNotifications();
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<void> setupFlutterNotifications() async {
    var androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        if (payload != null) {
          Map<String, dynamic> jsondata = jsonDecode(payload);
          firebaseNotificationClicked(jsondata);
        }
      },
    );
    var initSetttings =
        InitializationSettings(android: androidSettings, iOS: iOSSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    final InitializationSettings initializationSettings = initSetttings;
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        onDidReceiveNotificationResponse:
            handleApplicationWasLaunchedFromNotificationWhenAppOpen);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance
        .subscribeToTopic(AppConstants.collectionName);
    FirebaseMessaging.onMessage.listen(showFlutterNotification);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    handleApplicationWasLaunchedFromNotificationWhenAppOpen(
        await notificationResponse());
  }

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );
  static void showFlutterNotification(RemoteMessage message) {
    log(message.data.toString());
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,

              channelDescription: channel.description,
              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data));
    }
  }

  static void handleApplicationWasLaunchedFromNotificationWhenAppOpen(
    NotificationResponse? response,
  ) {
    Map<String, dynamic> payloadData =
        getUserDataFromPayload(response!.payload!);
    String userid = payloadData[AppConstants.userIdKey];
    String username = payloadData[AppConstants.userName];
    Map<String, dynamic> locationData =
        jsonDecode(payloadData[AppConstants.location]);
    LocationModel initialLocation = LocationModel.fromJson(locationData);

    NavigationService.navigateToScreen(MapUi(
      userId: userid,
      initialLocation: initialLocation,
      userName: username,
    ));
  }

  static void firebaseNotificationClicked(
      Map<String, dynamic> payloadData) async {
    String userid = payloadData[AppConstants.userIdKey];
    Map<String, dynamic> locationData = payloadData[AppConstants.location];
    LocationModel initialLocation = LocationModel.fromJson(locationData);
    String username = payloadData[AppConstants.userName];

    NavigationService.navigateToScreen(MapUi(
      userId: userid,
      initialLocation: initialLocation,
      userName: username,
    ));
  }

  static Map<String, dynamic> getUserDataFromPayload(String payload) {
    Map<String, dynamic> json = jsonDecode(payload);

    return json;
  }

  static Future<bool?> wasApplicationLaunchedFromNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    return notificationAppLaunchDetails?.didNotificationLaunchApp;
  }

  static Future<NotificationResponse?> notificationResponse() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    return notificationAppLaunchDetails?.notificationResponse;
  }
}
