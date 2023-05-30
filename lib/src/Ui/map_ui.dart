import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taskapp/src/Constants/app_constant.dart';
import 'package:taskapp/src/core/Model/location_model.dart';

import '../core/AppService/app_repository.dart';
import '../core/AppService/app_service.dart';

class MapUi extends StatefulWidget {
  final String userId;
  final LocationModel initialLocation;
  final String userName;
  const MapUi(
      {super.key,
      required this.userId,
      required this.initialLocation,
      required this.userName});

  @override
  State<MapUi> createState() => _MapUiState();
}

class _MapUiState extends State<MapUi> {
  late LatLng initialLocation;
  Marker marker = Marker(
    markerId: MarkerId(AppConstants.collectionName),
    position: const LatLng(0, 0),
  );
  GoogleMapController? mapController;
  late final AppService appService;
  late final CameraPosition cameraPosition;
  @override
  void initState() {
    appService = AppRepository();
    final location = LatLng(
        widget.initialLocation.latitude, widget.initialLocation.longitude);
    Marker(
      markerId: MarkerId(AppConstants.collectionName),
      position: location,
    );
    initialLocation = location;
    appService.getLatestLocation(widget.userId).listen((event) {
      setState(() {
        initialLocation = LatLng(event.latitude, event.longitude);
        marker = Marker(
          markerId: MarkerId(AppConstants.collectionName),
          position: LatLng(event.latitude, event.longitude),
        );
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              bearing: 270.0,
              target: LatLng(event.latitude, event.longitude),
              tilt: 30.0,
              zoom: 17.0,
            ),
          ),
        );
      });
    });
    cameraPosition = CameraPosition(
      target: initialLocation,
      zoom: 14,
    );

    // TODO: implement initState
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName} Location"),
      ),
      body: GoogleMap(
        markers: {marker},
        initialCameraPosition: cameraPosition,
        onMapCreated: _onMapCreated,
        // ToDO: add markers
      ),
    );
  }
}
