import 'package:firebase_database/firebase_database.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId) => _db.ref('appointments/$ownerId');

  Future<AppointmentModel> addAppointment(AppointmentModel appointment) async {
    final ref = _ref(appointment.ownerId).push();
    final newAppt = AppointmentModel(
      id: ref.key!,
      ownerId: appointment.ownerId,
      petId: appointment.petId,
      petName: appointment.petName,
      service: appointment.service,
      vetName: appointment.vetName,
      location: appointment.location,
      dateTime: appointment.dateTime,
      notes: appointment.notes,
      status: appointment.status,
      createdAt: appointment.createdAt,
    );
    await ref.set(newAppt.toMap());
    return newAppt;
  }

  Future<void> updateAppointment(AppointmentModel appointment) =>
      _ref(appointment.ownerId).child(appointment.id).update(appointment.toMap());

  Future<void> deleteAppointment(String ownerId, String appointmentId) =>
      _ref(ownerId).child(appointmentId).remove();

  Stream<List<AppointmentModel>> appointmentsStream(String ownerId) =>
      _ref(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return AppointmentModel.fromMap(data);
        }).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
}
