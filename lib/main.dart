// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'core/services/localization_fallback.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/language_service.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/theme_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApp();
  runApp(const NipanzeApp());
}

/// Initializes all app-wide dependencies: Hive cache, Supabase, persisted
/// theme/language settings, dependency injection, and the BLoC observer.
/// Kept separate from [main] so integration tests can reuse it before
/// pumping [NipanzeApp] directly (calling `runApp` from a test conflicts
/// with the live test binding).
Future<void> initApp() async {
  // Hive local cache init
  await Hive.initFlutter();

  // Supabase init
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: false,
  );

  // Theme & Language persistence — loads saved settings before first frame
  await ThemeService.instance.init();
  await LanguageService.instance.init();
  await AppLockService.instance.init();

  // Dependency injection
  configureDependencies();

  // BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
}

class NipanzeApp extends StatefulWidget {
  const NipanzeApp({super.key});

  @override
  State<NipanzeApp> createState() => _NipanzeAppState();
}

class _NipanzeAppState extends State<NipanzeApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: AppLockService.instance.handlePaused,
      onHide: AppLockService.instance.handlePaused,
      onResume: AppLockService.instance.handleResumed,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.instance.notifier,
        builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
          valueListenable: LanguageService.instance.notifier,
          builder: (context, locale, _) {
            final router = AppRouter(authBloc: context.read<AuthBloc>()).router;
            return ValueListenableBuilder<bool>(
              valueListenable: AppLockService.instance.locked,
              builder: (context, locked, _) => MaterialApp.router(
                title: 'Nipanze',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  SafeMaterialLocalizationsDelegate(),
                  GlobalWidgetsLocalizations.delegate,
                  SafeCupertinoLocalizationsDelegate(),
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                // If the user's locale isn't in our list at all, default to English
                localeResolutionCallback: (deviceLocale, supported) {
                  if (locale != null) {
                    return locale; // honour explicit user choice
                  }
                  for (final s in supported) {
                    if (s.languageCode == deviceLocale?.languageCode) return s;
                  }
                  return const Locale('en');
                },
                routerConfig: router,
                builder: (context, child) {
                  return Stack(
                    children: [
                      if (child != null) child,
                      if (locked) const AppLockScreen(),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
