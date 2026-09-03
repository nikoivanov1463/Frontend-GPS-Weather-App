import "dart:async";
import "dart:collection";

import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";

import "package:tracking_app/helper_methods/map/homepage_markers_operations.dart";

class MapPage extends StatefulWidget {
  final MarkerMethods markerDio = MarkerMethods();

  MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;

  StreamSubscription<Position>? listenForPositionUpdates;

  HashMap<MarkerId, Marker> markers = HashMap();

  static const String blueMarker = "Item needs to be transported";
  static const String greenMarker = "Finished operation";

  late LatLng userCoordinates;

  bool permissionsAreGranted = false;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loading = true;
    checkLocation();
  }

  void getCurrentLocation() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    Position currentPosition =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    if (mounted) {
      setState(() {
        userCoordinates =
            LatLng(currentPosition.latitude, currentPosition.longitude);
        loading = false;
      });
    }
  }

  void checkLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    permissionsAreGranted = true;

    //get user current location
    getCurrentLocation();
    //fetch user pins
    plotResults();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    const locationSettings =
        LocationSettings(accuracy: LocationAccuracy.bestForNavigation);

    if (listenForPositionUpdates != null) {
      listenForPositionUpdates!.cancel();
    }

    listenForPositionUpdates =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        userCoordinates = LatLng(
            position.latitude.toDouble(), position.longitude.toDouble());
      } else {
        throw Exception("There was no coordinates");
      }
    });
  }

  void plotResults() async {
    dynamic result = await widget.markerDio.fetchUserPins();

    for (var data in result) {
      MarkerId markerId = MarkerId(data["markerID"]);
      LatLng latLngCords = LatLng(data["lat"], data["lng"]);

      Marker marker = Marker(
        markerId: markerId,
        draggable: false,
        position: latLngCords,
        infoWindow: InfoWindow(
          title: data["title"],
          snippet:
              "${latLngCords.latitude.toStringAsFixed(5)}, ${latLngCords.longitude.toStringAsFixed(5)}",
        ),
        onTap: () {
          deleteSelectedMarkers(data["title"], latLngCords, markerId);
        },
        icon: data["type"] == "In Progress"
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      if (mounted) {
        setState(() {
          markers[markerId] = marker;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(children: [
      Expanded(
          child: permissionsAreGranted && !loading
              ? SizedBox.expand(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: onMapCreated,
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                        initialCameraPosition: CameraPosition(
                          target: userCoordinates,
                          zoom: 15.0,
                        ),
                        onLongPress: (latLong) {
                          addMarkerLongPress(latLong, context);
                        },
                        markers: Set<Marker>.of(markers.values),
                      )
                    ],
                  ),
                )
              : Center(
                  child: Card(
                    shadowColor: const Color.fromRGBO(255, 255, 255, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: const Color.fromRGBO(255, 255, 255, 0),
                    child: const Padding(
                      padding: EdgeInsets.all(35.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amberAccent,
                            size: 50,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Location Permissions Not Granted",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Unable to load the map as location permissions are required. Please enable location permissions in your device settings.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
    ]);
  }

  @override
  void dispose() {
    if (listenForPositionUpdates != null) {
      listenForPositionUpdates?.cancel();
    }
    mapController?.dispose();
    super.dispose();
  }

  void addMarkerLongPress(LatLng latLong, BuildContext context) async {
    final markerDialog = AlertDialog(
      title: const Text("Choose marker:"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: const Text(blueMarker),
                  onTap: () {
                    Navigator.of(context).pop();
                    selectMarkerTypeDialog("blue", latLong, context);
                  },
                  leading: const Icon(Icons.square_rounded, color: Colors.blue),
                )),
            Card(
              child: ListTile(
                  title: const Text(greenMarker),
                  onTap: () {
                    Navigator.of(context).pop();
                    selectMarkerTypeDialog("green", latLong, context);
                  },
                  leading:
                      const Icon(Icons.square_rounded, color: Colors.green)),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.blue))),
      ],
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => markerDialog,
    );
  }

  List<String> typesOfWasteMarker = [
    "Recyclable waste",
    "Solid waste",
    "Household waste",
    "Industrial waste",
    "Green waste",
    "Medical waste",
    "Agricultural waste",
    "Electronic waste",
    "Demolition waste",
    "Commercial waste"
  ];

  void selectMarkerTypeDialog(
      String typeOfMarker, LatLng latLong, BuildContext context) async {
    final typeDialog = AlertDialog(
        title: const Text("Choose type of product:"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < typesOfWasteMarker.length; i++)
                if (typeOfMarker == "blue") ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      title: Text(typesOfWasteMarker[i]),
                      onTap: () {
                        addMarkerSave(
                            latLong,
                            typesOfWasteMarker[i],
                            BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure),
                            "blue");
                      },
                      leading:
                          const Icon(Icons.square_rounded, color: Colors.blue),
                    ),
                  ),
                ] else ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      title: Text(typesOfWasteMarker[i]),
                      onTap: () {
                        addMarkerSave(
                            latLong,
                            typesOfWasteMarker[i],
                            BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen),
                            "green");
                      },
                      leading:
                          const Icon(Icons.square_rounded, color: Colors.green),
                    ),
                  ),
                ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.blue))),
        ]);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => typeDialog,
    );
  }

  Future<void> addMarkerSave(
      LatLng cords, String title, BitmapDescriptor icon, String color) async {
    final MarkerId markerId = MarkerId(DateTime.now().toString());
    Marker marker = Marker(
      markerId: markerId,
      draggable: false,
      position: cords,
      infoWindow: InfoWindow(
        title: title,
        snippet:
            "${cords.latitude.toStringAsFixed(5)}, ${cords.longitude.toStringAsFixed(5)}",
      ),
      onTap: () {
        deleteSelectedMarkers(title, cords, markerId);
      },
      icon: icon,
    );

    if (mounted) {
      setState(() {
        markers[markerId] = marker;
      });
    }

    await widget.markerDio.saveMarker(
            marker.markerId,
            cords.latitude,
            cords.longitude,
            color,
            title)
        .then((request) => {});

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void deleteSelectedMarkers(String title, LatLng cords, MarkerId markerId) {
    final double lat = cords.latitude;
    final double long = cords.longitude;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Coordinates: "),
            Text("${lat.toStringAsFixed(5)}, ${long.toStringAsFixed(5)}")
          ],
        ),
        content: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                child: const Text('Delete'),
                onPressed: () async {
                  await widget.markerDio.deleteSelectedMarker(markerId.value)
                      .then((request) {
                    if (mounted) {
                      setState(() {
                        markers.remove(markerId);
                      });
                    }
                  });
                  if(context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              ElevatedButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
