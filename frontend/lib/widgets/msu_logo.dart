import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MsuLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const MsuLogo({
    super.key,
    this.size = 40,
    this.showBorder = false,
    this.borderColor,
    this.borderRadius = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      'assets/images/msu_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.school_rounded,
            size: size * 0.6,
            color: AppColors.accentGold,
          ),
        );
      },
    );

    if (showBorder) {
      return Container(
        width: size + 8,
        height: size + 8,
        padding: padding ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor ?? AppColors.accentGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
