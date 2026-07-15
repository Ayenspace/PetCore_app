import 'package:flutter/material.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Marketplace')));
}

class AddListingScreen extends StatelessWidget {
  const AddListingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Listing')));
}

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('My Listings')));
}

class ListingDetailsScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailsScreen({super.key, required this.listingId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Listing $listingId')));
}

class EditListingScreen extends StatelessWidget {
  final String listingId;
  const EditListingScreen({super.key, required this.listingId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Edit Listing $listingId')));
}
