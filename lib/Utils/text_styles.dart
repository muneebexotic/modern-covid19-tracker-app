import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle heading(BuildContext context, {double size = 20}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.darkCard,
      height: 1.2,
    );
  }

  static const TextStyle smallMuted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );
}
