import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taskapp/src/core/Model/location_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../core/AppService/app_repository.dart';
import '../core/AppService/app_service.dart';

enum LocationParams { searching, successfull, error }

class ShareLocationScreen extends StatefulWidget {
  const ShareLocationScreen({super.key});

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  Position? position;
  final TextEditingController controller = TextEditingController();
  Timer? timer;
  late final AppService appService;
  GoogleMapController? mapController;
  LocationParams locationParams = LocationParams.searching;

  @override
  void initState() {
    appService = AppRepository();
    getLocation();
    // getDetails();
    // TODO: implement initState
    super.initState();
  }

  // getDetails() async {
  //   try {
  //     bool? value =
  //         await NotificationService.wasApplicationLaunchedFromNotification();
  //     if (value != null) {
  //       if (value) {
  //         NotificationService
  //             .handleApplicationWasLaunchedFromNotificationWhenAppOpen(
  //                 await NotificationService.notificationResponse());
  //       } else {
  //         Fluttertoast.showToast(msg: "false");
  //       }
  //     } else {
  //       Fluttertoast.showToast(msg: "no data");
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: e.toString());
  //   }
  // }

  getLocation() async {
    try {
      Position newposition = await appService.getCurrentPosition();
      log(newposition.toJson().toString());
      setState(() {
        locationParams = LocationParams.successfull;
        position = newposition;
      });
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            bearing: 270.0,
            target: LatLng(position!.latitude, position!.longitude),
            tilt: 30.0,
            zoom: 17.0,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        locationParams = LocationParams.error;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share Location"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(locationParams == LocationParams.error
              ? "Error Getting Location"
              : locationParams == LocationParams.successfull
                  ? "Longitude: ${position!.longitude}  Latitude:${position!.latitude}"
                  : "Searching"),
          TextField(
            controller: controller,
          ),
          ElevatedButton(
              onPressed: () async {
                if (position == null) {
                  Fluttertoast.showToast(
                      msg: "Kindly Enable Location Again and restart app",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                } else if (controller.text.trim().isEmpty) {
                  Fluttertoast.showToast(
                      msg: "Kindly Enter Your Name",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                } else {
                  LocationModel locationModel = LocationModel(
                      longitude: position!.longitude,
                      latitude: position!.latitude);
                  await appService.updateLocation(locationModel);
                  await appService.sendNotification(
                      userName: controller.text.trim(),
                      locationModel: locationModel);
                  Fluttertoast.showToast(
                      msg: "Location Shared",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                      fontSize: 16.0);
                  timer =
                      Timer.periodic(const Duration(seconds: 5), (timer) async {
                    await getLocation();
                    appService.updateLocation(LocationModel(
                        longitude: position!.longitude,
                        latitude: position!.latitude));
                    mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          bearing: 270.0,
                          target:
                              LatLng(position!.latitude, position!.longitude),
                          tilt: 30.0,
                          zoom: 17.0,
                        ),
                      ),
                    );
                  });
                }
              },
              child: const Text("Share Live Location")),
          ElevatedButton(
              onPressed: () {
                timer?.cancel();
                Fluttertoast.showToast(
                    msg: "Location Sharing Cancelled",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.TOP,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
              child: const Text("Cancel Live Location")),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  locationParams = LocationParams.searching;
                });
                getLocation();
              },
              child: const Text("Get Location Again")),
          Expanded(
              child: GoogleMap(
                  mapType: MapType.normal,
                  onMapCreated: _onMapCreated,
                  markers: {
                    Marker(
                        markerId: const MarkerId("value"),
                        position: LatLng(
                            position == null ? 0 : position!.latitude,
                            position == null ? 0 : position!.longitude))
                  },
                  initialCameraPosition: CameraPosition(
                      target: LatLng(position == null ? 0 : position!.latitude,
                          position == null ? 0 : position!.longitude),
                      zoom: 15)))
        ],
      ),
    );
  }
}
