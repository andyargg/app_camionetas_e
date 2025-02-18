import 'package:app_camionetas_empleado/Models/vehicle.dart';
import 'package:app_camionetas_empleado/Services/vehicle_repository.dart';
import 'package:app_camionetas_empleado/Widgets/dropdown_widget.dart';
import 'package:app_camionetas_empleado/Widgets/nav_bar_widget.dart';
import 'package:app_camionetas_empleado/Widgets/search_anchor_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  List<Vehicle> _pendingVehicles = [];
  int _editingVehicleIndex = -1;
  final _formKey = GlobalKey<FormState>();
  final VehicleRepository _repository = VehicleRepository(FirebaseFirestore.instance);
  final _patenteController = TextEditingController();
  final _tecnicoController = TextEditingController();
  
  Map<String, String> _formValues = {
    'patent': '',
    'technician': '',
    'order': '',
    'cleanliness': '',
    'water': '',
    'spareTire': '',
    'oil': '',
    'jack': '',
    'crossWrench': '',
    'fireExtinguisher': '',
    'lock': '',
    'comment': '',
  };

  bool _isLoading = true;
  List<String> _patentes = [];
  List<String> _tecnicos = [];

  final Map<String, List<String>> _formOptions = {
    'cleanliness': ["Impecable", "Bien", "Algo descuidado", "Deficiente"],
    'yesNo': ["Sí", "No"],
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _patenteController.dispose();
    _tecnicoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await rootBundle.loadString('assets/data.json');
      final data = json.decode(response) as Map<String, dynamic>;
      
      setState(() {
        _patentes = List<String>.from(data['patentes']);
        _tecnicos = List<String>.from(data['tecnicos']);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error loading initial data');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final vehicle = Vehicle(
        date: Timestamp.now(),
        patent: _formValues['patent']!,
        technician: _formValues['technician']!,
        order: _formValues['order']!,
        cleanliness: _formValues['cleanliness']!,
        water: _formValues['water']!,
        spareTire: _formValues['spareTire']!,
        oil: _formValues['oil']!,
        jack: _formValues['jack']!,
        crossWrench: _formValues['crossWrench']!,
        fireExtinguisher: _formValues['fireExtinguisher']!,
        lock: _formValues['lock']!,
        comment: _formValues['comment']!,
      );


      if (_editingVehicleIndex > 0) {
        _pendingVehicles[_editingVehicleIndex] = vehicle;
        _editingVehicleIndex = -1;
      } else {
        _pendingVehicles.add(vehicle);
      }
      // await _repository.save(vehicle);
      _showSuccess('Vehículo agregado exitosamente');
      _resetForm();
    } catch (e) {
      _showError('Error al agregar el vehículo: ${e.toString()}');
    }
  }

  void _resetForm() {
    setState(() {
      _formValues = {
        'patent': '',
        'technician': '',
        'order': '',
        'cleanliness': '',
        'water': '',
        'spareTire': '',
        'oil': '',
        'jack': '',
        'crossWrench': '',
        'fireExtinguisher': '',
        'lock': '',
        'comment': '',
      };
      
      _editingVehicleIndex = -1; // Resetear el índice de edición
    });
    
    _patenteController.clear();
    _tecnicoController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de vehiculos')),
      drawer: NavBarWidget(
        pendingVehicles: _pendingVehicles,
        onEditVehicle: _handleEditVehicle,
        onDeleteVehicle: _handleDeleteVehicle,
        onSubmitAll: _submitAllVehicles,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              
              SearchAnchorWidget(
                hint: 'Patentes',
                suggestions: _patentes,
                formKey: 'patent',
                formValues: _formValues,
                controller: _patenteController,
                onItemSelected: (value) {
                  
                  setState(() => _formValues['patent'] = value);
                },
              ),
              const SizedBox(height: 20),
              SearchAnchorWidget(
                hint: 'Busca tecnico',
                suggestions: _tecnicos,
                formKey: 'technician',
                formValues: _formValues,
                controller: _tecnicoController,
                onItemSelected: (value) {
                  
                  setState(() => _formValues['technician'] = value);
                },
              ),

              const SizedBox(height: 20),
              DropdownWidget(
                label: 'Orden',
                options: _formOptions['cleanliness']!,
                formKey: 'order', 
                formValues: _formValues,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _formValues['order'] = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              DropdownWidget(
                label: 'Limpieza',
                options: _formOptions['cleanliness']!,
                formKey: 'cleanliness',
                formValues: _formValues,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _formValues['cleanliness'] = value);
                  }
                },
              ),
              ..._buildYesNoFields(),
              const SizedBox(height: 20),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _formValues['comment'] = value,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _addForm,
                child: const Text('AGREGAR', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildYesNoFields() {
    const fields = {
      'water': 'Agua',
      'spareTire': 'Rueda de auxilio',
      'oil': 'Aceite',
      'jack': 'Crique',
      'crossWrench': 'Llave cruz',
      'fireExtinguisher': 'Extinguidor',
      'lock': 'Candado',
    };

    return fields.entries.map((entry) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownWidget(
        label: entry.value,
        options: _formOptions['yesNo']!,
        formKey: entry.key,
        formValues: _formValues,
        onChanged: (value) {
          if (value != null) {
            setState(() => _formValues[entry.key] = value);
          }
        },
      ),
    )).toList();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleEditVehicle(int index) {
    final vehicle = _pendingVehicles[index];

    setState(() {
      _formValues = {
        'patent': vehicle.patent,
        'technician': vehicle.technician,
        'order': vehicle.order,
        'cleanliness': vehicle.cleanliness,
        'water': vehicle.water,
        'spareTire': vehicle.spareTire,
        'oil': vehicle.oil,
        'jack': vehicle.jack,
        'crossWrench': vehicle.crossWrench,
        'fireExtinguisher': vehicle.fireExtinguisher,
        'lock': vehicle.lock,
        'comment': vehicle.comment, 
      };
      
      _patenteController.text = vehicle.patent;
      _tecnicoController.text = vehicle.technician;
      
      _editingVehicleIndex = index;
    });

    Navigator.pop(context);
  }

  void _handleDeleteVehicle(int index) {
    setState(() {
      _pendingVehicles.removeAt(index);

      if (_editingVehicleIndex == index) {
        _resetForm();
        _editingVehicleIndex = -1;
      }
      else if (_editingVehicleIndex > index) {
        _editingVehicleIndex--;
      }
    });
  }

  Future<void> _submitAllVehicles() async {
    if (_pendingVehicles.isEmpty) {
      _showError('No hay vehículos pendientes para enviar');
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Enviando vehículos...'),
            ],
          ),
        ),
      );

      for (final vehicle in _pendingVehicles) {
        await _repository.save(vehicle);
      }

      Navigator.pop(context);

      _showSuccess('${_pendingVehicles.length} vehículos enviados exitosamente');
      setState(() => _pendingVehicles.clear());
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showError('Error al enviar los vehículos: ${e.toString()}');
    }
  }
}
