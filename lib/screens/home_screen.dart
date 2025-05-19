import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../models/car.dart';
import 'car_details_screen.dart';
import 'add_edit_car_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

const Color kPrimaryColor = Color(0xFF164654);
const Color kBackgroundColor = Color(0xFFFFFFFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _initialPosition = LatLng(-1.94995, 30.05885);
  LatLng? _userLocation;
  bool _blink = true;
  Timer? _blinkTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _startBlinking();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startBlinking() {
    _blinkTimer = Timer.periodic(Duration(milliseconds: 700), (timer) {
      setState(() {
        _blink = !_blink;
      });
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      carProvider.fetchCars();
    });
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      // Could not get location
    }
  }

  double? _distanceToCar(LatLng? user, Car car) {
    if (user == null) return null;
    double lat = double.tryParse(car.latitude.toString()) ?? 0.0;
    double lng = double.tryParse(car.longitude.toString()) ?? 0.0;
    final carLoc = LatLng(lat, lng);
    final Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, user, carLoc);
  }

  @override
  Widget build(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    final cars = carProvider.cars;
    final error = carProvider.errorMessage;

    // Calculate bounds for all cars
    LatLngBounds? bounds;
    if (cars.isNotEmpty) {
      final points =
          cars
              .map(
                (car) => LatLng(
                  double.tryParse(car.latitude.toString()) ?? 0.0,
                  double.tryParse(car.longitude.toString()) ?? 0.0,
                ),
              )
              .toList();
      bounds = LatLngBounds.fromPoints(points);
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Fleet Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSearchBar(context),
              ),
              SizedBox(height: 8),
              Expanded(
                child:
                    cars.isEmpty && error == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 64,
                                color: kPrimaryColor.withOpacity(0.2),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No cars to display',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: kPrimaryColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () async {
                            await carProvider.fetchCars();
                          },
                          child: ListView(
                            children: [
                              SizedBox(
                                height: 250,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter:
                                          bounds != null
                                              ? bounds.center
                                              : _initialPosition,
                                      initialZoom: 14,
                                      initialCameraFit:
                                          bounds != null
                                              ? CameraFit.bounds(
                                                bounds: bounds,
                                                padding: EdgeInsets.all(20),
                                              )
                                              : null,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        subdomains: ['a', 'b', 'c'],
                                        userAgentPackageName:
                                            'com.example.fleetMonitoringApp',
                                      ),
                                      MarkerLayer(
                                        markers:
                                            cars.map((car) {
                                              double lat =
                                                  double.tryParse(
                                                    car.latitude.toString(),
                                                  ) ??
                                                  0.0;
                                              double lng =
                                                  double.tryParse(
                                                    car.longitude.toString(),
                                                  ) ??
                                                  0.0;
                                              Color borderColor;
                                              if (car.status == 'Moving') {
                                                borderColor =
                                                    _blink
                                                        ? Colors.green
                                                        : Colors.transparent;
                                              } else {
                                                borderColor =
                                                    _blink
                                                        ? Colors.red
                                                        : Colors.transparent;
                                              }
                                              Color iconColor =
                                                  car.status == 'Moving'
                                                      ? kPrimaryColor
                                                      : Colors.grey;
                                              return Marker(
                                                width: 44,
                                                height: 44,
                                                point: LatLng(lat, lng),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (lat == 0.0 &&
                                                        lng == 0.0) {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (_) => AlertDialog(
                                                              title: Text(
                                                                'Invalid Location',
                                                              ),
                                                              content: Text(
                                                                'This car does not have a valid location.',
                                                              ),
                                                            ),
                                                      );
                                                      return;
                                                    }
                                                    double? dist;
                                                    if (_userLocation != null) {
                                                      final Distance distance =
                                                          Distance();
                                                      dist = distance.as(
                                                        LengthUnit.Meter,
                                                        _userLocation!,
                                                        LatLng(lat, lng),
                                                      );
                                                    }
                                                    String distText = '';
                                                    if (dist != null) {
                                                      if (dist >= 1000) {
                                                        distText =
                                                            '\nDistance: ${(dist / 1000).toStringAsFixed(2)} km';
                                                      } else {
                                                        distText =
                                                            '\nDistance: ${dist.toStringAsFixed(0)} m';
                                                      }
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${car.name} (${car.status})\nSpeed: ${car.speed} km/h\nLocation: (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})$distText',
                                                        ),
                                                        duration: Duration(
                                                          seconds: 4,
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: borderColor,
                                                        width: 4,
                                                      ),
                                                      color: Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: kPrimaryColor
                                                              .withAlpha(
                                                                (0.08 * 255)
                                                                    .toInt(),
                                                              ),
                                                          blurRadius: 6,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    padding: EdgeInsets.all(2),
                                                    child: Icon(
                                                      car.status == 'Moving'
                                                          ? Icons.directions_car
                                                          : Icons.local_parking,
                                                      color: iconColor,
                                                      size: 36,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: cars.length,
                                itemBuilder: (context, index) {
                                  final car = cars[index];
                                  final dist = _distanceToCar(
                                    _userLocation,
                                    car,
                                  );
                                  return Dismissible(
                                    key: ValueKey(car.id),
                                    background: Container(
                                      color: kPrimaryColor.withAlpha(
                                        (0.08 * 255).toInt(),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(left: 24),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'View',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 24),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction ==
                                          DismissDirection.startToEnd) {
                                        // View details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    CarDetailsScreen(car: car),
                                          ),
                                        );
                                        return false;
                                      } else if (direction ==
                                          DismissDirection.endToStart) {
                                        // Delete
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text('Delete Car'),
                                                content: Text(
                                                  'Are you sure you want to delete this car?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (confirm == true) {
                                          await Provider.of<CarProvider>(
                                            context,
                                            listen: false,
                                          ).deleteCar(car.id);
                                          return true;
                                        }
                                        return false;
                                      }
                                      return false;
                                    },
                                    child: Card(
                                      color: kBackgroundColor,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(18),
                                                bottomLeft: Radius.circular(18),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    car.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: kPrimaryColor,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Text(
                                                    'Status: ${car.status} | Speed: ${car.speed} km/h' +
                                                        (dist != null
                                                            ? ' | ${dist.toStringAsFixed(2)} km away'
                                                            : ''),
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16.0,
                                            ),
                                            child: Material(
                                              color: kPrimaryColor.withAlpha(
                                                (0.08 * 255).toInt(),
                                              ),
                                              shape: CircleBorder(),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: kPrimaryColor,
                                                  size: 22,
                                                ),
                                                tooltip: 'Edit',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              AddEditCarScreen(
                                                                car: car,
                                                              ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
          Positioned(top: 100, right: 16, child: _buildFilterButton(context)),
          if (error != null)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: _buildErrorBanner(error),
            ),
          Positioned(bottom: 24, left: 16, child: _buildLegend(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditCarScreen()),
          );
        },
        child: Icon(Icons.add, color: kPrimaryColor, size: 32),
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or ID',
          prefixIcon: Icon(Icons.search, color: kPrimaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: carProvider.setSearchQuery,
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.filter_list, color: kPrimaryColor, size: 32),
      onSelected: carProvider.setStatusFilter,
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'All', child: Text('All')),
            PopupMenuItem(value: 'Moving', child: Text('Moving')),
            PopupMenuItem(value: 'Parked', child: Text('Parked')),
          ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Material(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(error, style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    final selected = carProvider.statusFilter;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => carProvider.setStatusFilter('All'),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: selected == 'All' ? kPrimaryColor : Colors.grey,
                    size: 28,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'All',
                    style: TextStyle(
                      fontSize: 16,
                      color: selected == 'All' ? kPrimaryColor : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => carProvider.setStatusFilter('Moving'),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: selected == 'Moving' ? kPrimaryColor : Colors.grey,
                    size: 28,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Moving',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          selected == 'Moving' ? kPrimaryColor : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => carProvider.setStatusFilter('Parked'),
              child: Row(
                children: [
                  Icon(
                    Icons.local_parking,
                    color: selected == 'Parked' ? kPrimaryColor : Colors.grey,
                    size: 28,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Parked',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          selected == 'Parked' ? kPrimaryColor : Colors.black,
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
}
