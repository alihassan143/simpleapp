import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final double longitude;
  final double latitude;

  const LocationModel({required this.longitude, required this.latitude});
  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      LocationModel(longitude: json["longitude"], latitude: json["latitude"]);
  LocationModel copyWith({double? longitude, double? latitude}) =>
      LocationModel(
          longitude: longitude ?? this.longitude,
          latitude: latitude ?? this.latitude);
  Map<String, dynamic> toJson() {
    Map<String, dynamic> locationdata = {};
    locationdata["longitude"] = longitude;
    locationdata["latitude"] = latitude;
    return locationdata;
  }

  @override
  List<Object?> get props => [longitude, latitude];
}
