import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_rider_app/Models/history.dart';
import 'package:uber_rider_app/screens/aboutScreen.dart';
import 'package:uber_rider_app/screens/historyScreen.dart';
import 'package:uber_rider_app/screens/loginScreen.dart';
import 'package:uber_rider_app/screens/mainscreen.dart';
import 'package:uber_rider_app/screens/profileScreen.dart';
import 'package:uber_rider_app/screens/registrationScreen.dart';
import 'package:uber_rider_app/screens/searchScreen.dart';
import 'package:uber_rider_app/screens/splashScreen.dart';

import 'DataHandler/appData.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase
      .initializeApp(); //I have to initialize the firebase app otherwise i am gonna get error
  runApp(MyApp());
}

DatabaseReference userRef = FirebaseDatabase.instance.reference().child(
    'users'); //the reason for you can say, defining or initializing the database reference here on demand or dot file outside the glass is now whenever we need to choose a reference. OK, we will just call it anywhere, I mean at any page when we need it.

DatabaseReference driverRef =
    FirebaseDatabase.instance.reference().child('drivers');

DatabaseReference newRequestRef =
    FirebaseDatabase.instance.reference().child('Ride Requests');

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        title: 'Taxi Rider App',
        theme: ThemeData(
          primaryColor: Colors.yellow[700],
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner:
            false, //if i make true it will display that this application is in debug model plus hathot el debug banner el bayb2 fal top right corner of the screen ,false hatsheel el debug banner

        routes: {
          LoginScreen.routeName: (ctx) => LoginScreen(),
          HistoryScreen.routeName: (ctx) => HistoryScreen(),
          RegistrationScreen.routeName: (ctx) => RegistrationScreen(),
          MainScreen.routeName: (ctx) => MainScreen(),
          SearchScreen.routeName: (ctx) => SearchScreen(),
          AboutScreen.routeName: (ctx) => AboutScreen(),
          ProfileScreen.routeName: (ctx) => ProfileScreen(),
        },
      ),
    );
  }
}
