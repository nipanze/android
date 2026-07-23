import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/constants/country_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// A widget that displays a monetary amount with the appropriate currency
/// prefix based on the user's selected country (derived from their phone number).
/// Example: MoneyAmount(12000) will render "UGX 12,000" for Ugandan users or
/// "KES 12,000" for Kenyan users.
class MoneyAmount extends StatelessWidget {
  final int amount;
  final double? fontSize;
  final Color? color;

  const MoneyAmount(
    this.amount, {
    Key? key,
    this.fontSize,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final phone = authState is AuthAuthenticated ? authState.user.phone : null;
    final country = EastAfricaCountries.findByPhone(phone);
    final formatted = NumberFormat('#,##0', 'en_US').format(amount);
    final display = '${country.currency} $formatted';
    return Text(
      display,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
