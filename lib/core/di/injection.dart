import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

// ---------------------------------------------------------------------------
// Manual registrations for things injectable can't auto-detect
// ---------------------------------------------------------------------------
@module
abstract class AppModule {
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
