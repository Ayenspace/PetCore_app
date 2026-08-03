import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/medical_record.dart';
import '../../models/pet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_providers.dart';

class AddMedicalRecordScreen extends StatefulWidget {
  const AddMedicalRecordScreen({super.key});
  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet')),
      );
      return;
    }

    final uid = context.read<AppAuthProvider>().user!.id;
    final record = MedicalRecord(
      id: '',
      ownerId: uid,
      petId: _selectedPet!.id,
      petName: _selectedPet!.name,
      diagnosis: _diagnosisController.text.trim(),
      treatment: _treatmentController.text.trim(),
      vetName: _vetController.text.trim(),
      date: _date,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await context.read<MedicalProvider>().addRecord(record);
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    final medical = context.watch<MedicalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Record', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet selector
              DropdownButtonFormField<PetModel>(
                decoration: const InputDecoration(
                  labelText: 'Select Pet',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: pets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (p) => setState(() => _selectedPet = p),
                validator: (v) => v == null ? 'Please select a pet' : null,
              ),
              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    initialValue: '${_date.day}/${_date.month}/${_date.year}',
                    key: ValueKey(_date),
                    decoration: const InputDecoration(
                      labelText: 'Date of Visit',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _diagnosisController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis',
                  prefixIcon: Icon(Icons.search_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a diagnosis' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _treatmentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Treatment',
                  prefixIcon: Icon(Icons.healing_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the treatment' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vetController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Veterinarian',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the vet\'s name' : null,
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
                  onPressed: medical.loading ? null : _save,
                  child: medical.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              if (medical.error != null) ...[
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
                      Expanded(child: Text(medical.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
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
