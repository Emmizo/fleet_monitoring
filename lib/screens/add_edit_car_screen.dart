import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';

const Color kPrimaryColor = Color(0xFF164654);
const Color kBackgroundColor = Color(0xFFFFFFFF);

class AddEditCarScreen extends StatefulWidget {
  final Car? car;
  const AddEditCarScreen({super.key, this.car});

  @override
  State<AddEditCarScreen> createState() => _AddEditCarScreenState();
}

class _AddEditCarScreenState extends State<AddEditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _speedController;
  late TextEditingController _statusController;
  String _selectedStatus = 'Moving';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.car?.name ?? '');
    _latitudeController = TextEditingController(
      text: widget.car?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.car?.longitude?.toString() ?? '',
    );
    _speedController = TextEditingController(
      text: widget.car?.speed.toString() ?? '',
    );
    _selectedStatus = widget.car?.status ?? 'Moving';
    _statusController = TextEditingController(text: _selectedStatus);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _speedController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      final car = Car(
        id: widget.car?.id ?? '',
        name: _nameController.text,
        latitude: _latitudeController.text,
        longitude: _longitudeController.text,
        speed: int.tryParse(_speedController.text) ?? 0,
        status: _selectedStatus,
      );
      if (widget.car == null) {
        await carProvider.addCar(car);
      } else {
        await carProvider.updateCar(car);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.car != null;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Car' : 'Add Car',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'Edit Car Details' : 'Add New Car',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 28),
                      _buildTextField(
                        _nameController,
                        'Name',
                        Icons.directions_car,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter name'
                                    : null,
                      ),
                      SizedBox(height: 18),
                      _buildTextField(
                        _latitudeController,
                        'Latitude',
                        Icons.location_on,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter latitude'
                                    : null,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 18),
                      _buildTextField(
                        _longitudeController,
                        'Longitude',
                        Icons.location_on_outlined,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter longitude'
                                    : null,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 18),
                      _buildTextField(
                        _speedController,
                        'Speed',
                        Icons.speed,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter speed'
                                    : null,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag, color: kPrimaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: kPrimaryColor,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: kPrimaryColor.withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: kPrimaryColor,
                              width: 1.8,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        items:
                            ['Moving', 'Parked']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Select status'
                                    : null,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(isEdit ? 'Update Car' : 'Add Car'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: kPrimaryColor.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.8),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
