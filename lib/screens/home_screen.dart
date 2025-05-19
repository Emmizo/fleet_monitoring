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
import 'package:flutter_slidable/flutter_slidable.dart';

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
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: FlutterMap(
                                        mapController: _mapController,
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
                                          minZoom: 3,
                                          maxZoom: 18,
                                          interactionOptions:
                                              const InteractionOptions(
                                                flags: InteractiveFlag.all,
                                              ),
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
                                                        car.longitude
                                                            .toString(),
                                                      ) ??
                                                      0.0;
                                                  Color borderColor;
                                                  if (car.status == 'Moving') {
                                                    borderColor = Colors.green;
                                                  } else {
                                                    borderColor = Colors.red;
                                                  }
                                                  Color iconColor =
                                                      car.status == 'Moving'
                                                          ? kPrimaryColor
                                                          : Colors.grey;
                                                  return Marker(
                                                    width: 24,
                                                    height: 24,
                                                    point: LatLng(lat, lng),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        if (lat == 0.0 &&
                                                            lng == 0.0) {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => AlertDialog(
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
                                                        String distText = '';
                                                        if (_userLocation !=
                                                            null) {
                                                          final Distance
                                                          distance = Distance();
                                                          dist = distance.as(
                                                            LengthUnit.Meter,
                                                            _userLocation!,
                                                            LatLng(lat, lng),
                                                          );
                                                          if (dist >= 1000) {
                                                            distText =
                                                                '\nDistance: ${(dist / 1000).toStringAsFixed(2)} km';
                                                          } else {
                                                            distText =
                                                                '\nDistance: ${dist.toStringAsFixed(0)} m';
                                                          }
                                                        } else {
                                                          distText =
                                                              '\nDistance: unknown (location not available)';
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
                                                          shape:
                                                              BoxShape.circle,
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
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        padding: EdgeInsets.all(
                                                          2,
                                                        ),
                                                        child: Icon(
                                                          car.status == 'Moving'
                                                              ? Icons
                                                                  .directions_car
                                                              : Icons
                                                                  .local_parking,
                                                          color: iconColor,
                                                          size: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Column(
                                        children: [
                                          FloatingActionButton(
                                            mini: true,
                                            heroTag: 'zoomIn',
                                            backgroundColor: kPrimaryColor,
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              _mapController.move(
                                                _mapController.center,
                                                _mapController.zoom + 1,
                                              );
                                            },
                                          ),
                                          SizedBox(height: 8),
                                          FloatingActionButton(
                                            mini: true,
                                            heroTag: 'zoomOut',
                                            backgroundColor: kPrimaryColor,
                                            child: Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              _mapController.move(
                                                _mapController.center,
                                                _mapController.zoom - 1,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                  return Slidable(
                                    key: ValueKey(car.id),
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => CarDetailsScreen(
                                                      car: car,
                                                    ),
                                              ),
                                            );
                                          },
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          icon: Icons.remove_red_eye,
                                          label: 'View',
                                        ),
                                        SlidableAction(
                                          onPressed: (context) async {
                                            final carProvider =
                                                Provider.of<CarProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            final confirm = await showDialog<
                                              bool
                                            >(
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
                                              await carProvider.deleteCar(
                                                car.id,
                                              );
                                            }
                                          },
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                        ),
                                      ],
                                    ),
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
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: kPrimaryColor, size: 32),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or ID',
          prefixIcon: Icon(Icons.search, color: kPrimaryColor),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      carProvider.setSearchQuery('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimaryColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: TextStyle(fontSize: 18),
        onChanged: (value) {
          carProvider.setSearchQuery(value);
        },
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
