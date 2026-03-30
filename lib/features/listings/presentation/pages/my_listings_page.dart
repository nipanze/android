// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My listings')),
      body: EmptyState(
        icon: Icons.list_alt_rounded,
        title: 'No listings yet',
        subtitle: 'Create your first loan request to get started.',
        action: ElevatedButton(
          onPressed: () => context.push('/listings/create'),
          child: const Text('Create a listing'),
        ),
      ),
    );
  }
}
