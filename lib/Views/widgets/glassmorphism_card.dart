import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.3),
                ],
        ),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]?.withOpacity(opacity)
                  : Colors.white.withOpacity(opacity),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}