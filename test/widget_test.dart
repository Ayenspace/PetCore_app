import 'package:flutter_test/flutter_test.dart';
import 'package:petcore_app/app/app.dart';
import 'package:petcore_app/models/marketplace_order_model.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PetCoreApp());
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
}
