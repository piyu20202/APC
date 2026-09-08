import 'package:flutter/material.dart';

/// Login/signup-style text field (grey box, left icon, optional password toggle).
class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String placeholder;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.placeholder,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF151D51),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Icon(icon, color: const Color(0xFF151D51), size: 20),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: isPassword ? obscureText : false,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      color: Color(0xFF151D51),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: const Color(0xFF151D51).withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      suffixIcon: isPassword && onToggleObscure != null
                          ? IconButton(
                              icon: Icon(
                                obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF151D51),
                              ),
                              onPressed: onToggleObscure,
                            )
                          : null,
                    ),
                    validator: validator,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
