import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';
import 'add_edit_car_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latLng2;

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  latLng2.LatLng? _userLocation;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _getUserLocationAndDistance();
  }

  Future<void> _getUserLocationAndDistance() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = latLng2.LatLng(pos.latitude, pos.longitude);
        _distance = _calculateDistance(_userLocation!, widget.car);
      });
    } catch (e) {
      // Could not get location
    }
  }

  double? _calculateDistance(latLng2.LatLng user, Car car) {
    double lat = double.tryParse(car.latitude.toString()) ?? 0.0;
    double lng = double.tryParse(car.longitude.toString()) ?? 0.0;
    final carLoc = latLng2.LatLng(lat, lng);
    final latLng2.Distance distance = latLng2.Distance();
    return distance.as(latLng2.LengthUnit.Meter, user, carLoc);
  }

  @override
  Widget build(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    final car = widget.car;
    final isTracking = carProvider.trackedCar?.id == car.id;
    double lat = double.tryParse(car.latitude.toString()) ?? 0.0;
    double lng = double.tryParse(car.longitude.toString()) ?? 0.0;
    String distanceText = '';
    if (_distance != null) {
      if (_distance! >= 1000) {
        distanceText = (_distance! / 1000).toStringAsFixed(2) + ' km from you';
      } else {
        distanceText = _distance!.toStringAsFixed(0) + ' m from you';
      }
    }
    final bool invalidLocation =
        car.latitude == null ||
        car.longitude == null ||
        lat == 0.0 && lng == 0.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(car.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditCarScreen(car: car)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
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
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await carProvider.deleteCar(car.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            invalidLocation
                ? Center(
                  child: Text(
                    'This car does not have a valid location.',
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (distanceText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.place, color: Colors.blueGrey),
                            SizedBox(width: 8),
                            Text(
                              distanceText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          car.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ActionChip(
                          label: Text(
                            car.status,
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor:
                              car.status == 'Moving'
                                  ? Colors.green
                                  : Colors.grey,
                          onPressed: () async {
                            final newStatus =
                                car.status == 'Moving' ? 'Parked' : 'Moving';
                            final updatedCar = Car(
                              id: car.id,
                              name: car.name,
                              latitude: car.latitude,
                              longitude: car.longitude,
                              speed: car.speed,
                              status: newStatus,
                            );
                            await Provider.of<CarProvider>(
                              context,
                              listen: false,
                            ).updateCar(updatedCar);
                            Navigator.pop(
                              context,
                            ); // Optionally go back or show a snackbar
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Speed: ${car.speed} km/h',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Location: (' +
                          (lat.toStringAsFixed(5)) +
                          ', ' +
                          (lng.toStringAsFixed(5)) +
                          ')',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: gmaps.GoogleMap(
                          initialCameraPosition: gmaps.CameraPosition(
                            target: gmaps.LatLng(lat, lng),
                            zoom: 16,
                          ),
                          markers: {
                            gmaps.Marker(
                              markerId: gmaps.MarkerId(car.id.toString()),
                              position: gmaps.LatLng(lat, lng),
                              infoWindow: gmaps.InfoWindow(title: car.name),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          liteModeEnabled: true,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isTracking
                              ? Icons.location_disabled
                              : Icons.location_searching,
                        ),
                        label: Text(
                          isTracking ? 'Stop Tracking' : 'Track This Car',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTracking ? Colors.redAccent : Colors.blue,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          if (isTracking) {
                            carProvider.untrackCar();
                          } else {
                            carProvider.trackCar(car);
                          }
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
