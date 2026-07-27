import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_providers.dart';

class EditAppointmentScreen extends StatefulWidget {
  final String appointmentId;

  const EditAppointmentScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<EditAppointmentScreen> createState() =>
      _EditAppointmentScreenState();
}

class _EditAppointmentScreenState
    extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _vetController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;

  String _selectedService = "General Check-up";

  AppointmentStatus _selectedStatus =
      AppointmentStatus.upcoming;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _saving = false;

  bool _initialized = false;

  final List<String> _services = [
    "General Check-up",
    "Vaccination",
    "Grooming",
    "Deworming",
    "Surgery",
    "Dental Care",
    "Emergency Visit",
  ];

  void _loadAppointment(
    AppointmentModel appointment,
    List<PetModel> pets,
  ) {
    if (_initialized) return;

    _vetController.text = appointment.vetName;
    _locationController.text =
        appointment.location ?? "";
    _notesController.text =
        appointment.notes ?? "";

    _selectedService = appointment.service;
    _selectedStatus = appointment.status;

    _selectedDate = appointment.dateTime;

    _selectedTime = TimeOfDay(
      hour: appointment.dateTime.hour,
      minute: appointment.dateTime.minute,
    );

    try {
      _selectedPet = pets.firstWhere(
        (pet) => pet.id == appointment.petId,
      );
    } catch (_) {}

    _initialized = true;
  }

  @override
  void dispose() {
    _vetController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appointment'),
      ),
      body: const Center(
        child: Text('Edit appointment screen'),
      ),
    );
  }}