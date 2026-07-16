import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_poviders.dart';
import '../../models/pet_model.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) context.read<PetProvider>().listenToPets(uid);
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Pets', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/pets/add'),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
      body: pets.isEmpty ? _buildEmptyState(context) : _buildPetList(context, pets),
      floatingActionButton: pets.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/pets/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No pets yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Add your first pet to get started', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/pets/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetList(BuildContext context, List<PetModel> pets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetCard(pet: pets[index]),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
            child: pet.photoUrl == null
                ? Icon(Icons.pets, color: theme.colorScheme.primary, size: 28)
                : null,
          ),
          title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
            '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''} • ${pet.age} yr${pet.age != 1 ? 's' : ''}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pet.gender.toLowerCase() == 'male'
                      ? Colors.blue.shade50
                      : Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pet.gender,
                  style: TextStyle(
                    fontSize: 12,
                    color: pet.gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPetScreen extends StatelessWidget {
  const AddPetScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PetForm();
}

class EditPetScreen extends StatelessWidget {
  final String petId;
  const EditPetScreen({super.key, required this.petId});
  @override
  Widget build(BuildContext context) {
    final pet = context.read<PetProvider>().getPetById(petId);
    return _PetForm(pet: pet);
  }
}

class _PetForm extends StatefulWidget {
  final PetModel? pet;
  const _PetForm({this.pet});
  @override
  State<_PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<_PetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  String _gender = 'Male';
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365));
  bool get _isEditing => widget.pet != null;

  final _species = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Fish', 'Hamster', 'Reptile', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name ?? '');
    _speciesController = TextEditingController(text: widget.pet?.species ?? '');
    _breedController = TextEditingController(text: widget.pet?.breed ?? '');
    _weightController = TextEditingController(text: widget.pet?.weight?.toString() ?? '');
    if (widget.pet != null) {
      _gender = widget.pet!.gender;
      _dateOfBirth = widget.pet!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final petProvider = context.read<PetProvider>();
    final uid = auth.user!.id;

    final pet = PetModel(
      id: widget.pet?.id ?? '',
      ownerId: uid,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      weight: double.tryParse(_weightController.text),
      photoUrl: widget.pet?.photoUrl,
      createdAt: widget.pet?.createdAt ?? DateTime.now(),
    );

    final success = _isEditing
        ? await petProvider.updatePet(pet)
        : await petProvider.addPet(pet);

    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : 'Add Pet', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.pets, size: 50, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Pet Name', prefixIcon: Icon(Icons.pets)),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _species.contains(_speciesController.text) ? _speciesController.text : null,
                decoration: const InputDecoration(labelText: 'Species', prefixIcon: Icon(Icons.category_outlined)),
                items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => _speciesController.text = v ?? '',
                validator: (v) => v == null || v.isEmpty ? 'Please select a species' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Breed (optional)', prefixIcon: Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Male', 'Female'].map((g) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _gender = g),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _gender == g ? theme.colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _gender == g ? theme.colorScheme.primary : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  g,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _gender == g ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    initialValue: '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight in kg (optional)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: petProvider.loading ? null : _save,
                  child: petProvider.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Save Changes' : 'Add Pet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/home'); break;
          case 1: context.go('/pets'); break;
          case 2: context.go('/appointments'); break;
          case 3: context.go('/marketplace'); break;
          case 4: context.go('/profile'); break;
        }
      },
      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Appointments'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Market'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
