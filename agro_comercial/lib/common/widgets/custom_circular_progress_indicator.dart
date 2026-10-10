import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  final Color color;

  const CustomCircularProgressIndicator({
    super.key,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 40,
        child: CircularProgressIndicator(
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          strokeWidth: 3.5,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}
