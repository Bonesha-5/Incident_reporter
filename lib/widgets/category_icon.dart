import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.categoryId, this.size = 44});

  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = AppConstants.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => AppConstants.categories.last,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category.icon,
        size: size / 2,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
