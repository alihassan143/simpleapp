import 'package:taskapp/src/core/Model/location_model.dart';
import 'package:geolocator/geolocator.dart';

abstract class AppService {
  Future<void> updateLocation(LocationModel locationModel);
  Future<void> sendNotification(
      {required String userName, required LocationModel locationModel});
  Stream<LocationModel> getLatestLocation(String userid,);
  Future<Position> getCurrentPosition();
    String getUserId();
 
}
