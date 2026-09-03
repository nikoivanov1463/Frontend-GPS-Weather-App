import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Location _location = Location();
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  bool _isSearching = false;

  final MapController _mapController = MapController();
  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    bool locationServiceEnabled = await _location.serviceEnabled();

    if (!locationServiceEnabled) {
      locationServiceEnabled = await _location.requestService();
      if (!locationServiceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<void> _initializeLocation() async {
    if (!await _checkLocationPermission()) return;

    if (!mounted) return;

    _location.onLocationChanged.listen((LocationData locationData) {
      if (!mounted) return;

      final lat = locationData.latitude;
      final lng = locationData.longitude;

      if (lat.isNaN || lng.isNaN) {
        return;
      }

      setState(() {
        _currentLocation = LatLng(
          lat,
          lng,
        );
      });
    });
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) {
      return;
    }

    if (_currentLocation!.latitude.isNaN ||
        _currentLocation!.longitude.isNaN ||
        _currentLocation!.latitude.isInfinite ||
        _currentLocation!.longitude.isInfinite) {
      print('⚠️ Current location has invalid coordinates: $_currentLocation');
      return;
    }

    final url = Uri.parse(
      "http://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isEmpty) {
        displayErrorMessage("Route not found. Please try another search.");
      }

      final geometry = data['routes'][0]['geometry'];

      _decodePolyline(geometry);
    } else {
      displayErrorMessage("Failed to fetch route. Try again later.");
    }
  }

  Future<void> _decodePolyline(String geometry) async {
    final polylines = decodePolyline(geometry);

    setState(() {
      _route = polylines
          .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
          .toList();
    });
  }

  Future<List<dynamic>> _fetchCoordinatesPoint(String location) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$location&addressdetails=1&format=jsonv2&limit=10",
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'com.example.tracking_app',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isEmpty) {
        displayErrorMessage("Location not found. Please try another search.");
        return [];
      }

      if (data is List) {
        final filtered = data.where((item) {
          if (item is! Map<String, dynamic>) return false;

          final type = item['type']?.toString() ?? '';
          final classType = item['category']?.toString() ?? '';
          final address = item['address'] as Map<String, dynamic>?;

          final validTypes = ['city', 'town', 'village', 'hamlet'];
          final isValidType = validTypes.contains(type);

          final hasCity = address?['city'] != null;
          final hasTown = address?['town'] != null;
          final hasVillage = address?['village'] != null;
          final hasHamlet = address?['hamlet'] != null;

          final isBoundary = classType == 'boundary' ||
              type == 'administrative' ||
              type == 'state' ||
              type == 'country';

          return (isValidType ||
                  hasCity ||
                  hasTown ||
                  hasVillage ||
                  hasHamlet) &&
              !isBoundary;
        }).map((item) {
          final address = item['address'] as Map<String, dynamic>? ?? {};

          return {
            'name': item['name']?.toString() ?? 'Unknown',
            'state': address['state']?.toString() ?? '',
            'country': address['country']?.toString() ?? '',
            'category': item['category']?.toString() ?? '',
            'type': item['type']?.toString() ?? '',
            'lat': double.parse(item['lat']?.toString() ?? '0'),
            'lon': double.parse(item['lon']?.toString() ?? '0'),
          };
        }).toList();

        return filtered;
      }
    }

    return [];
  }

  Future<void> _getUserCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is not available.')),
      );
    }
  }

  void displayErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _capitalizeFirstLetterString(String value) {
    return value.isNotEmpty ? value[0].toUpperCase() + value.substring(1) : '';
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Column(
      children: [
        Expanded(
          child: Stack(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(0, 0),
                  initialZoom: 2,
                  minZoom: 0,
                  maxZoom: 100,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: "com.example.tracking_app",
                  ),
                  const CurrentLocationLayer(
                    style: LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        color: Colors.blue,
                        child: Icon(Icons.location_pin, color: Colors.white),
                      ),
                      markerSize: Size(36, 36),
                      markerDirection: MarkerDirection.top,
                    ),
                  ),
                  if (_destination != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destination!,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.blue,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  if (_currentLocation != null &&
                      _destination != null &&
                      _route.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route,
                          strokeWidth: 3,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _getUserCurrentLocation,
                  backgroundColor: Colors.blue,
                  tooltip: 'Current Location',
                  child: const Icon(
                    Icons.my_location,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchAnchor(
                    searchController: _searchController,
                    isFullScreen: false,
                    viewConstraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    viewElevation: 4,
                    viewShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    viewBackgroundColor: Colors.white,
                    builder:
                        (BuildContext context, SearchController controller) {
                      String controllerText = controller.text.trim();

                      return SearchBar(
                        controller: controller,
                        onSubmitted: (changedValue) {
                          if (changedValue.isNotEmpty) {
                            controller.openView();
                          }
                        },
                        onChanged: (newValue) {
                          if (mounted) {
                            if (newValue.isNotEmpty) {
                              setState(() {
                                _isSearching = true;
                              });
                            } else {
                              setState(() {
                                _isSearching = false;
                              });
                            }
                          }
                        },
                        hintText: "Enter destination",
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        trailing: [
                          if (_isSearching)
                            IconButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _route = [];
                                    _destination = null;
                                    _isSearching = false;
                                  });
                                }
                                controller.clear();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.blue,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              iconSize: 32,
                              onPressed: () {
                                if (controllerText.isNotEmpty) {
                                  controller.openView();
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    suggestionsBuilder: (BuildContext context,
                        SearchController controller) async {
                      final searchQuery = controller.text.trim();

                      if (searchQuery.isEmpty) {
                        return const [
                          ListTile(title: Text('Type to search...'))
                        ];
                      }

                      try {
                        final results =
                            await _fetchCoordinatesPoint(searchQuery);

                        if (results.isEmpty) {
                          return [
                            const ListTile(title: Text('No results found'))
                          ];
                        }

                        return results.map((place) {
                          String displayName = place['name'];
                          String state = place['state'];
                          String country = place['country'];
                          String placeCategory = place['category'];
                          String placeType = place['type'];
                          double lat = place['lat'];
                          double lon = place['lon'];

                          return ListTile(
                            title: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$displayName $state $country",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            subtitle: Text(
                              "${_capitalizeFirstLetterString(placeCategory)} ${_capitalizeFirstLetterString(placeType)}",
                            ),
                            leading: const Icon(Icons.house),
                            iconColor: Colors.blue,
                            onTap: () async {
                              controller.closeView("$displayName, $state");

                              if (mounted) {
                                setState(() {
                                  _destination = LatLng(lat, lon);
                                  _mapController.move(_destination!, 10);
                                });

                                _fetchRoute();
                              }
                            },
                          );
                        }).toList();
                      } catch (e) {
                        return [
                           const ListTile(
                              title:
                                  Text('Error when fetching. Please try again'))
                        ];
                      }
                    }),
              )
            ],
          ),
        ),
      ],
    );
  }
}
