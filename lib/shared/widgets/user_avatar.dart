// lib/shared/widgets/user_avatar.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.newAvatarBytes,
    this.initials = 'U',
    this.radius = 24.0,
    this.showCameraBadge = false,
    this.isVerified = false,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.textColor = Colors.white,
    this.borderColor,
  });

  final String? avatarUrl;
  final Uint8List? newAvatarBytes;
  final String initials;
  final double radius;
  final bool showCameraBadge;
  final bool isVerified;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double size = radius * 2;
    final double fontSize = radius * 0.72;

    final defaultGradient = gradient ??
        const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    final bool hasNewAvatar = newAvatarBytes != null;
    final bool hasUrlAvatar =
        avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    Widget avatarCore;
    if (hasNewAvatar) {
      avatarCore = Image.memory(
        newAvatarBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(fontSize),
      );
    } else if (hasUrlAvatar) {
      avatarCore = Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(fontSize),
      );
    } else {
      avatarCore = _buildInitials(fontSize);
    }

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (hasNewAvatar || hasUrlAvatar) ? null : backgroundColor,
        gradient: (hasNewAvatar || hasUrlAvatar || backgroundColor != null)
            ? null
            : defaultGradient,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      child: ClipOval(child: avatarCore),
    );

    if (showCameraBadge || isVerified) {
      final badgeSize = (radius * 0.6).clamp(16.0, 28.0);
      final iconSize = badgeSize * 0.6;
      final bgScaffoldColor = Theme.of(context).scaffoldBackgroundColor;

      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (showCameraBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: bgScaffoldColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (isVerified)
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildInitials(double fontSize) {
    return Center(
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
