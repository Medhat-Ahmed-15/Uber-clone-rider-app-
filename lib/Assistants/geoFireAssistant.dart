// ignore_for_file: file_names

import 'package:uber_rider_app/Models/nearByAvailableDriver.dart';

class GeoFireAssistant {
  static List<NearByAvailableDriver> nearByAvailableDriversList = [];

  static void removeDriverFromList(String key) {
    int index =
        nearByAvailableDriversList.indexWhere((element) => element.key == key);

    nearByAvailableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(
      NearByAvailableDriver nearByAvailableDriver) {
    int index = nearByAvailableDriversList
        .indexWhere((element) => element.key == nearByAvailableDriver.key);

    nearByAvailableDriversList[index].latitude = nearByAvailableDriver.latitude;

    nearByAvailableDriversList[index].longitude =
        nearByAvailableDriver.longitude;
  }
}
