import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ContentSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isLoading;

  const ContentSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            color: Colors.grey.shade500,
            size: 20,
          ),
          suffixIcon: isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}