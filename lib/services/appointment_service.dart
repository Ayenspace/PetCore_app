import 'package:firebase_database/firebase_database.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _appointmentsRef(String ownerId) =>
      _db.ref('appointments/$ownerId');

  Future<AppointmentModel> addAppointment(
      AppointmentModel appointment) async {
    final ref = _appointmentsRef(appointment.ownerId).push();

    final newAppointment = appointment.copyWith(
      id: ref.key!,
    );

    await ref.set(newAppointment.toMap());

    return newAppointment;
  }

  Future<void> updateAppointment(
      AppointmentModel appointment) async {
    await _appointmentsRef(appointment.ownerId)
        .child(appointment.id)
        .update(appointment.toMap());
  }

  Future<void> deleteAppointment(
      String ownerId,
      String appointmentId,
      ) async {
    await _appointmentsRef(ownerId)
        .child(appointmentId)
        .remove();
  }

  Stream<List<AppointmentModel>> appointmentsStream(
      String ownerId,
      ) {
    return _appointmentsRef(ownerId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return [];
      }

      final map = Map<String, dynamic>.from(
        (event.snapshot.value as Map).map(
              (k, v) => MapEntry(
            k.toString(),
            v,
          ),
        ),
      );

      final dataList = map.values.map((value) {
        return Map<String, dynamic>.from(
          (value as Map).map(
                (k, v) => MapEntry(
              k.toString(),
              v,
            ),
          ),
        );
      }).toList();

      dataList.sort((a, b) {
        DateTime parse(dynamic v) {
          try {
            if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
            return DateTime.parse(v.toString());
          } catch (_) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
        }

        return parse(a['date']).compareTo(parse(b['date']));
      });

      final appointments = dataList.map((data) => AppointmentModel.fromMap(data)).toList();

      return appointments;
    });
  }
}