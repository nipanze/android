import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

// ignore: prefer_void_to_null
/// Call once in main() after Supabase.initialize().
/// The real init() is generated into injection.config.dart by build_runner.
/// Until code generation runs, this is a no-op that keeps the compiler happy.
void configureDependencies() {
  getIt.init();
}

/// Provides the Supabase client as a singleton injectable.
@module
abstract class SupabaseModule {
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
