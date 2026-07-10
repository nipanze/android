// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive local cache init
  await Hive.initFlutter();

  // Supabase init
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: false,
  );

  // Theme persistence — loads saved mode before first frame
  await ThemeService.instance.init();

  // Dependency injection
  configureDependencies();

  // BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  runApp(const NipanzeApp());
}

class NipanzeApp extends StatelessWidget {
  const NipanzeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.instance.notifier,
        builder: (context, themeMode, _) => MaterialApp.router(
          title: 'Nipanze',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: AppRouter(authBloc: context.read<AuthBloc>()).router,
        ),
      ),
    );
  }
}
