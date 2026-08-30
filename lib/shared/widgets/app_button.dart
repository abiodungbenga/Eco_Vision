import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_dimensions.dart';

enum AppButtonStyle { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == AppButtonStyle.primary;
    final isOutline = style == AppButtonStyle.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingM,
            horizontal: AppDimensions.paddingL,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.primary
                : (isOutline ? Colors.transparent : AppColors.elevatedSurface),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: isOutline ? Border.all(color: AppColors.divider) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? AppColors.background : AppColors.text,
                    ),
                  ),
                )
              else ...[
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: isPrimary ? AppColors.background : AppColors.text,
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                ],
                Text(
                  text,
                  style: AppTypography.button.copyWith(
                    color: isPrimary ? AppColors.background : AppColors.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
