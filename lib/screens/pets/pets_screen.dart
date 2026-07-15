import 'package:flutter/material.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Pets')));
}

class AddPetScreen extends StatelessWidget {
  const AddPetScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Pet')));
}

class PetDetailsScreen extends StatelessWidget {
  final String petId;
  const PetDetailsScreen({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Pet $petId')));
}

class EditPetScreen extends StatelessWidget {
  final String petId;
  const EditPetScreen({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Edit Pet $petId')));
}
