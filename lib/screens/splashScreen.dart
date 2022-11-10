// ignore: file_names
// ignore_for_file: file_names
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:uber_rider_app/screens/loginScreen.dart';
import 'package:lottie/lottie.dart' as lot;
import 'package:uber_rider_app/screens/mainscreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      backgroundColor: Colors.white,
      centered: true,
      splashIconSize: 250,
      duration: 4000,
      splashTransition: SplashTransition.fadeTransition,
      nextScreen: FirebaseAuth.instance.currentUser == null
          ? LoginScreen()
          : MainScreen(),
      splash: Center(
        child: SizedBox(
          width: double.infinity,
          height: 300,
          child: lot.LottieBuilder.asset('assets/images/splash.json'),
        ),
      ),
    );
  }
}
