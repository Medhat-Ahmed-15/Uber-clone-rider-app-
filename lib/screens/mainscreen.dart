// ignore_for_file: unnecessary_new

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:slider_button/slider_button.dart';
import 'package:uber_rider_app/Assistants/assistantMethods.dart';
import 'package:uber_rider_app/Assistants/geoFireAssistant.dart';
import 'package:uber_rider_app/DataHandler/appData.dart';
import 'package:uber_rider_app/Models/directdetails.dart';
import 'package:uber_rider_app/Models/nearByAvailableDriver.dart';
import 'package:uber_rider_app/configMaps.dart';
import 'package:uber_rider_app/main.dart';
import 'package:uber_rider_app/screens/aboutScreen.dart';
import 'package:uber_rider_app/screens/historyScreen.dart';
import 'package:uber_rider_app/screens/loginScreen.dart';
import 'package:uber_rider_app/screens/profileScreen.dart';
import 'package:uber_rider_app/screens/ratingScreen.dart';
import 'package:uber_rider_app/screens/registrationScreen.dart';
import 'package:uber_rider_app/widgets/collectFareDialog.dart';
import 'package:uber_rider_app/widgets/noDriverAvailableDialog.dart';
import 'package:uber_rider_app/widgets/progressDialog.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:url_launcher/url_launcher.dart';
import 'searchScreen.dart';

import 'package:lottie/lottie.dart' as lot;

class MainScreen extends StatefulWidget {
  static const routeName = '/MainScreen';
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  //The main difference between List and Set is that Set is unordered and contains different elements, whereas the list is ordered and can contain the same elements in it.
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double requestRideContainerHeight = 0.0;
  double bottomPaddingOfMap = 300;
  double driverDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;
  bool isRequestingPositionDetails = false;

  DatabaseReference rideRequestRef;

  DirectionDetails tripDirectionDetails;

  BitmapDescriptor nearByIcon;

  List<NearByAvailableDriver> availableDrivers;
  String state = 'normal';
  String uName = "";
  String rideStatus = "";
  String currentState = "";

  StreamSubscription<Event> rideStreamSubscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRiderequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child('Ride Requests').push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      'latitude': pickUp.latitude.toString(),
      'longitude': pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      'latitude': dropOff.latitude.toString(),
      'longitude': dropOff.longitude.toString(),
    };

    Map rideinfoMap = {
      'driver_id': 'waiting',
      'payment_method': 'cash',
      'pickUp': pickUpLocMap,
      'dropOff': dropOffLocMap,
      'created_at': DateTime.now().toString(),
      'rider_name': userCurrentInfo.name,
      'rider_id': userCurrentInfo.id,
      'rider_phone': userCurrentInfo.phone,
      'pickup_address': pickUp.placeName,
      'dropOff_address': dropOff.placeName,
      'ride_type': carRideType,
    };

    rideRequestRef.set(rideinfoMap);

    rideStreamSubscription = rideRequestRef.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }
      print('Listnegingggg');

      if (event.snapshot.value["car_details"] != null) {
        setState(() {
          carDetailsDriver = event.snapshot.value["car_details"].toString();
        });
      }

      if (event.snapshot.value["driver_name"] != null) {
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }

      if (event.snapshot.value["driver_location"] != null) {
        double driverLat =
            double.parse(event.snapshot.value["driver_location"]["latitude"]);

        double driverLng =
            double.parse(event.snapshot.value["driver_location"]["longitude"]);

        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

        if (event.snapshot.value["status"].toString() == "accepted") {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        }

        if (event.snapshot.value["status"].toString() == "onride") {
          print('Going to Destination');
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        }
        if (event.snapshot.value["status"].toString() == "arrived") {
          setState(() {
            currentState = 'arrived';
            rideStatus = "Driver has Arrived .";
          });
          print('arrived');
        }
      }

      if (event.snapshot.value["driver_phone"] != null) {
        setState(() {
          driverPhone = event.snapshot.value["driver_phone"].toString();
        });
      }

      if (event.snapshot.value["status"].toString() == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener(); //stop listning to near by drivers
        deleteGeofileMarkers();
      }

      if (event.snapshot.value["status"].toString() == "cancelled") {
        rideRequestRef.onDisconnect();
        rideRequestRef = null;
        rideStreamSubscription.cancel();
        rideStreamSubscription = null;
        resetApp();
      }

      if (event.snapshot.value["status"].toString() == "ended") {
        if (event.snapshot.value["fares"] != null) {
          int fare = int.parse(event.snapshot.value["fares"].toString());
          var response = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectFareDialog(
              paymentMethod: "cash",
              fareAmount: fare,
            ),
          );

          String driverId = "";
          if (response == "close") {
            if (event.snapshot.value["driver_id"] != null) {
              driverId = event.snapshot.value["driver_id"].toString();
            }
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RatingScreen(
                      driverId: driverId,
                    )));
            rideRequestRef.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofileMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains('driver'));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails =
          true; //3ashan maya3mlsh call 3amal 3ala batal, yastana el await el 2wl ba3dein ya3ml call tany
      var positionUserLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

