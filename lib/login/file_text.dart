import 'package:flutter/material.dart';

class FileTextInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final IconData icon;
  final bool isVisible; // To control visibility
  final VoidCallback? toggleVisibility; // Callback to toggle visibility

  const FileTextInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    required this.icon,
    this.isVisible = false, // Default to false
    this.toggleVisibility, // Initialize the callback
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: TextField(
        obscureText: isPass && !isVisible, // Toggle visibility
        controller: textEditingController,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.black,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: InputBorder.none,
          filled: true,
          fillColor: const Color(0xFFedf0f8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 2,
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          suffixIcon: isPass // Show the toggle icon only for password fields
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: toggleVisibility, // Call the toggle function
                )
              : null,
        ),
      ),
    );
  }
}