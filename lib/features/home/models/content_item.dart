import 'package:flutter/material.dart';

class ContentItem {
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String year;
  final String duration;
  final double rating;
  final Color primaryColor;
  final Color secondaryColor;

  const ContentItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.year,
    required this.duration,
    required this.rating,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
