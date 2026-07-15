import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Appointments')));
}

class AddAppointmentScreen extends StatelessWidget {
  const AddAppointmentScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Appointment')));
}

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Appointment $appointmentId')));
}

class EditAppointmentScreen extends StatelessWidget {
  final String appointmentId;
  const EditAppointmentScreen({super.key, required this.appointmentId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Edit Appointment $appointmentId')));
}
