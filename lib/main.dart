import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: login and database
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Our design decision: users log in every time the app opens,
  // because reports can contain sensitive safety information.
  await FirebaseAuth.instance.signOut();

  // Supabase: photo storage only
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Load the saved theme BEFORE the first screen appears
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        // Gets the logged-in user from AuthProvider automatically
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(IncidentService(), StorageService()),
          update: (_, auth, incidents) => incidents!..setUser(auth.user),
        ),
      ],
      child: const AluIncidentApp(),
    ),
  );
}
