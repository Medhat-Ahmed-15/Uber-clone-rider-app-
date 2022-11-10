// ignore_for_file: file_names

import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uber_rider_app/Assistants/requestAssistant.dart';
import 'package:uber_rider_app/DataHandler/appData.dart';
import 'package:uber_rider_app/Models/address.dart';
import 'package:uber_rider_app/Models/allUsers.dart';
import 'package:uber_rider_app/Models/directdetails.dart';
import 'package:uber_rider_app/Models/history.dart';
import 'package:uber_rider_app/configMaps.dart';
import 'package:http/http.dart' as http;
import 'package:uber_rider_app/main.dart';

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, BuildContext context) async {
    String placeAddress = "";

    String placeAddress1;
    String placeAddress2;
    String placeAddress3;
    String placeAddress4;

    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestAssistant.getRequest(url);

    if (response != "failed") {
      // placeAddress = response["results"][0][
      //     "formatted_address"]; //since the formatted address displays the specific address of the current location and this is risky regarding the security
      placeAddress1 =
          response["results"][0]["address_components"][0]["long_name"];
      placeAddress2 =
          response["results"][0]["address_components"][2]["long_name"];
      placeAddress4 =
          response["results"][0]["address_components"][5]["long_name"];

      placeAddress =
          placeAddress1 + ", " + placeAddress2 + ", " + placeAddress4;

      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectiondetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        'https://maps.googleapis.com/maps/api/directions/json?&destination=${finalPosition.longitude},${finalPosition.latitude}&origin=${initialPosition.longitude},${initialPosition.latitude}&key=$mapKey';

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == 'failed') {
      return null;
    }

    DirectionDetails directiondetails = DirectionDetails();

    directiondetails.encodedPoints =
        res['routes'][0]['overview_polyline']['points'];

    directiondetails.distanceText =
        res['routes'][0]['legs'][0]['distance']['text'];

    directiondetails.distancevalue =
        res['routes'][0]['legs'][0]['distance']['value'];

    directiondetails.durationText =
        res['routes'][0]['legs'][0]['duration']['text'];

    directiondetails.durationValue =
        res['routes'][0]['legs'][0]['duration']['value'];

    return directiondetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    //in terms USD
    double timeTravelFare = (directionDetails.durationValue / 60) * 0.20;
    double distanceTravelFare = (directionDetails.distancevalue / 1000) * 0.20;
    double totalFareAmount = timeTravelFare + distanceTravelFare;

    //local currency
    //1$=16EG
    double totalLocalAmount = totalFareAmount * 16;
    return totalLocalAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance
        .currentUser; //'firebaseUser' defined globaly in configMaps.dart

    String userID = firebaseUser.uid;

//bageeb hna location el data el ana 3ayzha
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child('users').child(userID);

//hna ba2 barooh lal location dah w 2ageeb el ana 3ayzo
    reference.once().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        userCurrentInfo = Users.fromSnapshot(
            dataSnapshot); // 'userCurrentInfo' defined it globally in configMaps.dart
      }
    });
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(
      String token, context, String rideRequestId) async {
    print('Ride request id: $rideRequestId');
    print('token: $token');
    print('Authorization: $serverToken');
    var destination =
        Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverToken,
    };

    Map notificationMap = {
      'body': 'DropOff Address, ${destination.placeName}',
      'title': 'New Ride Request'
    };

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': rideRequestId
    };

    Map sendNotificationMap = {
      'notification': notificationMap,
      'data': dataMap,
      'priority': 'high',
      'to': token
    };

    try {
      final response = await http.post(
        'https://fcm.googleapis.com/fcm/send',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': serverToken,
        },
        body: json.encode(
          {
            "notification": {
              "body": 'DropOff Address, ${destination.placeName}',
              "title": "New Ride Request"
            },
            "priority": "high",
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "id": "1",
              "status": "done",
              "ride_request_id": rideRequestId
            },
            "to": token
          },
        ),
      );
    } catch (err) {
      print('errorrrr: $err');
    }
  }

  static void retrieveHistoryInfo(context) {
    //retreive and trip history
    newRequestRef
        .orderByChild('rider_name')
        .once()
        .then(((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        //update total number of trip counts to Provider
        Map<dynamic, dynamic> keys = dataSnapshot.value;
        int tripCounter = keys.length;
        print('TRIP COUNTER:: ${tripCounter}');
        Provider.of<AppData>(context, listen: false)
            .updateTripCounter(tripCounter);

        //update trip keys to provider
        List<String> tripHistorykeys = [];
        keys.forEach((key, value) {
          print('TRIP KEY:: ${key}');
          tripHistorykeys.add(key);
        });

        Provider.of<AppData>(context, listen: false)
            .updateTripKeys(tripHistorykeys);

        obtainTripRequestHistoryData(context);
      }
    }));
  }

  static void obtainTripRequestHistoryData(context) {
    var keys = Provider.of<AppData>(context, listen: false).tripHistoryKeys;

    for (String key in keys) {
      newRequestRef.child(key).once().then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          newRequestRef
              .child(key)
              .child("rider_name")
              .once()
              .then((DataSnapshot dSnap) {
            String name = dSnap.value.toString();

            if (name == userCurrentInfo.name) {
              var history = History.fromSnapshot(snapshot);
              Provider.of<AppData>(context, listen: false)
                  .updateTripHistoryData(history);
              print('111111111111111');
            }
          });
        }
      });
    }
  }

  static String formatTripDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate =
        "${DateFormat.MMMd().format(dateTime)},${DateFormat.y().format(dateTime)}-${DateFormat.jm().format(dateTime)}";

    return formattedDate;
  }
}
