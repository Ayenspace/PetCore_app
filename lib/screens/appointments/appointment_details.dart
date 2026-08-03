import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    final appointment = provider.getAppointmentById(appointmentId);

    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("Appointment not found."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
                    Icon(
            Icons.calendar_month,
            size: 70,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              appointment.petName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              appointment.service,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          const SizedBox(height: 30),
                    Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Date"),
              subtitle: Text(
                "${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Time"),
              subtitle: Text(
                TimeOfDay.fromDateTime(
                  appointment.dateTime,
                ).format(context),
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Veterinarian"),
              subtitle: Text(appointment.vetName),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Clinic"),
              subtitle: Text(
                appointment.location ?? "Not provided",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.notes),
              title: const Text("Notes"),
              subtitle: Text(
                appointment.notes?.isEmpty ?? true
                    ? "No notes"
                    : appointment.notes!,
              ),
            ),
          ),

          const SizedBox(height: 20),
                    Center(
            child: Chip(
              label: Text(
                appointment.status.name.toUpperCase(),
              ),
              avatar: Icon(
                appointment.status == AppointmentStatus.upcoming
                    ? Icons.schedule
                    : appointment.status == AppointmentStatus.completed
                        ? Icons.check_circle
                        : Icons.cancel,
              ),
            ),
          ),

          const SizedBox(height: 30),
                    ElevatedButton.icon(
            onPressed: () {
              context.push(
                "/appointments/${appointment.id}/edit",
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text("Edit Appointment"),
          ),

          const SizedBox(height: 15),

          FilledButton.tonalIcon(
            onPressed: () async {
              final ownerId = context.read<AppAuthProvider>().user!.id;
              final apptProvider = context.read<AppointmentProvider>();
              final router = GoRouter.of(context);

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Appointment"),
                  content: const Text(
                    "Are you sure you want to delete this appointment?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              await apptProvider.deleteAppointment(ownerId, appointment.id);

              if (context.mounted) {
                router.pop();
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text("Delete Appointment"),
          ),
                  ],
      ),
    );
  }
}