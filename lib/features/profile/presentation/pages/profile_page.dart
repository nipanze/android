import 'package:flutter/material.dart';

/// Profile — User profile and settings. Stage 2.1.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('User profile and settings. Stage 2.1.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
