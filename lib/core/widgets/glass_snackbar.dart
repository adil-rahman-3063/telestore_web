import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'glass_container.dart';

enum GlassSnackBarType { success, error, info }

class GlassSnackBar {
  static void show(
    BuildContext context, 
    String message, {
    GlassSnackBarType type = GlassSnackBarType.info,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color accentColor;
    IconData icon;
    
    switch (type) {
      case GlassSnackBarType.success:
        accentColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case GlassSnackBarType.error:
        accentColor = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
      case GlassSnackBarType.info:
      default:
        accentColor = AppColors.primary;
        icon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 16,
          backgroundColor: isDark ? Colors.black.withAlpha(180) : Colors.white.withAlpha(220),
          borderColor: accentColor.withAlpha(150),
          blur: 20,
          child: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
