// lib/features/auth/presentation/widgets/auth_widgets.dart
//
// Shared building blocks for the auth flow's new look — brand mark, status
// pill, and the labeled card-style input used on login/register/reset.
// Centralizing these means the three auth screens (and any future one, e.g.
// change-password) automatically stay visually identical instead of drifting
// as each screen's TextFormField gets tweaked independently.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// "N" mark + "Nipanze" wordmark, used at the top of the login screen.
/// Uses AppColors.accentDark -> AppColors.purple, the same gradient pair
/// as the profile avatar, so the two brand touchpoints in the app match.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentDark, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: AppFonts.heading,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('Nipanze', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

/// Small dot + label pill, echoing the "3 offers" / "Fully funded" badge
/// treatment already used on marketplace listing cards.
class AuthStatusPill extends StatelessWidget {
  const AuthStatusPill({
    super.key,
    required this.label,
    this.color = AppColors.success,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled input: a small uppercase caption above a card-styled field,
/// mirroring how "DURATION" / "TIME LEFT" sit above their values on
/// MyListingCard, instead of Material's default floating-label TextField.
///
/// Note: because the field itself has InputBorder.none, the card border
/// does not turn red on validation error — only the error text beneath it
/// does, via the theme's default errorStyle. That's an intentional
/// simplification; wire in a focus/error listener here if a stronger error
/// state is needed later.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.3,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              prefixIcon:
                  icon != null ? Icon(icon, size: 17, color: muted) : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width secondary action, styled to carry equal visual weight to the
/// primary ElevatedButton — used for "Create an account" / "Back to sign in"
/// instead of a small TextButton link, matching how MyListingCard gives
/// "View offers" and "Cancel" equal-weight buttons rather than one link +
/// one button.
class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
