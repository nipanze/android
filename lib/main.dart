// lib/main.dart
// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Global Supabase client accessor used throughout the app.
// ---------------------------------------------------------------------------
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive — UI-layer cache only (last marketplace snapshot, preferences).
  // NOT the primary database. Supabase Postgres is the source of truth.
  await Hive.initFlutter();

  // Supabase initialisation.
  // URL and anonKey come from SupabaseConfig which reads --dart-define at
  // build time, with local dev defaults baked in.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Dependency injection (injectable + get_it).
  configureDependencies();

  runApp(const OpenCapitalApp());
}

class OpenCapitalApp extends StatelessWidget {
  const OpenCapitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OpenCapital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}