//keda haygeeb el etails mabein location el driver w location el rider
      var details = await AssistantMethods.obtainPlaceDirectiondetails(
          driverCurrentLocation, positionUserLatLng);

      if (details == null) {
        return;
      }

      setState(() {
        currentState = 'coming';
        rideStatus = "Driver is Coming - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    print('Going to Destination');
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails =
          true; //3ashan maya3mlsh call 3amal 3ala batal, yastana el await el 2wl ba3dein ya3ml call tany
      var dropOff =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffLatLng = LatLng(dropOff.latitude, dropOff.longitude);

//keda haygeeb el etails mabein location el driver w location el rider
      var details = await AssistantMethods.obtainPlaceDirectiondetails(
          driverCurrentLocation, dropOffLatLng);

      if (details == null) {
        return;
      }

      setState(() {
        currentState = 'going';
        rideStatus = "Going to Destination - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 300.0;
      driverDetailsContainerHeight = 320.0;
    });
  }

  void cancelRiderequest() {
    rideRequestRef.remove();
    setState(() {
      state = 'normal';
    });
    resetApp();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = true;
    });

    saveRiderequest();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      rideDetailsContainerHeight = 340;
      searchContainerHeight = 0.0;
      bottomPaddingOfMap = 360;
      drawerOpen = false;
    });
  }

  resetApp() {
    setState(() {
      rideDetailsContainerHeight = 0;
      searchContainerHeight = 300.0;
      bottomPaddingOfMap = 300;
      requestRideContainerHeight = 0;
      drawerOpen = true;

      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      //statusRide = "";
      driverName = "";
      driverPhone = "";
      carDetailsDriver = "";
      rideStatus = "";
      driverDetailsContainerHeight = 0.0;
    });

    locatePosition();
  }

  static final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Position currentPosition;
  var geoLocator = Geolocator();

