import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_providers.dart';

class EditAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  const EditAppointmentScreen({super.key, required this.appointmentId});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vetController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;
  String _selectedService = 'General Check-up';
  AppointmentStatus _selectedStatus = AppointmentStatus.upcoming;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;
  bool _initialized = false;

  final List<String> _services = [
    'General Check-up', 'Vaccination', 'Grooming',
    'Deworming', 'Surgery', 'Dental Care', 'Emergency Visit',
  ];

  @override
  void dispose() {
    _vetController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromAppointment(AppointmentModel appt, List<PetModel> pets) {
    if (_initialized) return;
    _initialized = true;
    _vetController.text = appt.vetName;
    _locationController.text = appt.location ?? '';
    _notesController.text = appt.notes ?? '';
    _selectedService = appt.service;
    _selectedStatus = appt.status;
    _selectedDate = appt.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(appt.dateTime);
    try {
      _selectedPet = pets.firstWhere((p) => p.id == appt.petId);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save(AppointmentModel original) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPet == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = original.copyWith(
      service: _selectedService,
      vetName: _vetController.text.trim(),
      location: _locationController.text.trim(),
      dateTime: DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      ),
      notes: _notesController.text.trim(),
      status: _selectedStatus,
    );

    final success = await context.read<AppointmentProvider>().updateAppointment(updated);
    setState(() => _saving = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update appointment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = context.read<AppointmentProvider>().getAppointmentById(widget.appointmentId);
    final pets = context.watch<PetProvider>().pets;

    if (appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Appointment')),
        body: const Center(child: Text('Appointment not found.')),
      );
    }

    _initFromAppointment(appt, pets);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Appointment')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<PetModel>(
                initialValue: _selectedPet,
                decoration: const InputDecoration(
                  labelText: 'Pet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: pets.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.species})'))).toList(),
                onChanged: (p) => setState(() => _selectedPet = p),
                validator: (v) => v == null ? 'Please select a pet' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedService = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppointmentStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: AppointmentStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vetController,
                decoration: const InputDecoration(
                  labelText: 'Veterinarian',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter veterinarian name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Clinic / Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter clinic location' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(appt),
                  icon: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
