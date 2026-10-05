import 'dart:io';

import 'package:flutter/material.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/utils/helpers.dart';

class CustomImagePicker extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;
  final double radius;
  final IconData placeholderIcon;

  const CustomImagePicker({
    super.key,
    required this.onTap,
    this.imageFile,
    this.imageUrl,
    this.radius = 55,
    this.placeholderIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;

    if (imageFile != null) {
      provider = FileImage(imageFile!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      final img = formatMediaUrl(imageUrl);
      provider = NetworkImage(img);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.surfaceColor,
            backgroundImage: provider,
            child: provider == null
                ? Icon(placeholderIcon, size: radius, color: Colors.grey)
                : null,
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
