// lib/features/auth/presentation/pages/register_page.dart
//
// Delegates entirely to the LoginPage wizard starting at the phone-entry step.
// This keeps routing clean (AppRoutes.register still works) while all wizard
// state lives in a single place.

import 'package:flutter/material.dart';

import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Start the wizard at Step 1 (phoneEntry) so the user immediately
    // begins the sign-up flow rather than seeing the welcome chooser.
    return const LoginPage(startAtSignUp: true);
  }
}
