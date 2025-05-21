import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nitd_code/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:nitd_code/pages/alumni_page/alumni_detail_page.dart';
import 'package:nitd_code/ui/pallete.dart';

class AlumniPage extends StatefulWidget {
  const AlumniPage({super.key});

  @override
  _AlumniPageState createState() => _AlumniPageState();
}

class _AlumniPageState extends State<AlumniPage> {
  late MapController _mapController;
  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> allAlumni = [];
  Map<LatLng, CityAlumniData> cityAlumniMap = {};
  LatLng? _hoveredCityLocation;
  String selectedCompany = 'All';
  String selectedYear = 'All';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAlumniData();
  }

  Future<void> _fetchAlumniData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final List<UserModel> tempAlumniList = [];

      for (var doc in snapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc.data());
          tempAlumniList.add(user);
        } catch (e) {
          print("Error processing alumni ${doc.id}: $e");
        }
      }

      setState(() {
        allAlumni = tempAlumniList;
      });

      _updateCityAlumniMap();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load alumni data: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCityAlumniMap() async {
    final Map<LatLng, CityAlumniData> tempMap = {};

    final List<UserModel> filteredAlumni = allAlumni.where((u) {
      final matchCompany = selectedCompany == 'All' ||
          u.company?.toLowerCase() == selectedCompany.toLowerCase();
      final matchYear =
          selectedYear == 'All' || u.endYear.toString() == selectedYear;
      return matchCompany && matchYear;
    }).toList();

    for (var user in filteredAlumni) {
      try {
        final coordinates = await _getCoordinates(user.location);
        final latLng = LatLng(coordinates.latitude, coordinates.longitude);

        if (tempMap.containsKey(latLng)) {
          tempMap[latLng]!.alumni.add(user);
        } else {
          tempMap[latLng] = CityAlumniData(
            location: user.location,
            alumni: [user],
            coordinates: latLng,
          );
        }
      } catch (e) {
        print("Error geocoding for ${user.name}: $e");
      }
    }

    setState(() {
      cityAlumniMap = tempMap;
      _isLoading = false;
    });
  }

  Future<Location> _getCoordinates(String location) async {
    final apiKey = dotenv.env['GEOCODING_API_KEY']!;

    try {
      if (location.isEmpty) {
        return Location(
            latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
      }

      final encodedLocation = Uri.encodeComponent(location);
      final response = await http.get(
        Uri.parse(
            'https://geocode.maps.co/search?q=$encodedLocation&api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final firstResult = results.first;
          return Location(
            latitude: double.parse(firstResult['lat']),
            longitude: double.parse(firstResult['lon']),
            timestamp: DateTime.now(),
          );
        }
      }

      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) return locations.first;

      final knownCities = {
        'Delhi': Location(
            latitude: 28.7041, longitude: 77.1025, timestamp: DateTime.now()),
        'Mumbai': Location(
            latitude: 19.0760, longitude: 72.8777, timestamp: DateTime.now()),
        'Bangalore': Location(
            latitude: 12.9716, longitude: 77.5946, timestamp: DateTime.now()),
      };

      final cityKey = knownCities.keys.firstWhere(
        (key) => location.toLowerCase().contains(key.toLowerCase()),
        orElse: () => '',
      );

      return cityKey.isNotEmpty
          ? knownCities[cityKey]!
          : Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
    } catch (e) {
      print("Error getting coordinates for $location: $e");
      return Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = [
      'All',
      ...{
        for (var user in allAlumni)
          if (user.company != null && user.company!.trim().isNotEmpty)
            user.company!
      }
    ];

    // final years = [
    //   'All',
    //   ...{for (var user in allAlumni) user.endYear.toString()}.toList()..sort()
    // ];
    final years = [
      'All',
      ...{
        for (var user in allAlumni)
          if (user.endYear.toString().trim().isNotEmpty) user.endYear.toString()
      }.toList()
        ..sort()
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Pallete.gradient1,
              Pallete.gradient2,
              Pallete.gradient3,
            ]),
          ),
        ),
        title: const Text(
          'Alumni Map',
          style: TextStyle(
            fontSize: 22, // Increase font size for better readability
            fontWeight: FontWeight.bold, // Make the title bold
            color: Colors.white, // Change text color to white
          ),
        ),
        elevation: 4.0, // Add shadow to the app bar for depth
        centerTitle: true, // Center the title
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Container(
                  color: Pallete.backgroundColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Card(
                          color: Pallete.backgroundColor,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedCompany,
                                    dropdownColor: Pallete.backgroundColor,
                                    decoration: InputDecoration(
                                      labelText: 'Company',
                                      labelStyle: TextStyle(
                                          color: Pallete.whiteColor
                                              .withOpacity(0.8)),
                                      prefixIcon: const Icon(Icons.business,
                                          color: Pallete.whiteColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Pallete.whiteColor
                                                .withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Pallete.whiteColor
                                                .withOpacity(0.3)),
                                      ),
                                      filled: true,
                                      fillColor: Pallete.backgroundColor
                                          .withOpacity(0.5),
                                    ),
                                    style: const TextStyle(
                                        color: Pallete.whiteColor),
                                    iconEnabledColor: Pallete.whiteColor,
                                    items: companies
                                        .map((company) => DropdownMenuItem(
                                              value: company,
                                              child: Text(company,
                                                  style: const TextStyle(
                                                      color:
                                                          Pallete.whiteColor)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCompany = value!;
                                        _isLoading = true;
                                      });
                                      _updateCityAlumniMap();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedYear,
                                    dropdownColor: Pallete.backgroundColor,
                                    decoration: InputDecoration(
                                      labelText: 'Year',
                                      labelStyle: TextStyle(
                                          color: Pallete.whiteColor
                                              .withOpacity(0.8)),
                                      prefixIcon: const Icon(
                                          Icons.calendar_today,
                                          color: Pallete.whiteColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Pallete.whiteColor
                                                .withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Pallete.whiteColor
                                                .withOpacity(0.3)),
                                      ),
                                      filled: true,
                                      fillColor: Pallete.backgroundColor
                                          .withOpacity(0.5),
                                    ),
                                    style: const TextStyle(
                                        color: Pallete.whiteColor),
                                    iconEnabledColor: Pallete.whiteColor,
                                    items: years
                                        .map((year) => DropdownMenuItem(
                                              value: year,
                                              child: Text(year,
                                                  style: const TextStyle(
                                                      color:
                                                          Pallete.whiteColor)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedYear = value!;
                                        _isLoading = true;
                                      });
                                      _updateCityAlumniMap();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // ],
                            //   ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(20.5937, 78.9629),
                                initialZoom: 5.0,
                                onPointerHover: (event, latLng) {
                                  final nearestCity = _findNearestCity(latLng);
                                  setState(() {
                                    _hoveredCityLocation =
                                        nearestCity?.coordinates;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                                  subdomains: const ['a', 'b', 'c'],
                                  retinaMode: true,
                                  userAgentPackageName:
                                      'com.example.alumni_map',
                                  tileProvider: NetworkTileProvider(),
                                ),
                                CircleLayer(
                                  circles: cityAlumniMap.entries.map((entry) {
                                    final data = entry.value;
                                    return CircleMarker(
                                      point: entry.key,
                                      color: Pallete.gradient2
                                          .withOpacity(0.4), // Inner glow
                                      borderColor: Pallete.gradient1
                                          .withOpacity(0.6), // Stronger border
                                      borderStrokeWidth: 2.0,
                                      radius:
                                          _calculateRadius(data.alumni.length),
                                      useRadiusInMeter: false,
                                    );
                                  }).toList(),
                                ),
                                if (_hoveredCityLocation != null &&
                                    cityAlumniMap
                                        .containsKey(_hoveredCityLocation))
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _hoveredCityLocation!,
                                        width: 100,
                                        height: 50,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AlumniLocationDetailsPage(
                                                  alumni: cityAlumniMap[
                                                          _hoveredCityLocation]!
                                                      .alumni,
                                                  location: cityAlumniMap[
                                                          _hoveredCityLocation]!
                                                      .location,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 4),
                                              ],
                                            ),
                                            child: Text(
                                              '${cityAlumniMap[_hoveredCityLocation]!.alumni.length} alumni\n${cityAlumniMap[_hoveredCityLocation]!.location}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            // Zoom Controls
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Zoom In Button
                                  _buildGradientButton(
                                    icon: Icons.zoom_in,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Pallete.gradient1,
                                        Pallete.gradient2
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () => _mapController.move(
                                      _mapController.camera.center,
                                      _mapController.camera.zoom + 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Zoom Out Button
                                  _buildGradientButton(
                                    icon: Icons.zoom_out,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Pallete.gradient2,
                                        Pallete.gradient3
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () => _mapController.move(
                                      _mapController.camera.center,
                                      _mapController.camera.zoom - 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  CityAlumniData? _findNearestCity(LatLng position) {
    CityAlumniData? nearestCity;
    double minDistance = double.infinity;

    for (final entry in cityAlumniMap.entries) {
      final distance =
          const Distance().as(LengthUnit.Meter, position, entry.key);
      if (distance < minDistance && distance < 50000) {
        minDistance = distance;
        nearestCity = entry.value;
      }
    }

    return nearestCity;
  }

  double _calculateRadius(int alumniCount) {
    return 8.0 + (alumniCount * 2.0);
  }

  Widget _buildGradientButton({
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: gradient.colors.first.withOpacity(0.4),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Pallete.whiteColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Pallete.whiteColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class CityAlumniData {
  final String location;
  final List<UserModel> alumni;
  final LatLng coordinates;

  CityAlumniData({
    required this.location,
    required this.alumni,
    required this.coordinates,
  });
}