//Locating current location
  void locatePosition() async {
    //get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    currentPosition = position;

    //get latitude and longitude from that position
    LatLng latlngPosition = LatLng(position.latitude, position.longitude);

    //locating camera towards this position
    CameraPosition cameraPosition =
        new CameraPosition(target: latlngPosition, zoom: 14);

    //updating the camera position
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//converting latlng to readable addresses
    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);

    initGeoFireListner();
    uName = userCurrentInfo.name;

    AssistantMethods.retrieveHistoryInfo(context);
  }

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.yellow[700]),
                  child: Row(
                    children: [
                      // Image.asset(
                      //   'assets/images/user_icon.png',
                      //   height: 65.0,
                      //   width: 65.0,
                      // ),

                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/images/user_icon.png',
                          height: 35.0,
                          width: 35.0,
                        ),
                      ),
                      const SizedBox(
                        width: 16.0,
                      ),
                      Text(
                        uName,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //Drawer Body Controllers
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, HistoryScreen.routeName);
                },
                child: ListTile(
                  leading: Icon(
                    Icons.history,
                    color: Colors.yellow[700],
                  ),
                  title:
                      const Text('History', style: TextStyle(fontSize: 15.0)),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, ProfileScreen.routeName, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.yellow[700]),
                  title: const Text('Visit Profile',
                      style: TextStyle(fontSize: 15.0)),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AboutScreen.routeName, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info, color: Colors.yellow[700]),
                  title: const Text('About', style: TextStyle(fontSize: 15.0)),
                ),
              ),

              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.routeName, (route) => false);
                },
                leading: Icon(Icons.logout, color: Colors.yellow[700]),
                title: const Text('Sign Out', style: TextStyle(fontSize: 15.0)),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            mapType: MapType.normal,
            markers: markersSet,
            circles: circlesSet,
            polylines: polyLineSet,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              // setState(() {
              //   bottomPaddingOfMap = 300.0;
              // });

              locatePosition();
            },
          ),

          //Hamburger Button
          Positioned(
            top: 38.0,
            left: 22.0,
            child: FlatButton(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onPressed: () {
                if (!drawerOpen) {
                  resetApp();
                } else {
                  scaffoldKey.currentState.openDrawer();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.yellow[700],
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.yellow[700],
                  child: Icon(
                    drawerOpen ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //Search UI
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 6.0,
                      ),
                      Text(
                        'Hi there, ',
                        style: TextStyle(
                            fontSize: 12.0, color: Colors.yellow[700]),
                      ),
                      const Text(
                        'Where to?, ',
                        style: TextStyle(
                            fontSize: 20.0, fontFamily: 'Brand-semibold'),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            // borderRadius:
                            //     const BorderRadius.all(Radius.circular(20)),
                            border: Border(
                                top: BorderSide(
                                  color: Colors.yellow[700],
                                  width: 3,
                                ),
                                bottom: BorderSide(
                                  color: Colors.yellow[700],
                                  width: 3,
                                ),
                                left: BorderSide(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                right: BorderSide(
                                  color: Colors.white,
                                  width: 3,
                                ))),
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: SliderButton(
                              alignLabel: Alignment.center,
                              child: Image.asset('assets/images/uberx.png'),

                              action: () async {
                                String res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SearchScreen())) as String;

                                if (res == 'obtainDirection') {
                                  displayRideDetailsContainer();
                                }
                              },
                              dismissible: false,
                              dismissThresholds: 0.4,

                              ///Put label over here
                              label: const Text(
                                "Slide to ride !",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17),
                              ),

                              //Put BoxShadow here
                              boxShadow: const BoxShadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),

                              //Adjust effects such as shimmer and flag vibration here
                              shimmer: true,
                              vibrationFlag: false,

                              ///Change All the color and size from here.
                              width: double.infinity,
                              radius: 20,
                              buttonColor: Colors.yellow[700],
                              backgroundColor: Colors.white,
                              highlightedColor: Colors.black,
                              baseColor: Colors.yellow[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.yellow[700],
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Provider.of<AppData>(context)
                                          .pickUpLocation !=
                                      null
                                  ? Provider.of<AppData>(context)
                                      .pickUpLocation
                                      .placeName
                                  : 'Add Home'),
                              const SizedBox(
                                height: 4.0,
                              ),
                              const Text(
                                'Your living home address',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Ride Details UI
          Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          //Bike Ride
                          GestureDetector(
                            onTap: () {
                              displayToastMessage("searching Bike...");
                              setState(() {
                                state = 'requesting';
                                carRideType = "bike";
                              });

                              displayRequestRideContainer();
                              availableDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;
                              searchNearestDriver();
                            },
                            child: Container(
                              width: double.infinity,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/bike.png',
                                      height: 70.0,
                                      width: 80.0,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bike',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              fontFamily: 'Brand-semibold'),
                                        ),
                                        Text(
                                          tripDirectionDetails != null
                                              ? tripDirectionDetails
                                                  .distanceText
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(child: Container()),
                                    Text(
                                      (tripDirectionDetails != null
                                          ? '\$${(AssistantMethods.calculateFares(tripDirectionDetails)) / 2}'
                                          : ''),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'Brand-semibold',
                                        color: Colors.yellow[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          const Divider(
                            height: 2.0,
                            thickness: 2.0,
                          ),

                          const SizedBox(
                            height: 10.0,
                          ),

//Uber go

                          GestureDetector(
                            onTap: () {
                              displayToastMessage("searching Uber-Go...");
                              setState(() {
                                state = 'requesting';
                                carRideType = "uber-go";
                              });

                              displayRequestRideContainer();
                              availableDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;
                              searchNearestDriver();
                            },
                            child: Container(
                              width: double.infinity,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/ubergo.png',
                                      height: 70.0,
                                      width: 80.0,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Uber-Go',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              fontFamily: 'Brand-semibold'),
                                        ),
                                        Text(
                                          tripDirectionDetails != null
                                              ? tripDirectionDetails
                                                  .distanceText
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(child: Container()),
                                    Text(
                                      (tripDirectionDetails != null
                                          ? '\$${AssistantMethods.calculateFares(tripDirectionDetails)}'
                                          : ''),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'Brand-semibold',
                                        color: Colors.yellow[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          const Divider(
                            height: 2.0,
                            thickness: 2.0,
                          ),

                          const SizedBox(
                            height: 10.0,
                          ),

                          //uberx
                          GestureDetector(
                            onTap: () {
                              displayToastMessage("searching Uber-X...");
                              setState(() {
                                state = 'requesting';
                                carRideType = "uber-x";
                              });

                              displayRequestRideContainer();
                              availableDrivers =
                                  GeoFireAssistant.nearByAvailableDriversList;
                              searchNearestDriver();
                            },
                            child: Container(
                              width: double.infinity,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/uberx.png',
                                      height: 70.0,
                                      width: 80.0,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Uber-X',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              fontFamily: 'Brand-semibold'),
                                        ),
                                        Text(
                                          tripDirectionDetails != null
                                              ? tripDirectionDetails
                                                  .distanceText
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(child: Container()),
                                    Text(
                                      (tripDirectionDetails != null
                                          ? '\$${(AssistantMethods.calculateFares(tripDirectionDetails)) * 2}'
                                          : ''),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'Brand-semibold',
                                        color: Colors.yellow[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          const Divider(
                            height: 2.0,
                            thickness: 2.0,
                          ),

                          const SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.moneyBillAlt,
                                  size: 18.0,
                                  color: Colors.yellow[700],
                                ),
                                const SizedBox(
                                  width: 16.0,
                                ),
                                Text(
                                  'Cash',
                                  style: TextStyle(
                                    color: Colors.yellow[700],
                                  ),
                                ),
                                const SizedBox(
                                  width: 6.0,
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16.0,
                                  color: Colors.yellow[700],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                ),
              )),

          //request or cancel UI
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ColorizeAnimatedTextKit(
                        onTap: () {
                          print('Tap Event');
                        },
                        text: const ['Finding a Driver...'],
                        textStyle: const TextStyle(
                          fontSize: 55.0,
                          fontFamily: 'Signatra',
                        ),
                        colors: [
                          Colors.yellow[700],
                          Colors.yellow[700],
                          Colors.yellow[700],
                          Colors.yellow[700],
                          Colors.yellow[700],
                          Colors.yellow[700],
                        ],
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 22.0,
                    ),
                    Container(
                      height: 60.0,
                      width: 60.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26.0),
                        border: Border.all(width: 2.0, color: Colors.grey[300]),
                      ),
                      child: FlatButton(
                        onPressed: () {
                          cancelRiderequest();
                        },
                        child: const Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 22.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: const Text(
                        'Cancel Ride',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          //Display Assigned Driver Info
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 6.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              rideStatus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20.0, fontFamily: 'Brand-semibold'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 22.0,
                      ),
                      const Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      const SizedBox(
                        height: 22.0,
                      ),
                      Text(
                        carDetailsDriver,
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        driverName,
                        style: TextStyle(fontSize: 20.0),
                      ),
                      currentState == 'coming'
                          ? Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: RaisedButton(
                                shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(24.0),
                                ),
                                onPressed: () async {
                                  launch(('tel://${driverPhone}'));
                                },
                                color: Colors.yellow[700],
                                child: Padding(
                                  padding: EdgeInsets.all(17.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: const [
                                      Text(
                                        "Call Driver   ",
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      Icon(
                                        Icons.call,
                                        color: Colors.white,
                                        size: 26.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : currentState == 'going'
                              ? Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: lot.LottieBuilder.asset(
                                        'assets/images/carMoving.json'),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      child: Image.asset(
                                          'assets/images/driverArrived.png'),
                                    ),
                                  ),
                                ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;

    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: 'Please wait...',
            ));

    var details = await AssistantMethods.obtainPlaceDirectiondetails(
        pickUpLatLng, dropOffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        mapKey,
        PointLatLng(initialPos.latitude, initialPos.longitude),
        PointLatLng(finalPos.latitude, finalPos.longitude));

    pLineCoordinates.clear();

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            //So basically, we have done here that now we have a list of latitude and longitude which will allow us to draw a line on map.
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
//Now we have to create an instance of the fully line and we have to pass the required parameters to it in order to redraw the polyline.

      Polyline polyline = Polyline(
          color: Colors.yellow[700],
          polylineId: PolylineId('PolylineID'),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

//but before we add a new one we have to make it clear that polyline is empty when ever we add a polyline to polyline set that why I cleared the set and aslo the list
      polyLineSet.add(polyline);
    });

//showayt tazbeetat for animating the camera when drawing the line
    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpMArker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: 'my Location'),
        position: pickUpLatLng,
        markerId: MarkerId('pickUpId'));

    Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: 'DropOff Location'),
        position: dropOffLatLng,
        markerId: MarkerId('dropOffId'));

    setState(() {
      markersSet.add(pickUpMArker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpCircle = Circle(
        fillColor: Colors.blueAccent,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.yellowAccent,
        circleId: CircleId('pickUpId'));

    Circle dropOffCircle = Circle(
        fillColor: Colors.purple,
        center: dropOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.yellowAccent,
        circleId: CircleId('dropOffId'));

    setState(() {
      circlesSet.add(pickUpCircle);
      circlesSet.add(dropOffCircle);
    });
  }

  void initGeoFireListner() {
    GeoFireAssistant.nearByAvailableDriversList.clear();
    Geofire.initialize('availableDrivers');
    //comment

//haya el function el taht dee hata%od el user current latitude w longitude w brdo hata5od el radius el hadawr lhad fee..ya3nii el limit bat3ha hadawr lhad fein w ba3d keda hat listen ....ya3ni hat loop 3ala kol el drivers el fal 'availableDriver node' el fal firebase w tshoof el longitude el latitude bata3o..walahi lw gowa el radius hatrg3 el map bata3o w sa3tha ana ha3mlo add fal list w hakza
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 10)
        .listen((map) {
      print('mappp $map');

      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {

          //it simply means that whenever a driver becomes online
          case Geofire.onKeyEntered:
            NearByAvailableDriver nearByAvailableDriver =
                NearByAvailableDriver();
            nearByAvailableDriver.key = map[
                'key']; //the key here is the driver id which is the key for availableDrivers node in firebase
            nearByAvailableDriver.latitude = map['latitude'];
            nearByAvailableDriver.longitude = map['longitude'];

            //since there will be multiple drivers near by then I must add each nearbydriver to a list

            GeoFireAssistant.nearByAvailableDriversList
                .add(nearByAvailableDriver);

            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }

            break;

          //it simply means that whenever a driver becomes offline
          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          //simply whenever the driver moved will get the updated location
          case Geofire.onKeyMoved:
            NearByAvailableDriver nearByAvailableDriver =
                NearByAvailableDriver();
            nearByAvailableDriver.key = map['key'];
            nearByAvailableDriver.latitude = map['latitude'];
            nearByAvailableDriver.longitude = map['longitude'];

            GeoFireAssistant.updateDriverNearbyLocation(nearByAvailableDriver);
            updateAvailableDriversOnMap();
            break;

          //here we wil display all nearbyDrivers with car icons on Map
          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});

      //comment
    });
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();

    for (NearByAvailableDriver driver
        in GeoFireAssistant.nearByAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearByIcon,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }

    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));

      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/images/car_android.png')
          .then((value) {
        nearByIcon = value;
      });
    }
  }

  void searchNearestDriver() {
    if (availableDrivers.length == 0) {
      cancelRiderequest();
      resetApp();
      noDriverFound();
      return;
    }
    //since the list is already sorted i will take the first near by driver to recommend it to the rider. If i forgot and got confused remember that it is logically true if I thought about that the list is truly sorted. ma howa ana bamla fal list ezay kan kol ma bayla2ee nearby driver bayhoto fal list
    var driver = availableDrivers[0];

    driverRef
        .child(driver.key)
        .child("car_details")
        .child("type")
        .once()
        .then((DataSnapshot snap) async {
      if (await snap.value != null) {
        String carType = snap.value.toString();
        if (carType == carRideType) {
          notifyDriver(driver);
          availableDrivers.removeAt(0);
        } else {
          displayToastMessage(
              carRideType + "drivers not available. Try again.");
        }
      } else {
        displayToastMessage("No car found. Try again");
      }
    });
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailableDialog());
  }

  void notifyDriver(NearByAvailableDriver driver) {
    driverRef.child(driver.key).child('newRide').set(rideRequestRef.key);

    driverRef.child(driver.key).child("token").once().then(
      (DataSnapshot snap) {
        if (snap.value != null) {
          String token = snap.value.toString();
          AssistantMethods.sendNotificationToDriver(
              token, context, rideRequestRef.key);
        } else {
          return;
        }

        const oneSecondPassed = Duration(seconds: 1);
        var timer = Timer.periodic(oneSecondPassed, (timer) {
          if (state != "requesting") {
            driverRef.child(driver.key).child('newRide').set('cancelled');
            driverRef.child(driver.key).child('newRide').onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }

          driverRequestTimeOut = driverRequestTimeOut - 1;

          driverRef.child(driver.key).child('newRide').onValue.listen((event) {
            if (event.snapshot.value.toString() == "accepted") {
              driverRef.child(driver.key).child('newRide').onDisconnect();
              driverRequestTimeOut = 40;
              timer.cancel();
            }
          });
          if (driverRequestTimeOut == 0) {
            driverRef.child(driver.key).child('newRide').set('timeout');
            driverRef.child(driver.key).child('newRide').onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();

            searchNearestDriver();
          }
        });
      },
    );
  }
}
