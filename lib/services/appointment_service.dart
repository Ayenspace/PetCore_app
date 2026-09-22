import 'package:firebase_database/firebase_database.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId) => _db.ref('appointments/$ownerId');
  DatabaseReference _vetRef(String vetId) => _db.ref('vet_appointments/$vetId');

  Future<AppointmentModel> addAppointment(AppointmentModel appointment) async {
    await _ensureNoConflict(appointment);

    final ownerRef = _ref(appointment.ownerId).push();
    final vetRef = _vetRef(appointment.vetId).push();

    final newAppt = AppointmentModel(
      id: ownerRef.key!,
      ownerId: appointment.ownerId,
      petId: appointment.petId,
      petName: appointment.petName,
      service: appointment.service,
      vetName: appointment.vetName,
      vetId: appointment.vetId,
      location: appointment.location,
      dateTime: appointment.dateTime,
      notes: appointment.notes,
      status: appointment.status,
      createdAt: appointment.createdAt,
    );

    await ownerRef.set(newAppt.toMap());
    if (appointment.vetId.isNotEmpty) {
      await vetRef.set(newAppt.toMap());
    }
    return newAppt;
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    await _ensureNoConflict(appointment, excludeId: appointment.id);
    await _ref(
      appointment.ownerId,
    ).child(appointment.id).update(appointment.toMap());
    if (appointment.vetId.isNotEmpty) {
      await _vetRef(
        appointment.vetId,
      ).child(appointment.id).update(appointment.toMap());
    }
  }

  Future<void> _ensureNoConflict(
    AppointmentModel appointment, {
    String? excludeId,
  }) async {
    if (appointment.vetId.isEmpty ||
        appointment.status != AppointmentStatus.upcoming) {
      return;
    }

    final existing = await _vetRef(appointment.vetId).get();
    if (!existing.exists || existing.value is! Map) return;

    final appointments = Map<String, dynamic>.from(
      (existing.value as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final hasConflict = appointments.entries.any((entry) {
      if (entry.key == excludeId || entry.value is! Map) return false;
      final data = Map<String, dynamic>.from(
        (entry.value as Map).map(
          (key, item) => MapEntry(key.toString(), item),
        ),
      );
      final status = data['status']?.toString();
      final dateTime = DateTime.tryParse(data['dateTime']?.toString() ?? '');
      return status == AppointmentStatus.upcoming.name &&
          dateTime != null &&
          dateTime.isAtSameMomentAs(appointment.dateTime);
    });

    if (hasConflict) throw AppointmentConflictException();
  }

  Future<void> updateStatus(
    String ownerId,
    String id,
    AppointmentStatus status, {
    String? vetId,
  }) async {
    await _ref(ownerId).child(id).update({'status': status.name});
    if (vetId != null && vetId.isNotEmpty) {
      await _vetRef(vetId).child(id).update({'status': status.name});
    }
  }

  Future<void> deleteAppointment(
    String ownerId,
    String appointmentId, {
    String? vetId,
  }) async {
    await _ref(ownerId).child(appointmentId).remove();
    if (vetId != null && vetId.isNotEmpty) {
      await _vetRef(vetId).child(appointmentId).remove();
    }
  }

  Stream<List<AppointmentModel>> appointmentsStream(String ownerId) =>
      _ref(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return AppointmentModel.fromMap(data);
        }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });

  Stream<List<AppointmentModel>> vetAppointmentsStream(String vetId) =>
      _vetRef(vetId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return AppointmentModel.fromMap(data);
        }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
}

class AppointmentConflictException implements Exception {
  @override
  String toString() =>
      'This veterinarian already has an appointment at that time.';
}
