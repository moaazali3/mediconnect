import 'package:flutter/material.dart';
import 'package:mediconnect/constants/theme_ext.dart';

class SpecializationItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const SpecializationItem({
    super.key,
    required this.title,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D47A1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : context.filterChipBg,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : context.filterChipBorder,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : context.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
