// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  const url = 'https://lqfpeookpjtbiuhlhjut.supabase.co';
  const anonKey = 'sb_publishable_NF2TuHf3NEfowGgK7QTEuw_UQ9b-0YK';

  print('Initializing Supabase...');
  final client = SupabaseClient(url, anonKey);

  print('Signing in as james.okello@outlook.com...');
  try {
    final response = await client.auth.signInWithPassword(
      email: 'james.okello@outlook.com',
      password: 'Test1234!',
    );
    print('Sign in successful! User ID: ${response.user?.id}');

    print('\n--- Query 1: Direct SELECT from profiles ---');
    try {
      final profile = await client.from('profiles').select().eq('id', response.user!.id).maybeSingle();
      print('Profile data: $profile');
    } catch (e) {
      print('Profile SELECT error: $e');
    }

    print('\n--- Query 2: Direct SELECT from subscriptions ---');
    try {
      final sub = await client.from('subscriptions').select().eq('user_id', response.user!.id).maybeSingle();
      print('Subscription data: $sub');
    } catch (e) {
      print('Subscription SELECT error: $e');
    }

    print('\n--- Query 3: Calling RPC get_my_subscription_plan ---');
    try {
      final plan = await client.rpc('get_my_subscription_plan');
      print('RPC get_my_subscription_plan result: $plan (Type: ${plan.runtimeType})');
    } catch (e) {
      print('RPC error: $e');
    }

  } catch (e) {
    print('Sign in error: $e');
  }
}
