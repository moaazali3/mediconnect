import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/models/DoctorModel.dart';
import 'package:mediconnect/constants/api_constants.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    String? fullImageUrl;
    if (doctor.profilePictureUrl != null && doctor.profilePictureUrl!.isNotEmpty) {
      fullImageUrl = doctor.profilePictureUrl!.startsWith('http')
          ? doctor.profilePictureUrl
          : "${ApiConstants.serverUrl}${doctor.profilePictureUrl}";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. الصورة الدائرية
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: fullImageUrl != null
                    ? Image.network(
                  fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                )
                    : _buildFallbackImage(),
              ),
            ),
            const SizedBox(width: 15),

            // 2. بيانات الدكتور (شيلنا السعر من هنا وخلينا الخبرة بس)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dr. ${doctor.firstName} ${doctor.lastName}",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doctor.specializationName.isEmpty ? "Specialist" : doctor.specializationName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // الخبرة بس هي اللي هتظهر بره
                  _buildStat(Icons.workspace_premium_outlined, "${doctor.experienceYears.toStringAsFixed(0)} Years Exp.", isDark: isDark),
                ],
              ),
            ),

            const SizedBox(width: 5),

            // 3. الزرار الأزرق
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت أيقونة الخبرة
  Widget _buildStat(IconData icon, String text, {required bool isDark}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? const Color(0xFF6B7280) : Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // الصورة البديلة
  Widget _buildFallbackImage() {
    return Container(
      color: primaryColor.withOpacity(0.1),
      child: const Icon(Icons.person_rounded, color: primaryColor, size: 40),
    );
  }
}