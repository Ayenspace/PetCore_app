import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/vaccination_provider.dart';
import 'providers/pet_providers.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: const PetCoreApp(),
    ),
  );
}
