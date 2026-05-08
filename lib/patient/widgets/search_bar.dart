import 'package:flutter/material.dart';
import 'package:mediconnect/constants/theme_ext.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onChanged;
  
  const SearchBarWidget({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search doctor...",
          hintStyle: TextStyle(color: context.subText),
          prefixIcon: Icon(Icons.search, color: context.subText),
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
