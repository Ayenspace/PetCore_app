import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/user_model.dart';
import '../../models/vaccination_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vaccination_provider.dart';
import '../../services/pet_service.dart';
import '../../services/vet_service.dart';

class AddVaccinationScreen extends StatefulWidget {
  const AddVaccinationScreen({super.key});
  @override
  State<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends State<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaccineController = TextEditingController();
  final _notesController = TextEditingController();

  final _vetService = VetService();
  final _petService = PetService();
  StreamSubscription? _petSub;

  List<PetModel> _pets = [];
  List<UserModel> _vets = [];
  bool _loadingPets = true;
  bool _loadingVets = true;

  PetModel? _selectedPet;
  UserModel? _selectedVet;
  DateTime _dateGiven = DateTime.now();
  DateTime? _nextDueDate;

  final _commonVaccines = [
    'Rabies', 'Distemper', 'Parvovirus', 'Bordetella',
    'Leptospirosis', 'Lyme Disease', 'FVRCP', 'FeLV', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadVets();
  }

  void _loadPets() {
    final ownerId = context.read<AppAuthProvider>().user!.id;
    _petSub = _petService.petsStream(ownerId).listen((pets) {
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _loadingPets = false;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _loadingPets = false);
    });
  }

  Future<void> _loadVets() async {
    try {
      final vets = await _vetService.loadVets();
      if (!mounted) return;
      setState(() {
        _vets = vets;
        _loadingVets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVets = false);
    }
  }

  @override
  void dispose() {
    _petSub?.cancel();
    _vaccineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateGiven() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateGiven,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateGiven = picked);
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    if (_selectedVet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a veterinarian')),
      );
      return;
    }

    final uid = context.read<AppAuthProvider>().user!.id;
    final vaccination = VaccinationModel(
      id: '',
      ownerId: uid,
      petId: _selectedPet!.id,
      petName: _selectedPet!.name,
      vaccineName: _vaccineController.text.trim(),
      vetName: _selectedVet!.name,
      dateGiven: _dateGiven,
      nextDueDate: _nextDueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await context.read<VaccinationProvider>().addVaccination(vaccination);
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaccinationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vaccination', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _loadingPets
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<PetModel>(
                      initialValue: _selectedPet,
                      hint: const Text('Select a pet'),
                      decoration: const InputDecoration(
                        labelText: 'Select Pet',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: _pets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (p) => setState(() => _selectedPet = p),
                      validator: (v) => v == null ? 'Please select a pet' : null,
                    ),
              const SizedBox(height: 16),

              // Vaccine name with quick-select chips
              TextFormField(
                controller: _vaccineController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  prefixIcon: Icon(Icons.vaccines),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the vaccine name' : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _commonVaccines.map((name) => ActionChip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _vaccineController.text = name),
                  backgroundColor: _vaccineController.text == name
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                )).toList(),
              ),
              const SizedBox(height: 16),

              _loadingVets
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<UserModel>(
                      initialValue: _selectedVet,
                      hint: const Text('Select a veterinarian'),
                      decoration: const InputDecoration(
                        labelText: 'Veterinarian',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _vets.map((vet) => DropdownMenuItem(
                        value: vet,
                        child: Text(
                          vet.clinicName != null && vet.clinicName!.isNotEmpty
                              ? '${vet.name} • ${vet.clinicName}'
                              : vet.name,
                        ),
                      )).toList(),
                      onChanged: (vet) => setState(() => _selectedVet = vet),
                      validator: (v) => v == null ? 'Please select a veterinarian' : null,
                    ),
              const SizedBox(height: 16),

              // Date given
              GestureDetector(
                onTap: _pickDateGiven,
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_dateGiven),
                    initialValue: '${_dateGiven.day}/${_dateGiven.month}/${_dateGiven.year}',
                    decoration: const InputDecoration(
                      labelText: 'Date Given',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Next due date (optional)
              GestureDetector(
                onTap: _pickNextDueDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_nextDueDate),
                    initialValue: _nextDueDate == null
                        ? ''
                        : '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}',
                    decoration: InputDecoration(
                      labelText: 'Next Due Date (optional)',
                      prefixIcon: const Icon(Icons.event_repeat_outlined),
                      suffixIcon: _nextDueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _nextDueDate = null),
                            )
                          : const Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.loading ? null : _save,
                  child: provider.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Vaccination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
