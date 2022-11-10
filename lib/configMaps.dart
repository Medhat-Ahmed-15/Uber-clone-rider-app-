// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber_rider_app/Models/allUsers.dart';

String mapKey = 'AIzaSyA0LLNiEnjHKM5kgKqb79-_UsBHyki3RHE';

User firebaseUser;

Users userCurrentInfo;

int driverRequestTimeOut = 40;

//String statusRide = "";
String carDetailsDriver = "";
String driverName = "";
String driverPhone = "";

double starCounter = 0.0;
String title = "";
String carRideType = "";

String serverToken =
    'key=AAAAB6Bctgw:APA91bGnk3Cru1rllVkQo2dpfQdpKjf0L8iFvz1QRcAiPfe66ok1tf6Gu9LTvMLDQU2oxh-DoAinH-jDzGIt7yv4DmfVahBqZdH4VCw1AVjeRm5ZpqoWtJX6i78AYNom_B3GFl9K4qTU';
