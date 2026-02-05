import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final String? imagePath; // for Home page
  final IconData? icon; // for Business page

  ServiceCategory({
    required this.name,
    this.imagePath,
    this.icon,
  });
}
