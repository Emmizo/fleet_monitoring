import 'dart:async';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import 'package:hive/hive.dart';

class CarProvider extends ChangeNotifier {
  final CarService carService;
  List<Car> _cars = [];
  List<Car> get cars => _filteredCars();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String get statusFilter => _statusFilter;
  String? errorMessage;
  Car? _trackedCar;

  CarProvider({required this.carService}) {
    _clearOldHiveData();
    fetchCars();
  }

  void _clearOldHiveData() async {
    try {
      final box = await Hive.openBox<Car>('cars');
      await box.clear();
      await box.close();
    } catch (e) {
      // Ignore if Hive is not used or box doesn't exist
    }
  }

  Future<void> fetchCars() async {
    try {
      _cars = await CarService.getCars();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to fetch car data';
    }
    notifyListeners();
  }

  Future<void> addCar(Car car) async {
    try {
      final newCar = await CarService.addCar(car);
      _cars.add(newCar);
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to add car';
      notifyListeners();
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      final updatedCar = await CarService.updateCar(car);
      final index = _cars.indexWhere((c) => c.id == car.id);
      if (index != -1) {
        _cars[index] = updatedCar;
      }
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to update car';
      notifyListeners();
    }
  }

  Future<void> deleteCar(String id) async {
    try {
      await CarService.deleteCar(id);
      _cars.removeWhere((c) => c.id == id);
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to delete car';
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void trackCar(Car car) {
    _trackedCar = car;
    notifyListeners();
  }

  void untrackCar() {
    _trackedCar = null;
    notifyListeners();
  }

  Car? get trackedCar => _trackedCar;

  List<Car> _filteredCars() {
    var filtered = _cars;
    if (_statusFilter != 'All') {
      filtered = filtered.where((c) => c.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.id.toString().contains(_searchQuery),
              )
              .toList();
    }
    return filtered;
  }
}
