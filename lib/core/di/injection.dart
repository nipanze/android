// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/account/data/profile_repository.dart';
import '../../features/account/presentation/cubit/profile_cubit.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/kyc/data/kyc_repository.dart';
import '../../features/kyc/presentation/cubit/kyc_cubit.dart';
import '../../features/listings/data/listing_repository.dart';
import '../../features/listings/presentation/cubit/my_listings_cubit.dart';
import '../../features/marketplace/data/marketplace_repository.dart';
import '../../features/marketplace/presentation/cubit/marketplace_cubit.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/positions/data/positions_repository.dart';
import '../../features/positions/presentation/cubit/positions_cubit.dart';
import '../../features/settings/data/system_settings_repository.dart';
import '../../features/watchlist/data/watchlist_repository.dart';
import '../../features/watchlist/presentation/cubit/watchlist_cubit.dart';

part 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

@module
abstract class SupabaseModule {
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}