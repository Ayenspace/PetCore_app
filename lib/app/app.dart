import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class PetCoreApp extends StatefulWidget {
  const PetCoreApp({super.key});

  @override
  State<PetCoreApp> createState() => _PetCoreAppState();
}

class _PetCoreAppState extends State<PetCoreApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(context.read<AppAuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'PetCore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
