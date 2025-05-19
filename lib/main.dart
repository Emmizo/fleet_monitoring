import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/car_provider.dart';
import 'services/car_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/car.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CarAdapter());
  await Hive.openBox<Car>('cars');
  runApp(const FleetMonitoringApp());
}

class FleetMonitoringApp extends StatelessWidget {
  const FleetMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CarProvider(carService: CarService()),
        ),
      ],
      child: MaterialApp(
        title: 'Fleet Monitoring',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
