import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcore_app/models/appointment_model.dart';
import 'package:petcore_app/models/marketplace_order_model.dart';
import 'package:petcore_app/screens/home/vet_dashboard_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ),
    );
  });

  test('order status flow supports pending, accepted, and rejected states', () {
    final order = MarketplaceOrderModel(
      id: 'order-1',
      listingId: 'listing-1',
      listingTitle: 'Pet food',
      sellerId: 'seller-1',
      buyerId: 'buyer-1',
      buyerName: 'Jane',
      createdAt: DateTime.now(),
    );

    expect(order.isPending, isTrue);
    expect(order.copyWith(status: 'accepted').isAccepted, isTrue);
    expect(order.copyWith(status: 'rejected').isRejected, isTrue);
  });

  test('vet dashboard shows only real future upcoming appointments, keeps overdue separate, and hides completed', () {
    final now = DateTime.now();
    final appointments = [
      AppointmentModel(
        id: '1',
        ownerId: 'owner-1',
        petId: 'pet-1',
        petName: 'Bruno',
        service: 'Checkup',
        vetName: 'Dr. Smith',
        vetId: 'vet-1',
        dateTime: now.add(const Duration(days: 1)),
        status: AppointmentStatus.upcoming,
        createdAt: now,
      ),
      AppointmentModel(
        id: '2',
        ownerId: 'owner-2',
        petId: 'pet-2',
        petName: 'Milo',
        service: 'Vaccination',
        vetName: 'Dr. Smith',
        vetId: 'vet-1',
        dateTime: now.subtract(const Duration(days: 1)),
        status: AppointmentStatus.completed,
        createdAt: now,
      ),
      AppointmentModel(
        id: '3',
        ownerId: 'owner-3',
        petId: 'pet-3',
        petName: 'Luna',
        service: 'Follow-up',
        vetName: 'Dr. Smith',
        vetId: 'vet-1',
        dateTime: now.subtract(const Duration(hours: 1)),
        status: AppointmentStatus.upcoming,
        createdAt: now,
      ),
      AppointmentModel(
        id: '4',
        ownerId: 'owner-4',
        petId: 'pet-4',
        petName: 'Daisy',
        service: 'Lab review',
        vetName: 'Dr. Smith',
        vetId: 'vet-1',
        dateTime: now.subtract(const Duration(days: 2)),
        status: AppointmentStatus.overdue,
        createdAt: now,
      ),
    ];

    final visible = vetUpcomingAppointments(appointments);
    final overdue = vetOverdueAppointments(appointments);

    expect(visible.length, 1);
    expect(visible.first.id, '1');
    expect(visible.every((a) => a.status == AppointmentStatus.upcoming), isTrue);
    expect(visible.any((a) => a.status == AppointmentStatus.completed), isFalse);
    expect(overdue.length, 1);
    expect(overdue.first.id, '4');
  });
}
