import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:taskapp/main.dart';
import 'package:taskapp/src/Constants/app_constant.dart';
import 'package:taskapp/src/core/AppService/app_service.dart';
import 'package:taskapp/src/core/Model/location_model.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:uuid/uuid.dart";

class AppRepository extends AppService {
  final Dio _dio = Dio();
  final Uuid uuid = const Uuid();
  CollectionReference reference =
      FirebaseFirestore.instance.collection(AppConstants.collectionName);
  @override
  Future<Position> getCurrentPosition() async {
    try {
      log("message");
      late bool serviceEnabled;
      late LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
        return Future.error('Location services are disabled.');
      }
      log(serviceEnabled.toString());
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, next time you could try
          // requesting permissions again (this is also where
          // Android's shouldShowRequestPermissionRationale
          // returned true. According to Android guidelines
          // your App should show an explanatory UI now.
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      log(e.toString());
      throw Exception(e);
    }
  }

  @override
  Stream<LocationModel> getLatestLocation(String userid) {
    return reference.doc(userid).snapshots().map((event) =>
        LocationModel.fromJson(event.data() as Map<String, dynamic>));
  }

  @override
  Future<void> sendNotification(
      {required String userName, required LocationModel locationModel}) async {
    String currentuserId = getUserId();
    _dio.options.headers[AppConstants.authorization] = AppConstants.authKey;
    _dio.options.headers[AppConstants.contentType] =
        AppConstants.applicationjson;

    try {
      final response = await _dio.post(AppConstants.fcmServerUrl, data: {
        "to": "/topics/${AppConstants.collectionName}",
        "notification": {
          "title": userName,
          "body": "Shared his location",
          
        },
        'priority': 'high',
        "data": {
          AppConstants.userIdKey: currentuserId,
         AppConstants.userName:userName,
          AppConstants.location: locationModel.toJson()
        }
      });
      log("notification response==>${response.data}");
      return;
    } catch (e) {
      log("notification error==>$e");
      throw Exception(e);
    }
    // TODO: implement sendNotification
  }

  @override
  Future<void> updateLocation(LocationModel locationModel) async {
    String userId = getUserId();
    await reference.doc(userId).set(locationModel.toJson());
    return;
  }

  @override
  String getUserId() {
    String? userId = storageService.get(AppConstants.collectionName);

    if (userId == null) {
      userId = uuid.v4();
      storageService.set(AppConstants.collectionName, userId);

      return userId;
    } else {
      return userId;
    }
  }
}
