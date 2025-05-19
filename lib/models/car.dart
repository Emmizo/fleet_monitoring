import 'package:hive/hive.dart';
part 'car.g.dart';

@HiveType(typeId: 0)
class Car {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final dynamic latitude;
  @HiveField(3)
  final dynamic longitude;
  @HiveField(4)
  final int speed;
  @HiveField(5)
  final String status;

  Car({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      speed: int.tryParse(json['speed'].toString()) ?? 0,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'status': status,
    };
  }
}
