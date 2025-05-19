import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/car.dart';

class CarService {
  static const String baseUrl =
      'https://682ae9ffab2b5004cb383a12.mockapi.io/api/v1';

  static Future<List<Car>> getCars() async {
    final response = await http.get(Uri.parse('$baseUrl/cars'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Car.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cars');
    }
  }

  static Future<Car> getCar(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/cars/$id'));
    if (response.statusCode == 200) {
      return Car.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load car');
    }
  }

  static Future<Car> addCar(Car car) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cars'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(car.toJson()),
    );
    if (response.statusCode == 201) {
      return Car.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add car');
    }
  }

  static Future<Car> updateCar(Car car) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cars/${car.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(car.toJson()),
    );
    if (response.statusCode == 200) {
      return Car.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update car');
    }
  }

  static Future<void> deleteCar(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/cars/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete car');
    }
  }
}
