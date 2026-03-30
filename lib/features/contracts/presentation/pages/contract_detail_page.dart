// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ContractDetailPage extends StatelessWidget {
  const ContractDetailPage({super.key, required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Contract'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.handshake_outlined, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Contract detail', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Contract ID: $contractId',
              style: const TextStyle(fontFamily: 'DM Mono', fontSize: 11),
            ),
            const SizedBox(height: 8),
            const Text('Full contract view — Stage 4 feature'),
          ],
        ),
      ),
    );
  }
}
