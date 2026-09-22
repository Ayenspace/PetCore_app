import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/weight_service.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    final appointment = provider.getAppointmentById(appointmentId);
    final user = context.watch<AppAuthProvider>().user;
    final isVet = user?.isVet == true;

    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Appointment not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Details")),
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
                TimeOfDay.fromDateTime(appointment.dateTime).format(context),
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
              subtitle: Text(appointment.location ?? "Not provided"),
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
              label: Text(appointment.status.name.toUpperCase()),
              backgroundColor: appointment.status == AppointmentStatus.upcoming
                  ? Colors.blue.shade50
                  : appointment.status == AppointmentStatus.completed
                  ? Colors.green.shade50
                  : appointment.status == AppointmentStatus.overdue
                  ? Colors.orange.shade50
                  : Colors.red.shade50,
              avatar: Icon(
                appointment.status == AppointmentStatus.upcoming
                    ? Icons.schedule
                    : appointment.status == AppointmentStatus.completed
                    ? Icons.check_circle
                    : appointment.status == AppointmentStatus.overdue
                    ? Icons.warning_amber_rounded
                    : Icons.cancel,
                color: appointment.status == AppointmentStatus.upcoming
                    ? Colors.blue
                    : appointment.status == AppointmentStatus.completed
                    ? Colors.green
                    : appointment.status == AppointmentStatus.overdue
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ),

          if (isVet &&
              (appointment.status == AppointmentStatus.upcoming ||
                  appointment.status == AppointmentStatus.overdue)) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/medical/add', extra: appointment),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add clinical record'),
            ),
          ],

          if (isVet) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showWeightDialog(context, appointment),
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('Update weight'),
            ),
          ],

          if (appointment.status == AppointmentStatus.upcoming ||
              appointment.status == AppointmentStatus.overdue) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await context
                          .read<AppointmentProvider>()
                          .updateAppointment(
                            appointment.copyWith(
                              status: AppointmentStatus.completed,
                            ),
                          );
                      if (context.mounted) context.pop();
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Mark Complete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await context
                          .read<AppointmentProvider>()
                          .updateAppointment(
                            appointment.copyWith(
                              status: AppointmentStatus.cancelled,
                            ),
                          );
                      if (context.mounted) context.pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 30),
          if (!isVet)
            ElevatedButton.icon(
              onPressed: () {
                context.push("/appointments/${appointment.id}/edit");
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Appointment"),
            ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: () async {
              final controller = TextEditingController();
              final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
              final provider = context.read<AppointmentProvider>();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Send note'),
                  content: SizedBox(
                    width: 360,
                    child: TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: isVet
                            ? 'Write a message for the pet owner'
                            : 'Write a quick message for ${appointment.vetName}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              );

              if (confirmed != true || controller.text.trim().isEmpty) return;

              final nextNotes = (appointment.notes ?? '').trim();
              final message = controller.text.trim();
              final combined = nextNotes.isEmpty
                  ? message
                  : '$nextNotes\n\n$message';

              final success = await provider.updateAppointment(
                appointment.copyWith(notes: combined),
              );

              if (context.mounted && scaffoldMessenger != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Message saved.' : 'Failed to save message.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Send message'),
          ),

          const SizedBox(height: 15),

          if (!isVet)
            FilledButton.tonalIcon(
              onPressed: () async {
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

                await apptProvider.deleteAppointment(
                  appointment.ownerId,
                  appointment.id,
                  vetId: appointment.vetId,
                );

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

  Future<void> _showWeightDialog(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${appointment.petName} weight'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
            ),
            validator: (value) {
              final parsed = double.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0) return 'Enter a valid weight';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, double.parse(controller.text.trim()));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (weight == null || !context.mounted) return;
    try {
      await WeightService().addVetEntry(
        ownerId: appointment.ownerId,
        petId: appointment.petId,
        appointmentId: appointment.id,
        weight: weight,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Weight history updated')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update weight')),
        );
      }
    }
  }
}
