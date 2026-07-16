import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/authentication/welcome_screen.dart';
import '../screens/authentication/login_screen.dart';
import '../screens/authentication/register_screen.dart';
import '../screens/authentication/fogort_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/pets/pets_screen.dart';
import '../screens/pets/pet_details_screen.dart';
import '../screens/appointments/appointments.dart';
import '../screens/medical/medical_records_screen.dart';
import '../screens/vaccinations/vaccinations_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/repots/reports_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/pets', builder: (c, s) => const PetsScreen()),
      GoRoute(path: '/pets/add', builder: (c, s) => const AddPetScreen()),
      GoRoute(path: '/pets/:id', builder: (c, s) => PetDetailsScreen(petId: s.pathParameters['id']!)),
      GoRoute(path: '/pets/:id/edit', builder: (c, s) => EditPetScreen(petId: s.pathParameters['id']!)),
      GoRoute(path: '/appointments', builder: (c, s) => const AppointmentsScreen()),
      GoRoute(path: '/appointments/add', builder: (c, s) => const AddAppointmentScreen()),
      GoRoute(path: '/appointments/:id', builder: (c, s) => AppointmentDetailsScreen(appointmentId: s.pathParameters['id']!)),
      GoRoute(path: '/appointments/:id/edit', builder: (c, s) => EditAppointmentScreen(appointmentId: s.pathParameters['id']!)),
      GoRoute(path: '/medical', builder: (c, s) => const MedicalRecordsScreen()),
      GoRoute(path: '/medical/add', builder: (c, s) => const AddMedicalRecordScreen()),
      GoRoute(path: '/vaccinations', builder: (c, s) => const VaccinationsScreen()),
      GoRoute(path: '/vaccinations/add', builder: (c, s) => const AddVaccinationScreen()),
      GoRoute(path: '/reminders', builder: (c, s) => const RemindersScreen()),
      GoRoute(path: '/marketplace', builder: (c, s) => const MarketplaceScreen()),
      GoRoute(path: '/marketplace/add', builder: (c, s) => const AddListingScreen()),
      GoRoute(path: '/marketplace/my-listings', builder: (c, s) => const MyListingsScreen()),
      GoRoute(path: '/marketplace/:id', builder: (c, s) => ListingDetailsScreen(listingId: s.pathParameters['id']!)),
      GoRoute(path: '/marketplace/:id/edit', builder: (c, s) => EditListingScreen(listingId: s.pathParameters['id']!)),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/reports', builder: (c, s) => const ReportsScreen()),
      GoRoute(path: '/reports/preview', builder: (c, s) => const PdfPreviewScreen()),
    ],
  );
}
