import 'package:flutter/material.dart';
import 'package:nitd_code/ui/pallete.dart';

class LoginField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;

  const LoginField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
  });

  @override
  _LoginFieldState createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  late bool _isObscured; // Track password visibility only for password fields

  @override
  void initState() {
    super.initState();
    _isObscured =
        widget.obscureText; // Initialize only if the field is a password field
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText
            ? _isObscured
            : false, // ✅ Apply only for password fields
        style:
            const TextStyle(color: Colors.white), // ✅ User input text in white
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Pallete.borderColor, width: 3),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Pallete.gradient2, width: 3),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: widget.hintText,
          hintStyle:
              const TextStyle(color: Colors.white70), // ✅ Placeholder in white
          suffixIcon: widget.obscureText
              ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured =
                            !_isObscured; // ✅ Toggle only for password fields
                      });
                    },
                  ),
              )
              : null, // ✅ No icon for non-password fields
        ),
      ),
    );
  }
}
