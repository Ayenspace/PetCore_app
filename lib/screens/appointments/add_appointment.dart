import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../services/vet_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final _vetService = VetService();
  List<UserModel> _vets = [];
  UserModel? _selectedVet;
  PetModel? _selectedPet;

  String _selectedService = "General Check-up";

  final List<String> _services = [
    "General Check-up",
    "Vaccination",
    "Grooming",
    "Deworming",
    "Surgery",
    "Dental Care",
    "Emergency Visit",
  ];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _saving = false;
  bool _loadingVets = true;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    try {
      final vets = await _vetService.loadVets();
      if (!mounted) return;
      setState(() {
        _vets = vets;
        _loadingVets = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVets = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load veterinarians: $e')),
      );
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a pet.")));
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time.")),
      );
      return;
    }

    setState(() => _saving = true);

    final auth = context.read<AppAuthProvider>();

    final owner = auth.user!;

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (_selectedVet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a veterinarian.")),
      );
      setState(() => _saving = false);
      return;
    }

    final appointment = AppointmentModel(
      id: "",
      ownerId: owner.id,
      petId: _selectedPet!.id,
      petName: _selectedPet!.name,
      service: _selectedService,
      vetName: _selectedVet!.name,
      location: _locationController.text.trim(),
      dateTime: appointmentDateTime,
      notes: _notesController.text.trim(),
      status: AppointmentStatus.upcoming,
      createdAt: DateTime.now(),
    );

    final success = await context.read<AppointmentProvider>().addAppointment(
      appointment,
    );

    setState(() => _saving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment added successfully.")),
      );

      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save appointment.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Appointment")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<PetModel>(
                initialValue: _selectedPet,
                decoration: const InputDecoration(
                  labelText: 'Select Pet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: pets.map((pet) {
                  return DropdownMenuItem(
                    value: pet,
                    child: Text("${pet.name} (${pet.species})"),
                  );
                }).toList(),
                onChanged: (pet) {
                  setState(() {
                    _selectedPet = pet;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a pet' : null,
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: _services.map((service) {
                  return DropdownMenuItem(value: service, child: Text(service));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              _loadingVets
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonFormField<UserModel>(
                      initialValue: _selectedVet,
                      decoration: const InputDecoration(
                        labelText: 'Veterinarian',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _vets.map((vet) {
                        return DropdownMenuItem(
                          value: vet,
                          child: Text(
                            vet.clinicName != null && vet.clinicName!.isNotEmpty
                                ? '${vet.name} • ${vet.clinicName}'
                                : vet.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (vet) {
                        setState(() => _selectedVet = vet);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a veterinarian' : null,
                    ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Clinic / Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter clinic location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? "Select Date"
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? "Select Time"
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveAppointment,
                  icon: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? "Saving..." : "Save Appointment"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
