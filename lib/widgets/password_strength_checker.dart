import 'package:flutter/material.dart';
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/constants/theme_ext.dart';

class PasswordStrengthChecker extends StatelessWidget {
  final String password;

  const PasswordStrengthChecker({Key? key, required this.password}) : super(key: key);

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSpecialChar => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);

  int get strengthScore {
    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;
    return score;
  }

  Color get _strengthColor {
    final score = strengthScore;
    if (score == 0) return Colors.grey.shade300;
    if (score <= 2) return Colors.red;
    if (score <= 4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 5,
                decoration: BoxDecoration(
                  color: index < strengthScore ? _strengthColor : (context.isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _buildConditionRow(context, "Minimum 8 characters", hasMinLength),
        _buildConditionRow(context, "One uppercase letter (A-Z)", hasUppercase),
        _buildConditionRow(context, "One lowercase letter (a-z)", hasLowercase),
        _buildConditionRow(context, "One number", hasNumber),
        _buildConditionRow(context, "One special character (@, #, \$, etc.)", hasSpecialChar),
      ],
    );
  }

  Widget _buildConditionRow(BuildContext context, String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : context.subText,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? context.onSurface : context.subText,
                fontSize: 12,
                decoration: isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
