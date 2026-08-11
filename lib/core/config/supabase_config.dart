/// Reads Supabase credentials from --dart-define at build time.
/// If no --dart-define is provided, the default is the cloud Supabase project
/// used by `run_with_supabase.sh`.
///
/// Local dev can still override these values with:
///   --dart-define=SUPABASE_URL=http://127.0.0.1:54321
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lqfpeookpjtbiuhlhjut.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_NF2TuHf3NEfowGgK7QTEuw_UQ9b-0YK',
  );
}
