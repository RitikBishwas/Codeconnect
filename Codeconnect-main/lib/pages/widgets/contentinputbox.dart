import 'package:flutter/material.dart';
import 'package:nitd_code/ui/pallete.dart';

class ContentInputField extends StatelessWidget {
  final TextEditingController controller;

  const ContentInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Enter Content',
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Pallete.whiteColor, // White for better contrast
        ),
        hintText: "Type your content here...",
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.gradient2, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Pallete.gradient3, width: 1.5),
        ),
        filled: true,
        fillColor: Pallete.backgroundColor, // Dark theme
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      minLines: 1,
      maxLines: 4,
      style: const TextStyle(fontSize: 14, color: Pallete.whiteColor),
      cursorColor: Pallete.gradient1,
    );
  }
}
